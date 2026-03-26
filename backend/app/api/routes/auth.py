from fastapi import APIRouter, Depends, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.db.session import get_db
from app.models.team_management import TeamMembership, User
from app.schemas.auth import AuthTeamMembershipRead, AuthUserRead, GoogleAuthRequest


router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/google", response_model=AuthUserRead)
def google_auth(payload: GoogleAuthRequest, db: Session = Depends(get_db)):
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
