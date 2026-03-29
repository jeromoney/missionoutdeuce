from fastapi import APIRouter, Depends, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
import requests
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.db.session import get_db
from app.models.team_management import TeamMembership, User
from app.schemas.auth import AuthTeamMembershipRead, AuthUserRead, GoogleAuthRequest


router = APIRouter(prefix="/auth", tags=["auth"])

GOOGLE_USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo"
GOOGLE_ACCESS_TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo"


def _verify_google_identity(payload: GoogleAuthRequest) -> dict:
    if payload.id_token:
        try:
            token_info = id_token.verify_oauth2_token(
                payload.id_token,
                google_requests.Request(),
                None,
            )
        except Exception as error:  # pragma: no cover - external verification
            raise HTTPException(
                status_code=401,
                detail="Invalid Google token",
            ) from error

        audience = token_info.get("aud")
        if audience not in settings.google_client_ids:
            raise HTTPException(
                status_code=401,
                detail="Google token audience is not allowed for this backend.",
            )

        return token_info

    if not payload.access_token:
        raise HTTPException(
            status_code=400,
            detail="Missing Google token.",
        )

    try:
        tokeninfo_response = requests.get(
            GOOGLE_ACCESS_TOKENINFO_URL,
            params={"access_token": payload.access_token},
            timeout=10,
        )
    except requests.RequestException as error:  # pragma: no cover - external verification
        raise HTTPException(
            status_code=502,
            detail="Google token verification request failed.",
        ) from error

    if tokeninfo_response.status_code != 200:
        raise HTTPException(
            status_code=401,
            detail="Invalid Google access token",
        )

    token_info = tokeninfo_response.json()
    audience = token_info.get("aud") or token_info.get("issued_to")
    if audience not in settings.google_client_ids:
        raise HTTPException(
            status_code=401,
            detail="Google token audience is not allowed for this backend.",
        )

    try:
        userinfo_response = requests.get(
            GOOGLE_USERINFO_URL,
            headers={"Authorization": f"Bearer {payload.access_token}"},
            timeout=10,
        )
    except requests.RequestException as error:  # pragma: no cover - external verification
        raise HTTPException(
            status_code=502,
            detail="Google userinfo request failed.",
        ) from error

    if userinfo_response.status_code != 200:
        raise HTTPException(
            status_code=401,
            detail="Unable to load Google user profile.",
        )

    userinfo = userinfo_response.json()
    userinfo.setdefault("aud", audience)
    return userinfo


@router.post("/google", response_model=AuthUserRead)
def google_auth(payload: GoogleAuthRequest, db: Session = Depends(get_db)):
    if not settings.google_client_ids:
        raise HTTPException(
            status_code=500,
            detail="GOOGLE_CLIENT_ID is not configured on the backend.",
        )

    token_info = _verify_google_identity(payload)

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

    user = db.scalar(
        select(User)
        .options(selectinload(User.memberships).selectinload(TeamMembership.team))
        .where(User.email == email)
    )
    if user is None:
        user = User(
            name=name,
            email=email,
            phone="",
            is_active=True,
        )
        db.add(user)
        db.commit()
        user = db.scalar(
            select(User)
            .options(selectinload(User.memberships).selectinload(TeamMembership.team))
            .where(User.email == email)
        )

    team_memberships: list[AuthTeamMembershipRead] = []
    if user is not None:
        active_memberships = [
            membership
            for membership in user.memberships
            if membership.is_active and membership.team.is_active
        ]
        team_memberships = [
            AuthTeamMembershipRead(
                team_id=membership.team_id,
                team_name=membership.team.name,
                roles=list(membership.roles),
            )
            for membership in sorted(active_memberships, key=lambda membership: membership.team_id)
        ]

    return AuthUserRead(
        name=name,
        initials=initials,
        global_permissions=[],
        team_memberships=team_memberships,
        email=email,
    )
