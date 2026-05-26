"""Authentication — API key generation and validation."""

from __future__ import annotations

import secrets
from pathlib import Path

from pydantic_settings import BaseSettings


class AuthSettings(BaseSettings):
    gateway_auth_token: str = ""
    model_config = {"env_prefix": "ROGUE_", "env_file": ".env"}


_settings = AuthSettings()
_config_path = Path.home() / ".config" / "rogue" / "gateway-token"


def ensure_token() -> str:
    if _settings.gateway_auth_token:
        return _settings.gateway_auth_token

    try:
        _config_path.parent.mkdir(parents=True, exist_ok=True)
        if _config_path.exists():
            return _config_path.read_text().strip()
    except OSError:
        pass

    token = secrets.token_urlsafe(32)
    try:
        _config_path.write_text(token)
        _config_path.chmod(0o600)
    except OSError:
        pass
    return token


def verify_token(token: str) -> bool:
    if not token:
        return False
    expected = ensure_token()
    return secrets.compare_digest(token, expected)
