from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.db.session import get_db
from app.models.incident import Incident, ResponseRecord
from app.models.team_management import Team, TeamMembership, User
from app.schemas.incident import (
    IncidentCreate,
    IncidentRead,
    IncidentUpdate,
    ResponseRecordCreate,
    ResponseRecordRead,
)


router = APIRouter(prefix="/incidents", tags=["incidents"])


def _serialize_incident(incident: Incident) -> IncidentRead:
    team_name = incident.team_ref.name if incident.team_ref is not None else incident.legacy_team_name
    return IncidentRead(
        id=incident.id,
        title=incident.title,
        team=team_name,
        location=incident.location,
        created=incident.created_at,
        notes=incident.notes,
        active=incident.active,
        responses=[
            ResponseRecordRead.model_validate(response)
            for response in incident.responses
        ],
    )


@router.get("", response_model=list[IncidentRead])
def list_incidents(request: Request, db: Session = Depends(get_db)):
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

    visible_team_ids = sorted(
        {
            membership.team_id
            for membership in user.memberships
            if membership.is_active and membership.team.is_active
        }
    )
    if not visible_team_ids:
        return []

    recent_cutoff = datetime.utcnow() - timedelta(days=7)
    statement = (
        select(Incident)
        .options(selectinload(Incident.responses), selectinload(Incident.team_ref))
        .where(Incident.created_at >= recent_cutoff)
        .where(Incident.team_id.in_(visible_team_ids))
        .order_by(Incident.created_at.desc())
    )

    incidents = db.scalars(statement).all()

    return [_serialize_incident(incident) for incident in incidents]


@router.post("", response_model=IncidentRead, status_code=201)
def create_incident(payload: IncidentCreate, db: Session = Depends(get_db)):
    team = db.scalar(select(Team).where(Team.name == payload.team))
    if team is None:
        raise HTTPException(status_code=400, detail="Unknown team")

    incident = Incident(
        title=payload.title,
        legacy_team_name=team.name,
        team_id=team.id,
        location=payload.location,
        notes=payload.notes,
        active=payload.active,
    )
    db.add(incident)
    db.commit()
    db.refresh(incident)
    return _serialize_incident(incident)


@router.patch("/{incident_id}", response_model=IncidentRead)
def update_incident(
    incident_id: int,
    payload: IncidentUpdate,
    db: Session = Depends(get_db),
):
    incident = db.scalar(
        select(Incident)
        .options(selectinload(Incident.responses), selectinload(Incident.team_ref))
        .where(Incident.id == incident_id)
    )
    if incident is None:
        raise HTTPException(status_code=404, detail="Incident not found")

    incident.title = payload.title
    team = db.scalar(select(Team).where(Team.name == incident.legacy_team_name))
    if team is not None:
        incident.team_id = team.id
        incident.legacy_team_name = team.name
    incident.location = payload.location
    incident.notes = payload.notes
    incident.active = payload.active

    db.commit()
    db.refresh(incident)
    return _serialize_incident(incident)


@router.post("/{incident_id}/responses", response_model=ResponseRecordRead, status_code=201)
def create_incident_response(
    incident_id: int,
    payload: ResponseRecordCreate,
    db: Session = Depends(get_db),
):
    incident = db.scalar(select(Incident).where(Incident.id == incident_id))
    if incident is None:
        raise HTTPException(status_code=404, detail="Incident not found")

    response = ResponseRecord(
        incident_id=incident_id,
        name=payload.name,
        status=payload.status,
        detail=payload.detail,
        rank=payload.rank,
    )
    db.add(response)
    db.commit()
    db.refresh(response)
    return ResponseRecordRead.model_validate(response)
