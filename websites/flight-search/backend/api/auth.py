"""Authentication endpoints for passkey gate."""

import hashlib
import os

from fastapi import APIRouter, Request, Response
from fastapi.responses import JSONResponse
from pydantic import BaseModel

router = APIRouter(prefix="/api/auth", tags=["auth"])

PASSKEY = "flyingagents"
# Token derived from passkey so it stays stable across restarts.
AUTH_TOKEN = hashlib.sha256(f"flight_auth:{PASSKEY}".encode()).hexdigest()


def _require_passkey() -> bool:
    """Return True unless REQUIRE_PASSKEY is explicitly set to 'false'."""
    return os.environ.get("REQUIRE_PASSKEY", "true").lower() != "false"


class PasskeyBody(BaseModel):
    passkey: str


@router.post("/verify")
async def verify(body: PasskeyBody, response: Response):
    if not _require_passkey():
        _set_auth_cookie(response)
        return {"ok": True}

    if body.passkey != PASSKEY:
        return JSONResponse(status_code=401, content={"detail": "Invalid passkey"})

    _set_auth_cookie(response)
    return {"ok": True}


def _set_auth_cookie(response: Response) -> None:
    """Set the auth cookie. Uses SameSite=None + Secure for HF Spaces iframe."""
    response.set_cookie(
        key="flight_auth",
        value=AUTH_TOKEN,
        httponly=True,
        samesite="none",
        secure=True,
        max_age=60 * 60 * 24 * 30,  # 30 days
    )


@router.get("/check")
async def check(request: Request):
    if not _require_passkey():
        return {"ok": True}

    token = request.cookies.get("flight_auth")
    if token != AUTH_TOKEN:
        return JSONResponse(status_code=401, content={"detail": "Not authenticated"})
    return {"ok": True}
