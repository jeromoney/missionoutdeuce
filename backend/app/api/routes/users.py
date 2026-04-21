from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.db.session import get_db
from app.models.team_management import TeamMembership, User
from app.schemas.team_management import UserActiveRead, UserActiveUpdate


router = APIRouter(prefix="/user", tags=["user"])

_PRIVILEGED_ROLES = {"team_admin", "dispatcher"}


@router.patch("/active", response_model=UserActiveRead)
def set_user_active(body: UserActiveUpdate, request: Request, db: Session = Depends(get_db)):
    user_email = request.headers.get("x-missionout-user-email", "").strip().lower()
    if not user_email:
        raise HTTPException(status_code=401, detail="Missing authenticated user context.")

    user = db.scalar(
        select(User)
        .options(selectinload(User.memberships).selectinload(TeamMembership.team))
        .where(func.lower(User.email) == user_email)
    )
    if user is None:
        raise HTTPException(status_code=401, detail="Authenticated user is not recognized.")

    has_privileged_role = any(
        membership.team.is_active and _PRIVILEGED_ROLES.intersection(membership.roles)
        for membership in user.memberships
    )
    if not has_privileged_role:
        raise HTTPException(
            status_code=403,
            detail="Only team_admin or dispatcher members may update active status.",
        )

    user.is_active = body.is_active
    db.commit()
    return UserActiveRead(public_id=user.public_id, is_active=user.is_active)
