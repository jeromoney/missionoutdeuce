from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.db.session import get_db
from app.models.team_management import Device, Team, TeamMembership, User
from app.schemas.team_management import DeviceRead, TeamMemberCreate, TeamMemberRead, TeamMemberUpdate


router = APIRouter(prefix="/teams", tags=["teams"])


def _get_team_or_404(team_id: int, db: Session) -> Team:
    team = db.get(Team, team_id)
    if team is None:
        raise HTTPException(status_code=404, detail="Team not found")
    return team


def _serialize_membership(membership: TeamMembership) -> TeamMemberRead:
    return TeamMemberRead(
        id=membership.id,
        user_id=membership.user_id,
        team_id=membership.team_id,
        name=membership.user.name,
        email=membership.user.email,
        phone=membership.user.phone,
        roles=list(membership.roles),
        is_active=membership.is_active,
        granted_at=membership.granted_at,
        revoked_at=membership.revoked_at,
    )


@router.get("/{team_id}/members", response_model=list[TeamMemberRead])
def list_team_members(team_id: int, db: Session = Depends(get_db)):
    _get_team_or_404(team_id, db)
    memberships = db.scalars(
        select(TeamMembership)
        .options(joinedload(TeamMembership.user))
        .where(TeamMembership.team_id == team_id)
        .order_by(TeamMembership.id.asc())
    ).all()
    return [_serialize_membership(membership) for membership in memberships]


@router.post("/{team_id}/members", response_model=TeamMemberRead, status_code=201)
def create_team_member(
    team_id: int,
    payload: TeamMemberCreate,
    db: Session = Depends(get_db),
):
    _get_team_or_404(team_id, db)

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
            TeamMembership.team_id == team_id,
            TeamMembership.user_id == user.id,
        )
    )
    if existing_membership is not None:
        raise HTTPException(status_code=409, detail="User is already a member of this team")

    membership = TeamMembership(
        user_id=user.id,
        team_id=team_id,
        roles=payload.roles,
        is_active=payload.is_active,
        revoked_at=None if payload.is_active else datetime.utcnow(),
    )
    db.add(membership)
    db.commit()
    db.refresh(membership)
    membership = db.scalar(
        select(TeamMembership)
        .options(joinedload(TeamMembership.user))
        .where(TeamMembership.id == membership.id)
    )
    return _serialize_membership(membership)


@router.patch("/{team_id}/members/{membership_id}", response_model=TeamMemberRead)
def update_team_member(
    team_id: int,
    membership_id: int,
    payload: TeamMemberUpdate,
    db: Session = Depends(get_db),
):
    _get_team_or_404(team_id, db)
    membership = db.scalar(
        select(TeamMembership)
        .options(joinedload(TeamMembership.user))
        .where(
            TeamMembership.id == membership_id,
            TeamMembership.team_id == team_id,
        )
    )
    if membership is None:
        raise HTTPException(status_code=404, detail="Team membership not found")

    if payload.roles is not None:
        membership.roles = payload.roles

    if payload.is_active is not None:
        membership.is_active = payload.is_active
        membership.user.is_active = payload.is_active
        membership.revoked_at = None if payload.is_active else datetime.utcnow()

    db.commit()
    db.refresh(membership)
    return _serialize_membership(membership)


@router.get("/{team_id}/devices", response_model=list[DeviceRead])
def list_team_devices(team_id: int, db: Session = Depends(get_db)):
    _get_team_or_404(team_id, db)
    devices = db.scalars(
        select(Device)
        .join(Device.user)
        .join(User.memberships)
        .options(joinedload(Device.user))
        .where(TeamMembership.team_id == team_id)
        .order_by(Device.last_seen.desc())
    ).all()
    return [
        DeviceRead(
            id=device.id,
            user_id=device.user_id,
            user_name=device.user.name,
            platform=device.platform,
            push_token=device.push_token,
            last_seen=device.last_seen,
            is_active=device.is_active,
            is_verified=device.is_verified,
        )
        for device in devices
    ]
