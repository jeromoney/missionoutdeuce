from fastapi import APIRouter, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

from app.core.config import settings
from app.schemas.auth import AuthUserRead, GoogleAuthRequest


router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/google", response_model=AuthUserRead)
def google_auth(payload: GoogleAuthRequest):
    if not settings.google_client_id:
        raise HTTPException(
            status_code=500,
            detail="GOOGLE_CLIENT_ID is not configured on the backend.",
        )

    try:
        token_info = id_token.verify_oauth2_token(
            payload.id_token,
            google_requests.Request(),
            settings.google_client_id,
        )
    except Exception as error:  # pragma: no cover - external verification
        raise HTTPException(
            status_code=401,
            detail="Invalid Google token",
        ) from error

    email = token_info.get("email")
    name = token_info.get("name") or email or "MissionOut User"
    if not email:
        raise HTTPException(
            status_code=400,
            detail="Google account email missing",
        )

    parts = [part for part in name.split() if part]
    if len(parts) >= 2:
        initials = f"{parts[0][0]}{parts[1][0]}".upper()
    elif parts:
        initials = parts[0][:2].upper()
    else:
        initials = "MO"

    return AuthUserRead(
        name=name,
        initials=initials,
        global_permissions=[],
        team_memberships=[],
        email=email,
    )
