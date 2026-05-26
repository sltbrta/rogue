"""Unit tests for the Rogue Gateway WebSocket ACP bridge."""

from __future__ import annotations


def test_cli_registry_has_required_entries() -> None:
    from rogue_gateway.adapters.registry import CLI_REGISTRY

    assert "opencode" in CLI_REGISTRY
    assert "codex" in CLI_REGISTRY
    assert "gemini" in CLI_REGISTRY
    assert CLI_REGISTRY["opencode"].command == ["opencode", "acp"]


def test_auth_token_generate_and_verify() -> None:
    from rogue_gateway.auth import ensure_token, verify_token

    token = ensure_token()
    assert token
    assert len(token) >= 32
    assert verify_token(token)
    assert not verify_token("bad-token")
    assert not verify_token("")


def test_session_manager_create_and_close() -> None:
    from rogue_gateway.session.manager import SessionManager

    manager = SessionManager()
    assert len(manager._sessions) == 0
