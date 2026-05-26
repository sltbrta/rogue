"""OpenCode adapter — spawns `opencode acp` and bridges stdio ↔ session."""

from __future__ import annotations

from .registry import CLIConfig

OPENCODE_CONFIG = CLIConfig(
    name="opencode",
    display_name="OpenCode",
    command=["opencode", "acp"],
)
