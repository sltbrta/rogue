"""Unit tests for CLI adapter registry and configs."""

from __future__ import annotations

from rogue_gateway.adapters.registry import CLI_REGISTRY


def test_opencode_config() -> None:
    c = CLI_REGISTRY["opencode"]
    assert c.name == "opencode"
    assert c.display_name == "OpenCode"
    assert c.command == ["opencode", "acp"]


def test_codex_config() -> None:
    c = CLI_REGISTRY["codex"]
    assert c.name == "codex"
    assert c.display_name == "Codex"
    assert "codex-acp" in c.command[2] or "codex-acp" in c.command[-1]


def test_gemini_config() -> None:
    c = CLI_REGISTRY["gemini"]
    assert c.name == "gemini"
    assert "--acp" in c.command


def test_all_clis_have_required_fields() -> None:
    for name, config in CLI_REGISTRY.items():
        assert config.name, f"CLI {name} missing name"
        assert config.display_name, f"CLI {name} missing display_name"
        assert config.command, f"CLI {name} missing command"
        assert len(config.command) >= 2, f"CLI {name} command too short"
