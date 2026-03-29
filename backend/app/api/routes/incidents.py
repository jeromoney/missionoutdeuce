from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.session import get_db
from app.models.incident import Incident, ResponseRecord
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
        id=incident.id,
        title=incident.title,
        team=incident.team,
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
