"""FastAPI application — WebSocket ACP bridge server."""

from __future__ import annotations

import json
import logging
from typing import Any

from fastapi import FastAPI, WebSocket, WebSocketDisconnect

from rogue_gateway.adapters.registry import CLI_REGISTRY
from rogue_gateway.auth import verify_token
from rogue_gateway.session.manager import SessionManager

logger = logging.getLogger(__name__)

app = FastAPI(title="Rogue Gateway", version="0.1.0")
session_manager = SessionManager()


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "version": __import__("rogue_gateway").__version__}


@app.get("/api/clis")
async def list_clis() -> list[dict[str, Any]]:
    return [
        {"name": cli.name, "display_name": cli.display_name, "acp_command": cli.command}
        for cli in CLI_REGISTRY.values()
    ]


def _jsonrpc_error(code: int, message: str, req_id: Any = None) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}}


def _jsonrpc_result(result: Any, req_id: Any = None) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": req_id, "result": result}


async def _handle_initialize(
    websocket: WebSocket, message: dict[str, Any]
) -> tuple[str | None, str | None]:
    params = message.get("params", {})
    auth_token = params.get("token", "")
    if not verify_token(auth_token):
        await websocket.send_json(_jsonrpc_error(-32001, "Unauthorized", message.get("id")))
        return None, None

    cli_name = params.get("cli", "opencode")
    cli_config = CLI_REGISTRY.get(cli_name)
    if cli_config is None:
        await websocket.send_json(
            _jsonrpc_error(-32002, f"Unknown CLI: {cli_name}", message.get("id"))
        )
        return None, None

    project_path = params.get("cwd", ".")
    sid = await session_manager.create_session(cli_config, project_path)
    await websocket.send_json(
        _jsonrpc_result({"session_id": sid, "cli": cli_name}, message.get("id"))
    )
    return sid, cli_name


async def _handle_prompt(websocket: WebSocket, message: dict[str, Any], session_id: str) -> None:
    params = message.get("params", {})
    prompt_text = params.get("prompt", "")
    attachments = params.get("attachments", [])

    async for bubble in session_manager.send_message(session_id, prompt_text, attachments):
        await websocket.send_json({"jsonrpc": "2.0", "method": "session/update", "params": bubble})

    await websocket.send_json(_jsonrpc_result({"status": "completed"}, message.get("id")))


async def _handle_cancel(websocket: WebSocket, message: dict[str, Any], session_id: str) -> None:
    await session_manager.cancel_session(session_id)
    await websocket.send_json(_jsonrpc_result({"status": "cancelled"}, message.get("id")))


async def _handle_close(websocket: WebSocket, message: dict[str, Any], session_id: str) -> bool:
    await session_manager.close_session(session_id)
    await websocket.send_json(_jsonrpc_result({"status": "closed"}, message.get("id")))
    return True


_METHOD_MAP: dict[str, Any] = {
    "session/prompt": _handle_prompt,
    "session/cancel": _handle_cancel,
    "session/close": _handle_close,
}


@app.websocket("/ws")
async def ws_endpoint(websocket: WebSocket) -> None:
    await websocket.accept()

    session_id: str | None = None
    cli_name: str | None = None

    try:
        while True:
            raw = await websocket.receive_text()
            message: dict[str, Any] = json.loads(raw)
            method: str = message.get("method", "")

            if method == "initialize":
                session_id, cli_name = await _handle_initialize(websocket, message)
                continue

            if session_id is None:
                await websocket.send_json(
                    _jsonrpc_error(-32003, "Not initialized", message.get("id"))
                )
                continue

            handler = _METHOD_MAP.get(method)
            if handler is None:
                await websocket.send_json(
                    _jsonrpc_error(-32601, f"Unknown method: {method}", message.get("id"))
                )
                continue

            should_break = await handler(websocket, message, session_id)
            if should_break:
                break

    except WebSocketDisconnect:
        logger.info("ws_disconnect session_id=%s", session_id)
    except Exception:
        logger.exception("ws_error session_id=%s", session_id)
    finally:
        if session_id:
            await session_manager.close_session(session_id)
