# Rogue unified roadmap

> Per `~/.claude/rules/unified-roadmap-discipline.md`: single source of truth.

> Per `~/.claude/rules/no-time-anchoring.md`: future work uses sequential vocabulary — NOT calendar dates.

> **Last consolidated**: 2026-05-26 (initial)

## Status markers

- ✅ **Shipped end-to-end** — user-reachable surface + integration test + consistent docs + stubs disclosed
- 🚧 **Backend ready, UI/wiring pending** — API exists, no user-reachable surface OR no production caller
- 🎨 **UI scaffold, backend pending** — mockup/stub UI, backend stubbed
- 📅 **Planned** — on the roadmap, not started
- ❌ **Deferred** — scoped out of current milestone

## Where we are

- **Sprint shape**: Multi-phase: gateway first, then iOS app, then integrations
- **Next milestone**: Phase A complete — gateway serving ACP over WebSocket with OpenCode adapter

## Tracks

### Track A — Gateway (`rogue-gateway/`)

| Item | Status | Notes |
|---|---|---|
| FastAPI + WebSocket ACP bridge | 📅 Planned | Phase A |
| OpenCode adapter (`opencode acp`) | 📅 Planned | Phase A — first CLI |
| Codex adapter (`@zed-industries/codex-acp`) | 📅 Planned | Phase C |
| Gemini adapter (`@google/gemini-cli --acp`) | 📅 Planned | Phase C |
| Claude adapter | 📅 Planned | Phase G |
| Cursor, Qwen, Kimi adapters | 📅 Planned | Phase G |
| Session manager (reuse lattice-code pattern) | 📅 Planned | Phase A |
| Handover log (SQLite) | 📅 Planned | Phase F |
| Handover sync (Railway S3) | 📅 Planned | Phase F |
| Railway deployment (Docker) | 📅 Planned | Phase F |

### Track B — iOS App (`rogue-ios/`)

| Item | Status | Notes |
|---|---|---|
| ACP client (JSON-RPC 2.0 over WebSocket) | 📅 Planned | Phase B |
| ChatView with streaming | 📅 Planned | Phase B |
| Tool call cards + approval gates | 📅 Planned | Phase B |
| Neo-Brutalist theme | 📅 Planned | Phase B |
| Multi-thread list + switcher | 📅 Planned | Phase C |
| Plugin system (SPM packages) | 📅 Planned | Phase E |
| Slash command palette | 📅 Planned | Phase E |
| File/image upload + preview | 📅 Planned | Phase E |
| Gateway failover (health check → auto-switch) | 📅 Planned | Phase F |
| Push notifications | 📅 Planned | Phase G |
| Widget + Siri Shortcuts | 📅 Planned | Phase G |
| App Store submission | 📅 Planned | Phase G |

### Track C — iMessage Bridge

| Item | Status | Notes |
|---|---|---|
| Mac daemon (Messages ↔ Gateway) | 📅 Planned | Phase D |
| Conversation → CLI session mapping | 📅 Planned | Phase D |
| Slash command routing over iMessage | 📅 Planned | Phase D |
| Tool approval via text reply | 📅 Planned | Phase D |
| File attachment relay | 📅 Planned | Phase D |

## Immediate next steps

1. Phase A: Scaffold `rogue-gateway/` — FastAPI app, WebSocket endpoint, ACP process spawn
2. Phase A: OpenCode adapter — `spawn_agent_process(["opencode", "acp"])`, stdio↔WS bridge
3. Phase A: Session manager with lattice-code's ACPSession pattern
4. Phase A: API key auth, health check endpoint

## Longer-horizon milestones

- **v0.1** (Phase A+B): Gateway + iOS chat — send message from iPhone to OpenCode, see streaming response
- **v0.2** (Phase C+D): Multi-CLI + threads + iMessage bridge
- **v0.3** (Phase E+F): Plugins + files + cloud failover
- **v1.0** (Phase G): All CLIs + polished + App Store

## Reference index

- (plans) `.claude/plans/rogue.md` — full architecture + phase plan
