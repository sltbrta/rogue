"""iMessage bridge — macOS daemon bridging Messages.app ↔ Rogue Gateway.

Runs on Mac. Uses osascript to read incoming iMessages and send responses.
Each iMessage chat buddy maps to one CLI session.
"""

from __future__ import annotations

import asyncio
import contextlib
import json
import os
import time
from pathlib import Path

import websockets

CHECK_INTERVAL = 2.0
LAST_READ_FILE = Path.home() / ".config" / "rogue" / "imessage-last-read"


async def run_imessage_script(script: str) -> str:
    proc = await asyncio.create_subprocess_exec(
        "osascript",
        "-e",
        script,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, _stderr = await proc.communicate()
    return stdout.decode("utf-8").strip()


async def send_imessage(buddy: str, text: str) -> None:
    safe = text.replace('"', '\\"').replace("\n", "\\n")
    await run_imessage_script(f'tell application "Messages" to send "{safe}" to buddy "{buddy}"')


async def get_unread_messages() -> list[dict[str, str]]:
    raw = await run_imessage_script('tell application "Messages" to get text of every chat')
    if not raw:
        return []

    chats = raw.split(", ")
    messages: list[dict[str, str]] = []
    for chat_info in chats:
        if not chat_info.strip():
            continue
        # Parse buddy:last_message format
        if ":" in chat_info:
            parts = chat_info.split(":", 1)
            messages.append(
                {
                    "buddy": parts[0].strip(),
                    "text": parts[1].strip(),
                }
            )
    return messages


async def _process_message(
    ws_url: str,
    token: str,
    buddy: str,
    text: str,
    sessions: dict[str, str],
) -> str | None:
    if text.startswith("/switch"):
        parts = text.split()
        cli = parts[1] if len(parts) > 1 else "opencode"
        if buddy in sessions:
            await close_session(ws_url, token, sessions.pop(buddy))
        print(f"[imessage-bridge] {buddy} switched to {cli}")
    return await forward_to_gateway(ws_url, token, buddy, text, sessions)


async def bridge_loop(gateway_url: str, token: str) -> None:
    """Main bridge loop: poll iMessages, forward to gateway, send responses."""

    ws_url = gateway_url.replace("http://", "ws://").rstrip("/") + "/ws"
    sessions: dict[str, str] = {}

    last_time = 0.0
    if LAST_READ_FILE.exists():
        with contextlib.suppress(ValueError, OSError):
            last_time = float(LAST_READ_FILE.read_text().strip())

    print(f"[imessage-bridge] Connecting to {ws_url}")

    while True:
        try:
            messages = await get_unread_messages()
            current_time = time.time()

            for msg in messages:
                buddy = msg["buddy"]
                text = msg["text"]
                if not buddy or not text:
                    continue
                if current_time <= last_time + 1:
                    continue

                print(f"[imessage-bridge] {buddy}: {text[:80]}")
                response = await _process_message(ws_url, token, buddy, text, sessions)
                if response:
                    await send_imessage(buddy, response)
                    print(f"[imessage-bridge] → {buddy}: {response[:80]}")

            last_time = current_time
            LAST_READ_FILE.write_text(str(current_time))

        except Exception as exc:
            print(f"[imessage-bridge] error: {exc}")
            await asyncio.sleep(5)

        await asyncio.sleep(CHECK_INTERVAL)


async def forward_to_gateway(
    ws_url: str,
    token: str,
    buddy: str,
    message: str,
    sessions: dict[str, str],
) -> str | None:
    try:
        async with websockets.connect(ws_url) as ws:
            # Initialize or reuse session
            if buddy not in sessions:
                await ws.send(
                    json.dumps(
                        {
                            "jsonrpc": "2.0",
                            "id": 1,
                            "method": "initialize",
                            "params": {
                                "token": token,
                                "cli": "opencode",
                                "cwd": str(Path.cwd()),
                            },
                        }
                    )
                )
                init_resp = json.loads(await asyncio.wait_for(ws.recv(), timeout=10))
                sid = init_resp.get("result", {}).get("session_id")
                if sid:
                    sessions[buddy] = sid

            # Send prompt
            await ws.send(
                json.dumps(
                    {
                        "jsonrpc": "2.0",
                        "id": 2,
                        "method": "session/prompt",
                        "params": {"prompt": message},
                    }
                )
            )

            # Collect all response text
            responses: list[str] = []
            while True:
                raw = await asyncio.wait_for(ws.recv(), timeout=60)
                msg = json.loads(raw)
                if "id" in msg and msg.get("id") == 2:
                    break
                if msg.get("method") == "session/update":
                    params = msg.get("params", {})
                    if params.get("type") == "assistant_text":
                        responses.append(params.get("content", ""))

            return "".join(responses)

    except Exception as exc:
        return f"Error: {exc}"


async def close_session(ws_url: str, token: str, session_id: str) -> None:
    try:
        async with websockets.connect(ws_url) as ws:
            await ws.send(
                json.dumps(
                    {
                        "jsonrpc": "2.0",
                        "id": 0,
                        "method": "initialize",
                        "params": {"token": token, "cli": "opencode", "cwd": "."},
                    }
                )
            )
            await ws.recv()
            await ws.send(
                json.dumps(
                    {
                        "jsonrpc": "2.0",
                        "id": 9,
                        "method": "session/close",
                    }
                )
            )
            await ws.recv()
    except Exception:
        pass


if __name__ == "__main__":
    gateway = os.environ.get("ROGUE_GATEWAY_URL", "http://localhost:8787")
    token = os.environ.get("ROGUE_GATEWAY_TOKEN", "")
    print(f"[imessage-bridge] Starting bridge to {gateway}")
    asyncio.run(bridge_loop(gateway, token))
