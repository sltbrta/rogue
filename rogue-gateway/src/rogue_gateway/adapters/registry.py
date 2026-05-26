"""CLI registry — known ACP-compatible CLIs and their configurations.

Reuses the ACPAgentConfig pattern from lattice-code.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class CLIConfig:
    name: str
    display_name: str
    command: list[str]
    env_required: tuple[str | tuple[str, ...], ...] = ()
    auth_files: tuple[str, ...] = ()
    auth_setup_url: str = ""


CLI_REGISTRY: Mapping[str, CLIConfig] = {
    "opencode": CLIConfig(
        name="opencode",
        display_name="OpenCode",
        command=["opencode", "acp"],
    ),
    "codex": CLIConfig(
        name="codex",
        display_name="Codex",
        command=["npx", "-y", "@zed-industries/codex-acp"],
        env_required=(("CODEX_API_KEY", "OPENAI_API_KEY"),),
        auth_files=("~/.codex/auth.json",),
        auth_setup_url="https://github.com/openai/codex-cli#authentication",
    ),
    "gemini": CLIConfig(
        name="gemini",
        display_name="Gemini",
        command=["npx", "-y", "@google/gemini-cli", "--acp"],
        env_required=(("GEMINI_API_KEY", "GOOGLE_AI_API_KEY"),),
        auth_files=("~/.gemini/gemini-credentials.json", "~/.gemini/oauth_creds.json"),
        auth_setup_url="https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/authentication.mdx",
    ),
    "claude": CLIConfig(
        name="claude",
        display_name="Claude Code",
        command=["claude", "--acp"],
    ),
    "cursor": CLIConfig(
        name="cursor",
        display_name="Cursor",
        command=["cursor", "--acp"],
    ),
    "qwen": CLIConfig(
        name="qwen",
        display_name="Qwen Code",
        command=["qwen", "acp"],
    ),
    "kimi": CLIConfig(
        name="kimi",
        display_name="Kimi",
        command=["kimi", "acp"],
    ),
}
