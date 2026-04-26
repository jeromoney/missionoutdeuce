from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.api.deps import Principal, get_current_principal
from app.db.session import get_db
from app.models.team_management import Device, Team, TeamMembership, User
from app.schemas.team_management import DeviceRead, TeamMemberCreate, TeamMemberRead, TeamMemberUpdate


router = APIRouter(prefix="/teams", tags=["teams"])


def _get_team_or_404(team_public_id: str, db: Session) -> Team:
    team = db.scalar(select(Team).where(Team.public_id == team_public_id))
    if team is None:
        raise HTTPException(status_code=404, detail="Team not found")
    return team


def _ensure_team_member(principal: Principal, team: Team) -> TeamMembership:
    membership = next(
        (
            m
            for m in principal.user.memberships
            if m.team_id == team.id and m.team.is_active
        ),
        None,
    )
    if membership is None:
        raise HTTPException(
            status_code=403,
            detail="Authenticated user is not a member of this team.",
        )
    return membership


def _ensure_team_admin(principal: Principal, team: Team) -> TeamMembership:
    membership = _ensure_team_member(principal, team)
    if membership.role != "team_admin" and "team_admin" not in (membership.roles or []):
        raise HTTPException(
            status_code=403,
            detail="Only team_admin members may modify team memberships.",
        )
    return membership


def _serialize_membership(membership: TeamMembership) -> TeamMemberRead:
    return TeamMemberRead(
        public_id=membership.public_id,
        user_public_id=membership.user.public_id,
        team_public_id=membership.team.public_id,
        name=membership.user.name,
        email=membership.user.email,
        phone=membership.user.phone,
        roles=list(membership.roles),
        is_active=membership.user.is_active,
        granted_at=membership.granted_at,
    )


def _pick_primary_role(roles: list[str]) -> str:
    for candidate in ("team_admin", "dispatcher", "responder"):
        if candidate in roles:
            return candidate
    return "responder"


@router.get("/{team_public_id}/members", response_model=list[TeamMemberRead])
def list_team_members(
    team_public_id: str,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    team = _get_team_or_404(team_public_id, db)
    _ensure_team_member(principal, team)
    memberships = db.scalars(
        select(TeamMembership)
        .options(joinedload(TeamMembership.user), joinedload(TeamMembership.team))
        .where(TeamMembership.team_id == team.id)
        .order_by(TeamMembership.id.asc())
    ).all()
    return [_serialize_membership(membership) for membership in memberships]


@router.post("/{team_public_id}/members", response_model=TeamMemberRead, status_code=201)
def create_team_member(
    team_public_id: str,
    payload: TeamMemberCreate,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    team = _get_team_or_404(team_public_id, db)
    _ensure_team_admin(principal, team)

    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None:
        user = User(
            name=payload.name,
            email=payload.email,
            phone=payload.phone,
            is_active=payload.is_active,
        )
        db.add(user)
        db.flush()
    else:
        user.name = payload.name
        user.phone = payload.phone
        user.is_active = payload.is_active

    existing_membership = db.scalar(
        select(TeamMembership).where(
            TeamMembership.team_id == team.id,
            TeamMembership.user_id == user.id,
        )
    )
    if existing_membership is not None:
        raise HTTPException(status_code=409, detail="User is already a member of this team")

    membership = TeamMembership(
        user_id=user.id,
        team_id=team.id,
        roles=payload.roles,
        role=_pick_primary_role(payload.roles),
    )
    db.add(membership)
    db.commit()
    db.refresh(membership)
    membership = db.scalar(
        select(TeamMembership)
        .options(joinedload(TeamMembership.user), joinedload(TeamMembership.team))
        .where(TeamMembership.id == membership.id)
    )
    return _serialize_membership(membership)


@router.patch("/{team_public_id}/members/{membership_public_id}", response_model=TeamMemberRead)
def update_team_member(
    team_public_id: str,
    membership_public_id: str,
    payload: TeamMemberUpdate,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    team = _get_team_or_404(team_public_id, db)
    _ensure_team_admin(principal, team)
    membership = db.scalar(
        select(TeamMembership)
        .options(joinedload(TeamMembership.user), joinedload(TeamMembership.team))
        .where(
            TeamMembership.public_id == membership_public_id,
            TeamMembership.team_id == team.id,
        )
    )
    if membership is None:
        raise HTTPException(status_code=404, detail="Team membership not found")

    if payload.roles is not None:
        membership.roles = payload.roles
        membership.role = _pick_primary_role(payload.roles)

    if payload.is_active is not None:
        membership.user.is_active = payload.is_active

    db.commit()
    db.refresh(membership)
    return _serialize_membership(membership)


@router.delete("/{team_public_id}/members/{membership_public_id}", status_code=204)
def delete_team_member(
    team_public_id: str,
    membership_public_id: str,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    team = _get_team_or_404(team_public_id, db)
    _ensure_team_admin(principal, team)
    membership = db.scalar(
        select(TeamMembership).where(
            TeamMembership.public_id == membership_public_id,
            TeamMembership.team_id == team.id,
        )
    )
    if membership is None:
        raise HTTPException(status_code=404, detail="Team membership not found")
    db.delete(membership)
    db.commit()


@router.get("/{team_public_id}/devices", response_model=list[DeviceRead])
def list_team_devices(
    team_public_id: str,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    team = _get_team_or_404(team_public_id, db)
    _ensure_team_member(principal, team)
    devices = db.scalars(
        select(Device)
        .join(Device.user)
        .join(User.memberships)
        .options(joinedload(Device.user))
        .where(TeamMembership.team_id == team.id)
        .order_by(Device.last_seen.desc())
    ).all()
    return [
        DeviceRead(
            public_id=device.public_id,
            user_public_id=device.user.public_id,
            user_name=device.user.name,
            platform=device.platform,
            push_token=device.push_token,
            last_seen=device.last_seen,
            is_active=device.is_active,
            is_verified=device.is_verified,
        )
        for device in devices
    ]
