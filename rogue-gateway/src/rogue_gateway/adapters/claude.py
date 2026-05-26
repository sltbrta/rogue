"""Claude adapter — spawns `claude --acp`."""

from __future__ import annotations

from .registry import CLIConfig

CLAUDE_CONFIG = CLIConfig(
    name="claude",
    display_name="Claude Code",
    command=["claude", "--acp"],
)
