"""Session manager — creates and manages ACP CLI subprocess sessions.

Follows lattice-code's ACPSessionManager pattern: spawn CLI via spawn_agent_process(),
bridge to internal bubble queue, expose via WebSocket.
"""

from __future__ import annotations

import asyncio
import contextlib
import logging
import os
import uuid
from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any, cast

from acp import PROTOCOL_VERSION, spawn_agent_process, text_block
from acp.exceptions import RequestError
from acp.interfaces import Client as ACPClientProtocol
from acp.schema import (
    ClientCapabilities,
    DeniedOutcome,
    FileSystemCapabilities,
    Implementation,
    RequestPermissionResponse,
)

from rogue_gateway.adapters.registry import CLIConfig

logger = logging.getLogger(__name__)


class ACPSession:
    """One active ACP CLI session — owns the subprocess + ACP connection."""

    def __init__(self, session_id: str, config: CLIConfig, project_path: str) -> None:
        self.session_id = session_id
        self.config = config
        self.project_path = str(Path(project_path).expanduser().resolve(strict=False))
        self.acp_session_id: str | None = None
        self._connection: Any = None
        self._context: Any = None
        self._bubble_queue: asyncio.Queue[dict[str, Any]] = asyncio.Queue()
        self._turn_lock = asyncio.Lock()
        self._active_task: asyncio.Task[None] | None = None

    async def initialize(self) -> str:
        """Spawn the CLI subprocess and perform ACP handshake."""
        client = _BridgeClient(self)
        command, *args = self.config.command
        env = {**os.environ}
        if self.config.env_required:
            # Best-effort: pass through required env vars if set
            for req in self.config.env_required:
                if isinstance(req, str):
                    pass
                else:
                    for var in req:
                        if os.environ.get(var):
                            env[var] = os.environ[var]

        self._context = spawn_agent_process(
            cast(ACPClientProtocol, client), command, *args, cwd=self.project_path, env=env
        )
        self._connection, _process = await self._context.__aenter__()

        await self._connection.initialize(
            protocol_version=PROTOCOL_VERSION,
            client_capabilities=ClientCapabilities(
                fs=FileSystemCapabilities(read_text_file=False, write_text_file=False),
                terminal=False,
            ),
            client_info=Implementation(
                name="rogue-gateway",
                title="Rogue Gateway",
                version="0.1.0",
            ),
        )

        response = await self._connection.new_session(
            cwd=self.project_path,
            mcp_servers=[],
        )
        session_id = getattr(response, "session_id", None)
        if not isinstance(session_id, str) or not session_id:
            raise RuntimeError("ACP agent did not return a session id")
        self.acp_session_id = session_id
        return session_id

    async def run_turn(self, message: str) -> AsyncIterator[dict[str, Any]]:
        """Send a prompt and yield streaming update bubbles."""
        async with self._turn_lock:
            prompt_task = asyncio.create_task(
                self._connection.prompt(
                    prompt=[text_block(message)],
                    session_id=self.acp_session_id,
                    message_id=str(uuid.uuid4()),
                )
            )
            get_task = asyncio.create_task(self._bubble_queue.get())

            try:
                while True:
                    done, _ = await asyncio.wait(
                        {prompt_task, get_task},
                        return_when=asyncio.FIRST_COMPLETED,
                    )
                    if get_task in done:
                        yield get_task.result()
                        get_task = asyncio.create_task(self._bubble_queue.get())
                    if prompt_task in done:
                        prompt_task.result()
                        get_task.cancel()
                        with contextlib.suppress(asyncio.CancelledError):
                            await get_task
                        while not self._bubble_queue.empty():
                            yield self._bubble_queue.get_nowait()
                        return
            finally:
                for task in (prompt_task, get_task):
                    if not task.done():
                        task.cancel()
                        with contextlib.suppress(asyncio.CancelledError):
                            await task

    async def cancel(self) -> None:
        if self._connection and self.acp_session_id:
            try:
                await self._connection.cancel(session_id=self.acp_session_id)
            except Exception:
                logger.exception("cancel_failed session_id=%s", self.session_id)

    async def close(self) -> None:
        if self._connection and self.acp_session_id:
            try:
                await self._connection.close_session(session_id=self.acp_session_id)
            except Exception:
                logger.exception("close_session_failed session_id=%s", self.session_id)
        if self._context:
            await self._context.__aexit__(None, None, None)
            self._context = None
            self._connection = None

    async def enqueue_bubble(self, bubble: dict[str, Any]) -> None:
        await self._bubble_queue.put(bubble)


