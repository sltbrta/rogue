"""Test configuration — shared fixtures for Rogue Gateway tests."""

from __future__ import annotations

import pytest

from rogue_gateway.adapters.registry import CLIConfig


@pytest.fixture
def opencode_config() -> CLIConfig:
    return CLIConfig(
        name="opencode",
        display_name="OpenCode",
        command=["opencode", "acp"],
    )


@pytest.fixture
def codex_config() -> CLIConfig:
    return CLIConfig(
        name="codex",
        display_name="Codex",
        command=["npx", "-y", "@zed-industries/codex-acp"],
    )


@pytest.fixture
def gemini_config() -> CLIConfig:
    return CLIConfig(
        name="gemini",
        display_name="Gemini",
        command=["npx", "-y", "@google/gemini-cli", "--acp"],
    )
