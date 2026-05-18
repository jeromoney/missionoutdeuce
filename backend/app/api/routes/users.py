from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import _load_user_by_email, _set_rls_gucs, get_firebase_claims
from app.db.session import get_db
from app.models.team_management import TeamMembership, User
from app.schemas.auth import AuthTeamMembershipRead, AuthUserRead


router = APIRouter(tags=["users"])


def _build_auth_user_read(*, email: str, name: str, user: User | None) -> AuthUserRead:
    parts = [part for part in name.split() if part]
    if len(parts) >= 2:
        initials = f"{parts[0][0]}{parts[1][0]}".upper()
    elif parts:
        initials = parts[0][:2].upper()
    else:
        initials = "MO"

    team_memberships: list[AuthTeamMembershipRead] = []
    if user is not None:
        active = [m for m in user.memberships if m.is_active and m.team.is_active]
        team_memberships = [
            AuthTeamMembershipRead(
                team_public_id=m.team.public_id,
                team_name=m.team.name,
                roles=list(m.roles),
            )
            for m in sorted(active, key=lambda m: m.team_id)
        ]

    return AuthUserRead(
        public_id=user.public_id if user is not None else "",
        name=name,
        initials=initials,
        global_permissions=[],
        team_memberships=team_memberships,
        email=email,
    )


@router.get("/users/me", response_model=AuthUserRead)
def get_me(
    request: Request,
    claims: dict = Depends(get_firebase_claims),
    db: Session = Depends(get_db),
) -> AuthUserRead:
    """Return the MissionOut profile for the authenticated Firebase user.

    Returns empty team_memberships when the user has no MissionOut account
    (unprovisioned state). If X-Team-Id is provided it is validated against
    active memberships and RLS GUCs are set for that team's role.
    """
    email = claims["email"]
    firebase_name = claims.get("name") or email

    user = _load_user_by_email(db, email)

    team_id_header = request.headers.get("X-Team-Id")
    if user is not None and team_id_header:
        matching = next(
            (
                m
                for m in user.memberships
                if m.team.public_id == team_id_header and m.is_active and m.team.is_active
            ),
            None,
        )
        if matching is None:
            raise HTTPException(
                status_code=403,
                detail="X-Team-Id is not a valid active team for this user.",
            )
        _set_rls_gucs(db, user.id, matching.role)

    name = user.name if user is not None else firebase_name
    return _build_auth_user_read(email=email, name=name, user=user)
