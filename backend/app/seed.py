from datetime import datetime, timedelta

from sqlalchemy import delete, text

from app.db.base import Base
from app.db.session import SessionLocal
from app.models.event import DeliveryEvent
from app.models.incident import Incident, ResponseRecord
from app.models.team_management import Device, Team, TeamMembership, User
from app.db.session import engine


def seed() -> None:
    Base.metadata.create_all(bind=engine)

    with SessionLocal() as db:
        if db.bind is not None and db.bind.dialect.name == "postgresql":
            # Keep seeded IDs predictable so clients can rely on stable team ids.
            db.execute(
                text(
                    "TRUNCATE TABLE "
                    "devices, team_memberships, users, teams, responses, incidents, delivery_events "
                    "RESTART IDENTITY CASCADE"
                )
            )
        else:
            db.execute(delete(Device))
            db.execute(delete(TeamMembership))
            db.execute(delete(User))
            db.execute(delete(Team))
            db.execute(delete(ResponseRecord))
            db.execute(delete(Incident))
            db.execute(delete(DeliveryEvent))

        now = datetime.utcnow()
        within_one_day = now - timedelta(hours=12)
        four_days_ago = now - timedelta(days=4)
        four_weeks_ago = now - timedelta(weeks=4)
        one_year_ago = now - timedelta(days=365)

        chaffee_team = Team(name="Chaffee SAR", is_active=True)
        summit_team = Team(name="Summit County Rescue", is_active=True)

        justin = User(
            name="Justin Mercer",
            email="justin@example.com",
            phone="555-0101",
            is_active=True,
        )
        sarah = User(
            name="Sarah Keller",
            email="sarah@example.com",
            phone="555-0102",
            is_active=True,
        )
        mike = User(
            name="Mike Donnelly",
            email="mike@example.com",
            phone="555-0103",
            is_active=True,
        )
        team_manager = User(
            name="Avery Teamlead",
            email="avery@example.com",
            phone="555-0110",
            is_active=True,
        )
        taylor = User(
            name="Taylor Price",
            email="taylor@example.com",
            phone="555-0201",
            is_active=True,
        )
        chris = User(
            name="Chris Everett",
            email="chris@example.com",
            phone="555-0202",
            is_active=True,
        )
        summit_admin = User(
            name="Jordan Summit",
            email="jordan@example.com",
            phone="555-0210",
            is_active=True,
        )

        db.add_all(
            [
                chaffee_team,
                summit_team,
                justin,
                sarah,
                mike,
                team_manager,
                taylor,
                chris,
                summit_admin,
            ]
        )
        db.flush()

        memberships = [
            TeamMembership(
                user_id=justin.id,
                team_id=chaffee_team.id,
                roles=["responder", "dispatcher"],
                is_active=True,
                granted_at=within_one_day,
            ),
            TeamMembership(
                user_id=sarah.id,
                team_id=chaffee_team.id,
                roles=["responder"],
                is_active=True,
                granted_at=four_days_ago,
            ),
            TeamMembership(
                user_id=mike.id,
                team_id=chaffee_team.id,
                roles=["responder"],
                is_active=True,
                granted_at=four_weeks_ago,
            ),
            TeamMembership(
                user_id=team_manager.id,
                team_id=chaffee_team.id,
                roles=["team_admin"],
                is_active=True,
                granted_at=one_year_ago,
            ),
            TeamMembership(
                user_id=taylor.id,
                team_id=summit_team.id,
                roles=["responder", "dispatcher"],
                is_active=True,
                granted_at=within_one_day - timedelta(hours=2),
            ),
            TeamMembership(
                user_id=chris.id,
                team_id=summit_team.id,
                roles=["responder"],
                is_active=True,
                granted_at=four_days_ago - timedelta(hours=3),
            ),
            TeamMembership(
                user_id=summit_admin.id,
                team_id=summit_team.id,
                roles=["team_admin"],
                is_active=True,
                granted_at=one_year_ago - timedelta(days=14),
            ),
        ]

        devices = [
            Device(
                user_id=justin.id,
                platform="android",
                push_token="fcm-token-justin",
                last_seen=within_one_day,
                is_active=True,
                is_verified=True,
            ),
            Device(
                user_id=sarah.id,
                platform="ios",
                push_token="apns-token-sarah",
                last_seen=four_days_ago,
                is_active=True,
                is_verified=True,
            ),
            Device(
                user_id=mike.id,
                platform="android",
                push_token="fcm-token-mike",
                last_seen=four_weeks_ago,
                is_active=False,
                is_verified=False,
            ),
            Device(
                user_id=taylor.id,
                platform="ios",
                push_token="apns-token-taylor",
                last_seen=within_one_day - timedelta(hours=4),
                is_active=True,
                is_verified=True,
            ),
            Device(
                user_id=chris.id,
                platform="android",
                push_token="fcm-token-chris",
                last_seen=one_year_ago,
                is_active=True,
                is_verified=True,
            ),
        ]

        incidents = [
            Incident(
                title="Injured Climber Extraction",
                team="Chaffee SAR",
                location="Mt. Princeton Southwest Gully",
                notes="Subject reports lower-leg injury above treeline. Snowpack stable but wind increasing. Air asset on standby if ground extraction stalls.",
                active=True,
                created_at=within_one_day,
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
                created_at=four_days_ago,
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
                created_at=four_weeks_ago,
            ),
            DeliveryEvent(
                title="Responder acknowledged on lock screen",
                detail="Sarah K. marked Responding from the native alert screen before opening the app.",
                time_label="4m",
                icon="task_alt",
                color="#3F6D91",
                created_at=one_year_ago,
            ),
        ]

        db.add_all(memberships)
        db.add_all(devices)
        db.add_all(incidents)
        db.add_all(events)
        db.commit()


if __name__ == "__main__":
    seed()
