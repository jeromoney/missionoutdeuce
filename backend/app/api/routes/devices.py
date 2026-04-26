from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.api.deps import Principal, get_current_principal
from app.core.config import settings
from app.core.time import utc_now
from app.db.session import get_db
from app.models.team_management import TeamMembership, WebPushSubscription
from app.schemas.team_management import (
    WebPushPublicKeyRead,
    WebPushSubscriptionCreate,
    WebPushSubscriptionDelete,
    WebPushSubscriptionRead,
)


router = APIRouter(prefix="/devices", tags=["devices"])


def _serialize_subscription(subscription: WebPushSubscription) -> WebPushSubscriptionRead:
    return WebPushSubscriptionRead(
        public_id=subscription.public_id,
        user_public_id=subscription.user.public_id,
        team_public_id=subscription.team.public_id if subscription.team is not None else None,
        endpoint=subscription.endpoint,
        client=subscription.client,
        last_seen=subscription.last_seen,
        is_active=subscription.is_active,
    )


@router.get("/web-push/public-key", response_model=WebPushPublicKeyRead)
def get_web_push_public_key():
    if not settings.web_push_public_key or not settings.web_push_subject:
        raise HTTPException(
            status_code=500,
            detail="Web Push VAPID keys are not configured on the backend.",
        )

    return WebPushPublicKeyRead(
        public_key=settings.web_push_public_key,
        subject=settings.web_push_subject,
    )


@router.post("/web-push", response_model=WebPushSubscriptionRead, status_code=status.HTTP_201_CREATED)
def register_web_push_subscription(
    payload: WebPushSubscriptionCreate,
    response: Response,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    user = principal.user
    membership: TeamMembership | None = None

    if payload.team_public_id is not None:
        membership = db.scalar(
            select(TeamMembership)
            .options(joinedload(TeamMembership.team))
            .where(
                TeamMembership.user_id == user.id,
                TeamMembership.team.has(public_id=payload.team_public_id),
            )
        )
        if membership is None:
            raise HTTPException(
                status_code=403,
                detail="Authenticated user is not an active member of the requested team.",
            )

    subscription = db.scalar(
        select(WebPushSubscription).where(WebPushSubscription.endpoint == payload.endpoint)
    )
    now = utc_now()

    if subscription is None:
        subscription = WebPushSubscription(
            user_id=user.id,
            team_id=membership.team_id if membership is not None else None,
            endpoint=payload.endpoint,
            p256dh=payload.keys.p256dh,
            auth=payload.keys.auth,
            user_agent=payload.user_agent,
            client=payload.client,
            last_seen=now,
            is_active=True,
        )
        db.add(subscription)
    else:
        if subscription.user_id != user.id:
            raise HTTPException(
                status_code=409,
                detail="Web push subscription endpoint is already registered to another user.",
            )
        subscription.team_id = membership.team_id if membership is not None else None
        subscription.p256dh = payload.keys.p256dh
        subscription.auth = payload.keys.auth
        subscription.user_agent = payload.user_agent
        subscription.client = payload.client
        subscription.last_seen = now
        subscription.is_active = True
        response.status_code = status.HTTP_200_OK

    db.commit()
    db.refresh(subscription)
    db.refresh(subscription, attribute_names=["user", "team"])
    return _serialize_subscription(subscription)


@router.delete("/web-push", status_code=status.HTTP_204_NO_CONTENT)
def delete_web_push_subscription(
    payload: WebPushSubscriptionDelete,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
):
    subscription = db.scalar(
        select(WebPushSubscription).where(
            WebPushSubscription.user_id == principal.user.id,
            WebPushSubscription.endpoint == payload.endpoint,
        )
    )
    if subscription is not None:
        subscription.is_active = False
        subscription.last_seen = utc_now()
        db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
