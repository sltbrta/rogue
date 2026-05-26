# Rogue

> Mobile CLI agent controller — control your coding agents from anywhere.

iPhone app + gateway that wraps ACP-compatible CLI coding agents (OpenCode, Codex, Gemini, Claude, Cursor, Qwen, Kimi) running on your MacBook or cloud VPS, exposed through a native iOS chat interface.

**Protocol**: ACP (Agent Client Protocol) — the LSP for AI agents. JSON-RPC 2.0 over WebSocket.

**Design**: Neo-Brutalist — bold, utilitarian, unapologetic. Black + white + terminal green.

**Architecture**:

```
iOS App (Swift 6, iOS 17+) ──ACP/WS──→ Gateway (Python, FastAPI) ──stdio──→ CLI (opencode acp / codex / gemini / ...)
```

Gateway runs on MacBook (local) or Railway (cloud), with handover log sync for seamless failover. Companion iMessage bridge on Mac for notifications and quick commands.

## Features

- Streaming chat with tool call visualization and approval gates
- Multi-thread: one conversation per CLI agent, switch freely
- Plugin system: SPM packages providing slash commands and custom renderers
- File/image upload from phone
- Built-in slash commands (`/deploy`, `/lint`, `/audit`, etc.)
- iMessage companion channel for notifications and quick commands
- Mac ↔ cloud seamless failover via handover log sync

## Status

🚧 **Phase A** (in progress): Gateway + OpenCode adapter

## Built with Claude

Co-authored with Claude Code.

## License

MIT
