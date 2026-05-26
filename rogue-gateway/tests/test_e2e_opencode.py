"""Phase A integration test — end-to-end WebSocket → OpenCode ACP.

Starts the gateway server, connects via WebSocket, initializes an OpenCode
session, sends a prompt, and verifies streaming response.

Usage: uv run python tests/test_e2e_opencode.py
"""

from __future__ import annotations

import asyncio
import json
import sys
from pathlib import Path

import websockets


async def main() -> None:
    gateway_host = sys.argv[1] if len(sys.argv) > 1 else "localhost"
    gateway_port = int(sys.argv[2]) if len(sys.argv) > 2 else 8787
    ws_url = f"ws://{gateway_host}:{gateway_port}/ws"

    # Get auth token
    token_path = Path.home() / ".config" / "rogue" / "gateway-token"
    token = token_path.read_text().strip() if token_path.exists() else "test-token"

    async with websockets.connect(ws_url) as ws:
        # Step 1: Initialize session
        print("[1] Initializing OpenCode session...")
        await ws.send(
            json.dumps(
                {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "initialize",
                    "params": {"token": token, "cli": "opencode", "cwd": str(Path.cwd())},
                }
            )
        )
        init_response = json.loads(await ws.recv())
        print(f"    Response: {json.dumps(init_response, indent=2)[:200]}")

        if "error" in init_response:
            print(f"    ERROR: {init_response['error']}")
            return

        session_id = init_response.get("result", {}).get("session_id")
        if not session_id:
            print("    No session_id!")
            return
        print(f"    Session: {session_id}")

        # Step 2: Send a prompt
        print("\n[2] Sending prompt: 'Say hello in one sentence'")
        await ws.send(
            json.dumps(
                {
                    "jsonrpc": "2.0",
                    "id": 2,
                    "method": "session/prompt",
                    "params": {"prompt": "Say hello in exactly one sentence."},
                }
            )
        )

        # Step 3: Stream response
        print("\n[3] Streaming response:")
        char_count = 0
        bubble_count = 0
        while True:
            raw = await ws.recv()
            msg = json.loads(raw)
            if "id" in msg and msg.get("id") == 2:
                # Final result
                print(f"\n    Final: {json.dumps(msg.get('result', {}))}")
                break
            if msg.get("method") == "session/update":
                params = msg.get("params", {})
                bubble_type = params.get("type", "unknown")
                content = params.get("content", "")
                bubble_count += 1
                if bubble_type == "assistant_text":
                    char_count += len(content)
                    print(content, end="", flush=True)
                else:
                    print(f"\n    [{bubble_type}] {params.get('name', '')}", end="")

        print(f"\n\n[4] Done — {char_count} chars, {bubble_count} bubbles")

        # Step 4: Close session
        print("\n[5] Closing session...")
        await ws.send(
            json.dumps(
                {
                    "jsonrpc": "2.0",
                    "id": 3,
                    "method": "session/close",
                }
            )
        )
        close_resp = json.loads(await ws.recv())
        print(f"    Closed: {close_resp.get('result', {}).get('status')}")


if __name__ == "__main__":
    asyncio.run(main())
