"""Gemini adapter — spawns `npx @google/gemini-cli --acp`."""

from __future__ import annotations

from .registry import CLIConfig

GEMINI_CONFIG = CLIConfig(
    name="gemini",
    display_name="Gemini",
    command=["npx", "-y", "@google/gemini-cli", "--acp"],
    env_required=(("GEMINI_API_KEY", "GOOGLE_AI_API_KEY"),),
    auth_files=("~/.gemini/gemini-credentials.json", "~/.gemini/oauth_creds.json"),
    auth_setup_url="https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/authentication.mdx",
)
