from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.event import DeliveryEvent
from app.schemas.event import DeliveryEventRead


router = APIRouter(prefix="/events", tags=["events"])


@router.get("/delivery-feed", response_model=list[DeliveryEventRead])
def list_delivery_feed(db: Session = Depends(get_db)):
    events = db.scalars(
        select(DeliveryEvent).order_by(DeliveryEvent.created_at.desc())
    ).all()

    return [
        DeliveryEventRead(
            title=event.title,
            detail=event.detail,
            time=event.time_label,
            icon=event.icon,
            color=event.color,
        )
        for event in events
    ]
