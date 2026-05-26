"""Codex adapter — spawns `npx @zed-industries/codex-acp`."""

from __future__ import annotations

from .registry import CLIConfig

CODEX_CONFIG = CLIConfig(
    name="codex",
    display_name="Codex",
    command=["npx", "-y", "@zed-industries/codex-acp"],
    env_required=(("CODEX_API_KEY", "OPENAI_API_KEY"),),
    auth_files=("~/.codex/auth.json",),
    auth_setup_url="https://github.com/openai/codex-cli#authentication",
)
