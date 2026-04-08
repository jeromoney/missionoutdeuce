import asyncio

from fastapi import APIRouter, Depends
from fastapi import HTTPException, Request
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.session import get_db
from app.models.event import DeliveryEvent
from app.models.team_management import TeamMembership, User
from app.realtime import event_broker
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
            time=event.created_at,
            icon=event.icon,
            color=event.color,
        )
        for event in events
    ]


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
        .where(User.email == user_email)
    )
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=401,
            detail="Authenticated user is not recognized.",
        )

    return user


@router.get(
    "/stream",
    summary="Stream Open-Tab Events",
    description=(
        "Streams supplemental open-tab event notifications over Server-Sent "
        "Events for authenticated web clients. Incident events are scoped to "
        "the caller's active team memberships."
    ),
    responses={
        200: {
            "content": {
                "text/event-stream": {
                    "schema": {
                        "type": "string",
                        "example": (
                            "event: incident.created\n"
                            'data: {"incident_public_id":"2cb1d6d9-7c83-4dc9-a9c6-54be6beea10b","team_public_id":"58ceaf6e-4f7d-4d0a-bca0-90d7a3b31591","title":"Injured Climber Extraction"}\n\n'
                        ),
                    }
                }
            },
            "description": "Server-Sent Events stream.",
        }
    },
)
async def stream_events(request: Request, db: Session = Depends(get_db)):
    user = _load_authenticated_user(request=request, db=db)
    team_ids = {
        membership.team_id
        for membership in user.memberships
        if membership.is_active and membership.team.is_active
    }
    if not team_ids:
        raise HTTPException(
            status_code=403,
            detail="Authenticated user does not have access to any active teams.",
        )

    subscription_id, queue = event_broker.subscribe(team_ids=team_ids)

    async def event_stream():
        try:
            yield ": connected\n\n"
            while True:
                if await request.is_disconnected():
                    break
                try:
                    message = await asyncio.wait_for(queue.get(), timeout=15)
                except TimeoutError:
                    yield ": keep-alive\n\n"
                    continue
                yield message
        finally:
            event_broker.unsubscribe(subscription_id)

    return StreamingResponse(event_stream(), media_type="text/event-stream")
