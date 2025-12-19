from __future__ import annotations

from dataclasses import dataclass

from fastapi import Header, HTTPException

from .security import token_matches


@dataclass(frozen=True)
class AuthResult:
    token: str


def require_token(authorization: str | None = Header(default=None)) -> AuthResult:
    if not authorization:
        raise HTTPException(status_code=401, detail="缺少 Authorization 请求头")
    parts = authorization.split(" ", 1)
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Authorization 格式错误，应为 Bearer <token>")
    provided = parts[1].strip()
    if not token_matches(provided):
        raise HTTPException(status_code=403, detail="Token 无效")
    return AuthResult(token=provided)

