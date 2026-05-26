# Rogue unified roadmap

> Per `~/.claude/rules/unified-roadmap-discipline.md`: single source of truth.
> Per `~/.claude/rules/no-time-anchoring.md`: future work uses sequential vocabulary.
> **Last consolidated**: 2026-05-26

## Status markers

- ✅ **Shipped end-to-end** — user-reachable surface + integration test + consistent docs + stubs disclosed
- 🚧 **Backend ready, UI/wiring pending** — API exists, no user-reachable surface OR no production caller
- 🎨 **UI scaffold, backend pending** — mockup/stub UI, backend stubbed
- 📅 **Planned** — on the roadmap, not started
- ❌ **Deferred** — scoped out of current milestone

## Where we are

- **Sprint shape**: Phased — gateway first, then iOS, then integrations, then polish
- **Next milestone**: Phase G — remaining CLI adapters + production polish

## Tracks

### Track A — Gateway (`rogue-gateway/`)

| Item | Status | Notes |
|---|---|---|
| FastAPI + WebSocket ACP bridge | ✅ Shipped | `main.py`, e2e test passes |
| OpenCode adapter | ✅ Shipped | `opencode acp` via agent-client-protocol SDK |
| Codex adapter | ✅ Shipped | Config in `registry.py` |
| Gemini adapter | ✅ Shipped | Config in `registry.py` |
| Claude adapter | ✅ Shipped | Config in `registry.py` |
| Cursor, Qwen, Kimi adapters | ✅ Shipped | Configs in `registry.py` |
| Session manager | ✅ Shipped | `session/manager.py` — ACPSession + SessionManager |
| Handover log (SQLite) | ✅ Shipped | `handover/log.py` — structured entries |
| Handover sync (Railway S3) | ✅ Shipped | `handover/sync.py` — snapshot upload/download |
| iMessage bridge | 🚧 | `imessage/bridge.py` — daemon code written, not tested on Mac |
| Railway deployment (Docker) | 🚧 | `Dockerfile` + `railway.toml` written, not deployed |

### Track B — iOS App (`rogue-ios/`)

| Item | Status | Notes |
|---|---|---|
| ACP client (JSON-RPC 2.0 over WebSocket) | ✅ Shipped | `ACPClient.swift` — URLSessionWebSocketTask |
| ChatView with streaming | ✅ Shipped | Per-token text rendering, auto-scroll |
| Tool call cards + approval gates | ✅ Shipped | `ToolCallCard.swift`, `ApprovalGate.swift` |
| Neo-Brutalist theme | ✅ Shipped | Colors, Typography, 2px borders |
| Multi-thread list + switcher | ✅ Shipped | `ThreadListView.swift` with create/delete |
| Slash command palette | ✅ Shipped | 9 built-in commands with icons |
| Gateway connection manager | ✅ Shipped | Add/edit/delete gateways, health indicator |
| Plugin system (SPM packages) | 📅 Planned | Plugin protocol defined in plan |
| File/image upload + preview | 📅 Planned | Phase not yet started |
| Gateway failover | 📅 Planned | Health check → auto-switch logic |
| Push notifications + Widget | 📅 Planned | Phase G |
| App Store submission | 📅 Planned | Phase G |

### Track C — OpenCode Plugins

| Item | Status | Notes |
|---|---|---|
| rogue-constitution | ✅ Shipped | All 46 rules as session context |
| rogue-quality-gate | ✅ Shipped | Blocks --no-verify, force-push, hook bypass |
| rogue-modularity | ✅ Shipped | File ≤500, complexity ≤15 |
| rogue-tool-allowlist | ✅ Shipped | 156 allowed Bash prefixes |
| rogue-adversarial-audit | ✅ Shipped | 10/13 failure shape pre-commit grep |
| rogue-compaction | ✅ Shipped | Standardized handover context |
| rogue-hook-integrity | ✅ Shipped | Verifies core.hooksPath |

## Immediate next steps

1. Test iMessage bridge on Mac
2. Deploy gateway on Railway
3. Open iOS project in Xcode, build and test
4. Phase G: add file attachment UI, push notifications, App Store prep

## Reference index

- (plans) `.claude/plans/rogue.md` — full architecture + phase plan
- (audits) `.claude/audits/` — when authored
