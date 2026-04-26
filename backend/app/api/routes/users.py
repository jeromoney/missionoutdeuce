from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import Principal, get_current_principal
from app.db.session import get_db
from app.schemas.team_management import UserActiveRead, UserActiveUpdate


router = APIRouter(prefix="/user", tags=["user"])

_PRIVILEGED_ROLES = {"team_admin", "dispatcher"}


@router.patch("/active", response_model=UserActiveRead)
def set_user_active(
    body: UserActiveUpdate,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    has_privileged_role = principal.role in _PRIVILEGED_ROLES or any(
        membership.team.is_active and _PRIVILEGED_ROLES.intersection(membership.roles or [])
        for membership in principal.user.memberships
    )
    if not has_privileged_role:
        raise HTTPException(
            status_code=403,
            detail="Only team_admin or dispatcher members may update active status.",
        )

    principal.user.is_active = body.is_active
    db.commit()
    return UserActiveRead(public_id=principal.user.public_id, is_active=principal.user.is_active)
