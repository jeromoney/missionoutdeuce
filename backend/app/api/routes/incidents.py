from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.session import get_db
from app.models.incident import Incident
from app.schemas.incident import IncidentRead, ResponseRecordRead
from app.services.formatters import relative_time_label


router = APIRouter(prefix="/incidents", tags=["incidents"])


@router.get("", response_model=list[IncidentRead])
def list_incidents(db: Session = Depends(get_db)):
    incidents = db.scalars(
        select(Incident)
        .options(selectinload(Incident.responses))
        .order_by(Incident.created_at.desc())
    ).all()

    return [
        IncidentRead(
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
        for incident in incidents
    ]
