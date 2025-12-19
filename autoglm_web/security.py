from __future__ import annotations

import os
import secrets
from pathlib import Path


def _autoglm_home() -> Path:
    return Path(os.environ.get("AUTOGLM_HOME", str(Path.home() / ".autoglm"))).expanduser()


def token_path() -> Path:
    return _autoglm_home() / "web_token"


def load_or_create_token() -> str:
    path = token_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        return path.read_text(encoding="utf-8").strip()
    token = secrets.token_urlsafe(32)
    path.write_text(token + "\n", encoding="utf-8")
    try:
        path.chmod(0o600)
    except Exception:
        pass
    return token


def reset_token() -> str:
    path = token_path()
    if path.exists():
        path.unlink()
    return load_or_create_token()


def token_matches(provided: str) -> bool:
    expected = load_or_create_token()
    return secrets.compare_digest(provided, expected)