class _BridgeClient:
    """ACP client callbacks — receives updates from the CLI subprocess."""

    __test__ = False

    def __init__(self, session: ACPSession) -> None:
        self._session = session

    async def session_update(self, session_id: str, update: object, **kwargs: Any) -> None:
        # Map ACP update subtypes to bubble dicts
        subtype = _field(update, "session_update", "sessionUpdate")
        if subtype == "agent_message_chunk":
            content = _field(update, "content")
            text = _field(content, "text") if content else ""
            if text and text.strip():
                await self._session.enqueue_bubble(
                    {
                        "type": "assistant_text",
                        "content": text.strip(),
                    }
                )
        elif subtype == "tool_call":
            await self._session.enqueue_bubble(
                {
                    "type": "tool_call",
                    "name": _field(update, "title")
                    or _field(update, "tool_call_id", "toolCallId")
                    or "tool",
                    "arguments": _safe_dict(update),
                }
            )
        elif subtype == "tool_call_update":
            await self._session.enqueue_bubble(
                {
                    "type": "tool_result",
                    "status": _field(update, "status"),
                    "arguments": _safe_dict(update),
                }
            )
        elif subtype == "plan":
            await self._session.enqueue_bubble(
                {
                    "type": "plan",
                    "entries": _field(update, "entries"),
                }
            )

    async def request_permission(
        self, options: list[object], session_id: str, tool_call: object, **kwargs: Any
    ) -> Any:
        return RequestPermissionResponse(outcome=DeniedOutcome(outcome="cancelled"))

    def on_connect(self, _conn: object) -> None:
        return None

    async def write_text_file(self, **kwargs: Any) -> None:
        raise RequestError.invalid_request({"operation": "fs_write_text_file_disabled"})

    async def read_text_file(self, **kwargs: Any) -> None:
        raise RequestError.invalid_request({"operation": "fs_read_text_file_disabled"})

    async def create_terminal(self, **kwargs: Any) -> None:
        raise RequestError.invalid_request({"operation": "terminal_create_disabled"})

    async def terminal_output(self, **kwargs: Any) -> None:
        pass

    async def release_terminal(self, **kwargs: Any) -> None:
        pass

    async def wait_for_terminal_exit(self, **kwargs: Any) -> None:
        pass

    async def kill_terminal(self, **kwargs: Any) -> None:
        pass

    async def ext_method(self, method: str, params: dict[str, Any]) -> dict[str, Any]:
        raise RequestError.method_not_found(method)

    async def ext_notification(self, method: str, params: dict[str, Any]) -> None:
        logger.debug("extension_notification method=%s", method)


class SessionManager:
    """Manages multiple ACP CLI sessions."""

    def __init__(self) -> None:
        self._sessions: dict[str, ACPSession] = {}

    async def create_session(self, config: CLIConfig, project_path: str) -> str:
        session_id = uuid.uuid4().hex[:16]
        session = ACPSession(session_id, config, project_path)
        await session.initialize()
        self._sessions[session_id] = session
        logger.info("session_created session_id=%s cli=%s", session_id, config.name)
        return session_id

    async def send_message(
        self, session_id: str, message: str, attachments: list[str] | None = None
    ) -> AsyncIterator[dict[str, Any]]:
        session = self._sessions.get(session_id)
        if session is None:
            raise KeyError(session_id)
        prompt = message
        if attachments:
            prompt = message + "\nAttached: " + ", ".join(attachments)
        async for bubble in session.run_turn(prompt):
            yield bubble

    async def cancel_session(self, session_id: str) -> None:
        session = self._sessions.get(session_id)
        if session:
            await session.cancel()

    async def close_session(self, session_id: str) -> None:
        session = self._sessions.pop(session_id, None)
        if session is None:
            return
        await session.close()
        logger.info("session_closed session_id=%s", session_id)

    async def shutdown(self) -> None:
        for session_id in list(self._sessions):
            await self.close_session(session_id)


def _field(value: object, *names: str) -> Any:
    for name in names:
        if isinstance(value, dict) and name in value:
            return value[name]
        if not isinstance(value, dict) and hasattr(value, name):
            return getattr(value, name)
    return None


def _safe_dict(obj: object) -> dict[str, Any]:
    if hasattr(obj, "model_dump"):
        return obj.model_dump(by_alias=True, exclude_none=True)  # type: ignore[no-any-return]
    if isinstance(obj, dict):
        return {str(k): v for k, v in obj.items()}
    return {}
