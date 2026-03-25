from sqlalchemy import delete

from app.db.base import Base
from app.db.session import SessionLocal
from app.models.event import DeliveryEvent
from app.models.incident import Incident, ResponseRecord
from app.db.session import engine


def seed() -> None:
    Base.metadata.create_all(bind=engine)

    with SessionLocal() as db:
        db.execute(delete(ResponseRecord))
        db.execute(delete(Incident))
        db.execute(delete(DeliveryEvent))

        incidents = [
            Incident(
                title="Injured Climber Extraction",
                team="Chaffee SAR",
                location="Mt. Princeton Southwest Gully",
                notes="Subject reports lower-leg injury above treeline. Snowpack stable but wind increasing. Air asset on standby if ground extraction stalls.",
                active=True,
                responses=[
                    ResponseRecord(
                        name="Justin M.",
                        status="Responding",
                        detail="En route from Buena Vista with litter trailer.",
                        rank=0,
                    ),
                    ResponseRecord(
                        name="Sarah K.",
                        status="Responding",
                        detail="Switching to radio channel SAR-2 at trailhead.",
                        rank=0,
                    ),
                    ResponseRecord(
                        name="Mike D.",
                        status="Pending",
                        detail="Push delivered to Android device, no acknowledgement yet.",
                        rank=1,
                    ),
                ],
            ),
            Incident(
                title="Overdue Snowmobiler",
                team="Summit County Rescue",
                location="Georgia Pass East Approach",
                notes="Family lost contact after sunset. Last device ping near the pass. Team requested beacon cache and UTV support for rapid sweep.",
                active=True,
                responses=[
                    ResponseRecord(
                        name="Taylor P.",
                        status="Responding",
                        detail="Trailer loaded and meeting command at lot B.",
                        rank=0,
                    ),
                    ResponseRecord(
                        name="Chris E.",
                        status="Pending",
                        detail="Primary push sent, SMS escalation queued in 4 minutes.",
                        rank=1,
                    ),
                ],
            ),
        ]

        events = [
            DeliveryEvent(
                title="Primary FCM burst completed",
                detail="12 Android devices received the first-wave push for Injured Climber Extraction.",
                time_label="2m",
                icon="notifications",
                color="#4F6F95",
            ),
            DeliveryEvent(
                title="Responder acknowledged on lock screen",
                detail="Sarah K. marked Responding from the native alert screen before opening the app.",
                time_label="4m",
                icon="task_alt",
                color="#3F6D91",
            ),
        ]

        db.add_all(incidents)
        db.add_all(events)
        db.commit()


if __name__ == "__main__":
    seed()
