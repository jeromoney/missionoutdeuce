from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.session import get_db
from app.models.incident import Incident
from app.schemas.incident import (
    IncidentCreate,
    IncidentRead,
    IncidentUpdate,
    ResponseRecordRead,
)
from app.services.formatters import relative_time_label


router = APIRouter(prefix="/incidents", tags=["incidents"])


def _serialize_incident(incident: Incident) -> IncidentRead:
    return IncidentRead(
        id=incident.id,
        title=incident.title,
        team=incident.team,
        location=incident.location,
        created=relative_time_label(incident.created_at),
        notes=incident.notes,
        active=incident.active,
        responses=[
            ResponseRecordRead.model_validate(response)
            for response in incident.responses
        ],
    )


@router.get("", response_model=list[IncidentRead])
def list_incidents(db: Session = Depends(get_db)):
    incidents = db.scalars(
        select(Incident)
        .options(selectinload(Incident.responses))
        .order_by(Incident.created_at.desc())
    ).all()

    return [_serialize_incident(incident) for incident in incidents]


@router.post("", response_model=IncidentRead, status_code=201)
def create_incident(payload: IncidentCreate, db: Session = Depends(get_db)):
    incident = Incident(
        title=payload.title,
        team=payload.team,
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
        .options(selectinload(Incident.responses))
        .where(Incident.id == incident_id)
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
