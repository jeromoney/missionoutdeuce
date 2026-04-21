from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.core.time import utc_now
from app.db.session import get_db
from app.models.incident import Incident, ResponseRecord
from app.models.team_management import Team, TeamMembership, User
from app.realtime import event_broker
from app.schemas.incident import (
    IncidentCreate,
    IncidentRead,
    IncidentUpdate,
    ResponseRecordCreate,
    ResponseRecordRead,
)


router = APIRouter(prefix="/incidents", tags=["incidents"])


def _serialize_incident(incident: Incident) -> IncidentRead:
    return IncidentRead(
        public_id=incident.public_id,
        title=incident.title,
        team_public_id=incident.team_ref.public_id if incident.team_ref is not None else None,
        location=incident.location,
        created=incident.created_at,
        notes=incident.notes,
        active=incident.active,
        responses=[
            ResponseRecordRead(
                user_public_id=response.user.public_id,
                status=response.status,
                rank=response.rank,
                updated=response.updated_at,
            )
            for response in incident.responses
        ],
    )


def _load_authenticated_user(*, request: Request, db: Session) -> User:
    user_email = request.headers.get("x-missionout-user-email", "").strip().lower()
    if not user_email:
        raise HTTPException(
            status_code=401,
            detail="Missing authenticated user context.",
        )

    user = db.scalar(
        select(User)
        .options(selectinload(User.memberships).selectinload(TeamMembership.team))
        .where(func.lower(User.email) == user_email)
    )
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=401,
            detail="Authenticated user is not recognized.",
        )

    return user


def _authorized_dispatcher_memberships(user: User) -> list[TeamMembership]:
    return [
        membership
        for membership in user.memberships
        if membership.team.is_active
        and "dispatcher" in membership.roles
    ]


@router.get("", response_model=list[IncidentRead])
def list_incidents(request: Request, db: Session = Depends(get_db)):
    user = _load_authenticated_user(request=request, db=db)
    visible_team_ids = sorted(
        {
            membership.team_id
            for membership in user.memberships
            if membership.team.is_active
        }
    )
    if not visible_team_ids:
        return []

    recent_cutoff = utc_now() - timedelta(days=7)
    statement = (
        select(Incident)
        .options(
            selectinload(Incident.responses).selectinload(ResponseRecord.user),
            selectinload(Incident.team_ref),
        )
        .where(Incident.created_at >= recent_cutoff)
        .where(Incident.team_id.in_(visible_team_ids))
        .order_by(Incident.created_at.desc())
    )

    incidents = db.scalars(statement).all()

    return [_serialize_incident(incident) for incident in incidents]


@router.post("", response_model=IncidentRead, status_code=201)
def create_incident(payload: IncidentCreate, request: Request, db: Session = Depends(get_db)):
    team: Team | None = None
    user_email = request.headers.get("x-missionout-user-email", "").strip()
    if user_email:
        user = _load_authenticated_user(request=request, db=db)
        dispatcher_memberships = _authorized_dispatcher_memberships(user)
        if not dispatcher_memberships:
            raise HTTPException(
                status_code=403,
                detail="Authenticated user does not have dispatcher access for any team.",
            )

        matching_membership = next(
            (
                membership
                for membership in dispatcher_memberships
                if membership.team.public_id == payload.team_public_id
            ),
            None,
        )
        if matching_membership is not None:
            team = matching_membership.team
        elif len(dispatcher_memberships) == 1:
            team = dispatcher_memberships[0].team
        else:
            raise HTTPException(
                status_code=400,
                detail="Requested team is not available to the authenticated dispatcher.",
            )
    else:
        team = db.scalar(select(Team).where(Team.public_id == payload.team_public_id))
        if team is None:
            raise HTTPException(status_code=400, detail="Unknown team")

    incident = Incident(
        title=payload.title,
        team_id=team.id,
        location=payload.location,
        notes=payload.notes,
        active=payload.active,
    )
    db.add(incident)
    db.commit()
    db.refresh(incident)
    db.refresh(team)
    event_broker.publish(
        event_type="incident.created",
        team_id=team.id,
        payload={
            "incident_public_id": incident.public_id,
            "team_public_id": team.public_id,
            "title": incident.title,
            "created": incident.created_at.isoformat(),
        },
    )
    return _serialize_incident(incident)


@router.patch("/{incident_public_id}", response_model=IncidentRead)
def update_incident(
    incident_public_id: str,
    payload: IncidentUpdate,
    db: Session = Depends(get_db),
):
    incident = db.scalar(
        select(Incident)
        .options(
            selectinload(Incident.responses).selectinload(ResponseRecord.user),
            selectinload(Incident.team_ref),
        )
        .where(Incident.public_id == incident_public_id)
    )
    if incident is None:
        raise HTTPException(status_code=404, detail="Incident not found")

    incident.title = payload.title
    incident.location = payload.location
    incident.notes = payload.notes
    incident.active = payload.active

    db.commit()
    db.refresh(incident)
    return _serialize_incident(incident)


@router.post("/{incident_public_id}/responses", response_model=ResponseRecordRead, status_code=201)
def create_incident_response(
    incident_public_id: str,
    payload: ResponseRecordCreate,
    request: Request,
    db: Session = Depends(get_db),
):
    user = _load_authenticated_user(request=request, db=db)
    incident = db.scalar(
        select(Incident)
        .options(selectinload(Incident.team_ref))
        .where(Incident.public_id == incident_public_id)
    )
    if incident is None:
        raise HTTPException(status_code=404, detail="Incident not found")

    authorized_membership = next(
        (
            membership
            for membership in user.memberships
            if membership.team_id == incident.team_id
        ),
        None,
    )
    if authorized_membership is None:
        raise HTTPException(
            status_code=403,
            detail="Authenticated user does not belong to the incident team.",
        )

    response = db.scalar(
        select(ResponseRecord)
        .options(selectinload(ResponseRecord.user))
        .where(
            ResponseRecord.incident_id == incident.id,
            ResponseRecord.user_id == user.id,
        )
    )

    if response is None:
        response = ResponseRecord(
            incident_id=incident.id,
            user_id=user.id,
            status=payload.status,
            source=payload.source,
            rank=payload.rank,
        )
        db.add(response)
    else:
        response.status = payload.status
        response.source = payload.source
        response.rank = payload.rank

    db.commit()
    db.refresh(response)
    db.refresh(user)
    return ResponseRecordRead(
        user_public_id=user.public_id,
        status=response.status,
        rank=response.rank,
        updated=response.updated_at,
    )
