from __future__ import annotations

from firebase_admin import messaging
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.push_delivery import PushDelivery
from app.models.team_management import Device
from app.core.time import utc_now


def dispatch_mobile_deliveries(db: Session, incident_id: int) -> None:
    rows = db.scalars(
        select(PushDelivery).where(
            PushDelivery.incident_id == incident_id,
            PushDelivery.channel == "mobile",
            PushDelivery.state == "created",
        )
    ).all()

    for delivery in rows:
        device: Device | None = delivery.device
        if device is None:
            delivery.state = "failed"
            delivery.last_error = "device_missing"
            db.commit()
            continue

        incident = delivery.incident
        body = incident.location or incident.notes or "New incident"

        try:
            message = messaging.Message(
                data={
                    "incident_public_id": incident.public_id,
                    "title": incident.title,
                    "body": body,
                },
                token=device.push_token,
                android=messaging.AndroidConfig(priority="high"),
            )
            messaging.send(message)
            delivery.state = "sent"
            delivery.attempt_count += 1
            delivery.last_attempt_at = utc_now()
        except messaging.UnregisteredError:
            delivery.state = "failed"
            delivery.last_error = "NOT_REGISTERED"
            delivery.attempt_count += 1
            delivery.last_attempt_at = utc_now()
            device.is_active = False
        except Exception as exc:
            delivery.state = "failed"
            delivery.last_error = str(exc)
            delivery.attempt_count += 1
            delivery.last_attempt_at = utc_now()

        db.commit()
