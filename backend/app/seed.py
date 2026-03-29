from datetime import datetime, timedelta

from sqlalchemy import delete, text

from app.db.base import Base
from app.db.bootstrap import ensure_incident_team_fk
from app.db.session import SessionLocal
from app.models.event import DeliveryEvent
from app.models.incident import Incident, ResponseRecord
from app.models.team_management import Device, Team, TeamMembership, User
from app.db.session import engine


def seed() -> None:
    Base.metadata.create_all(bind=engine)
    ensure_incident_team_fk(engine)

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

        quiet_team = Team(name="North Rim SAR", is_active=True)
        one_team = Team(name="Cinder Valley Rescue", is_active=True)
        many_team = Team(name="Pine Ridge Search", is_active=True)

        zero_user = User(
            name="Zane Ortega",
            email="zero@gmail.com",
            phone="555-1000",
            is_active=True,
        )
        one_user = User(
            name="Nora Ellison",
            email="one@gmail.com",
            phone="555-1001",
            is_active=True,
        )
        many_user = User(
            name="Miles Avery",
            email="many@gmail.com",
            phone="555-1002",
            is_active=True,
        )

        db.add_all(
            [
                quiet_team,
                one_team,
                many_team,
                zero_user,
                one_user,
                many_user,
            ]
        )
        db.flush()

        memberships = [
            TeamMembership(
                user_id=zero_user.id,
                team_id=quiet_team.id,
                roles=["responder", "dispatcher", "team_admin"],
                is_active=True,
                granted_at=within_one_day,
            ),
            TeamMembership(
                user_id=one_user.id,
                team_id=one_team.id,
                roles=["responder", "dispatcher", "team_admin"],
                is_active=True,
                granted_at=four_days_ago,
            ),
            TeamMembership(
                user_id=many_user.id,
                team_id=many_team.id,
                roles=["responder", "dispatcher", "team_admin"],
                is_active=True,
                granted_at=one_year_ago,
            ),
        ]

        devices = [
            Device(
                user_id=zero_user.id,
                platform="android",
                push_token="fcm-token-zero",
                last_seen=within_one_day,
                is_active=True,
                is_verified=True,
            ),
            Device(
                user_id=one_user.id,
                platform="ios",
                push_token="apns-token-one",
                last_seen=four_days_ago,
                is_active=True,
                is_verified=True,
            ),
            Device(
                user_id=many_user.id,
                platform="android",
                push_token="fcm-token-many",
                last_seen=within_one_day - timedelta(hours=3),
                is_active=True,
                is_verified=True,
            ),
        ]

        incidents = [
            Incident(
                title="Winter Trailhead Welfare Check",
                legacy_team_name=quiet_team.name,
                team_id=quiet_team.id,
                location="Echo Basin Upper Lot",
                notes="Historical training incident retained for audit and timeline testing. No operational activity in the last 7 days for this team.",
                active=False,
                created_at=four_weeks_ago,
                responses=[
                    ResponseRecord(
                        name="Zane O.",
                        status="Not Available",
                        detail="Archived training call used for seeded test history.",
                        rank=0,
                    ),
                ],
            ),
            Incident(
                title="Lost Day Hiker",
                legacy_team_name=one_team.name,
                team_id=one_team.id,
                location="Cinder Valley South Fork",
                notes="Single recent mission for the one@gmail.com account. Team should show exactly one incident within the last 7 days.",
                active=True,
                created_at=within_one_day,
                responses=[
                    ResponseRecord(
                        name="Nora E.",
                        status="Responding",
                        detail="Confirmed availability and is heading to the trailhead.",
                        rank=0,
                    ),
                ],
            ),
            Incident(
                title="Overdue Climber",
                legacy_team_name=many_team.name,
                team_id=many_team.id,
                location="Pine Ridge North Face",
                notes="Recent mission one of several for many@gmail.com.",
                active=True,
                created_at=within_one_day - timedelta(hours=2),
                responses=[
                    ResponseRecord(
                        name="Miles A.",
                        status="Responding",
                        detail="Departed staging area with technical gear cache.",
                        rank=0,
                    ),
                ],
            ),
            Incident(
                title="Riverbank Evidence Search",
                legacy_team_name=many_team.name,
                team_id=many_team.id,
                location="Pine Ridge Lower Narrows",
                notes="Recent mission two of several for many@gmail.com.",
                active=True,
                created_at=four_days_ago,
                responses=[
                    ResponseRecord(
                        name="Miles A.",
                        status="Responding",
                        detail="Assigned to grid sector Bravo for sweep coverage.",
                        rank=0,
                    ),
                ],
            ),
            Incident(
                title="Storm Shelter Evacuation",
                legacy_team_name=many_team.name,
                team_id=many_team.id,
                location="Pine Ridge High Meadow",
                notes="Recent mission three of several for many@gmail.com, still within the last 7 days.",
                active=False,
                created_at=now - timedelta(days=6),
                responses=[
                    ResponseRecord(
                        name="Miles A.",
                        status="Responding",
                        detail="Handled evacuation transport coordination before stand-down.",
                        rank=0,
                    ),
                ],
            ),
        ]

        events = [
            DeliveryEvent(
                title="Single-team dispatch acknowledged",
                detail="Nora Ellison acknowledged the Lost Day Hiker alert from Cinder Valley Rescue.",
                time_label="2m",
                icon="notifications",
                color="#4F6F95",
                created_at=within_one_day,
            ),
            DeliveryEvent(
                title="Multi-mission team burst delivered",
                detail="Pine Ridge Search received another recent alert, keeping many@gmail.com in a high-activity test state.",
                time_label="4m",
                icon="task_alt",
                color="#3F6D91",
                created_at=four_days_ago,
            ),
        ]

        db.add_all(memberships)
        db.add_all(devices)
        db.add_all(incidents)
        db.add_all(events)
        db.commit()


if __name__ == "__main__":
    seed()
