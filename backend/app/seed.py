"""Replace the database with three realistic SAR teams.

Run:
    python -m app.seed

Produces three teams sized 65 / 40 / 89, each with one team_admin, ~10%
dispatchers, and the rest pure responders. `justin.matis@gmail.com` is hard-
wired as the admin of the first team. Members get 0-2 active devices with
weights 10/75/15 to keep push fanout realistic. The RNG is seeded so reruns
produce byte-identical rows.

Splitting `seed()` from `seed_into(db)` lets the test suite call the data-
generation half against the SQLite test session without touching the global
engine.
"""
from __future__ import annotations

import random
from dataclasses import dataclass
from datetime import timedelta

from sqlalchemy import delete, text
from sqlalchemy.orm import Session

from app.core.time import utc_now
from app.db.base import Base
from app.db.bootstrap import (
    ensure_incident_team_fk,
    ensure_incident_version,
    ensure_public_ids,
    ensure_response_record_fields,
    ensure_team_membership_role,
)
from app.db.session import SessionLocal, engine
from app.models.event import DeliveryEvent
from app.models.incident import Incident, ResponseRecord
from app.models.incident_event import IncidentEvent
from app.models.push_delivery import PushDelivery
from app.models.team_management import (
    Device,
    EmailCodeToken,
    Team,
    TeamMembership,
    User,
    WebPushSubscription,
)


# --- Team layout -----------------------------------------------------------

@dataclass(frozen=True)
class TeamSpec:
    name: str
    size: int
    admin_email: str | None
    admin_name: str | None
    admin_phone: str | None


TEAM_SPECS: list[TeamSpec] = [
    TeamSpec(
        name="Cinder Valley Rescue",
        size=65,
        admin_email="justin.matis@gmail.com",
        admin_name="Justin Matis",
        admin_phone="+15551234567",
    ),
    TeamSpec(name="Pine Ridge Search", size=40, admin_email=None, admin_name=None, admin_phone=None),
    TeamSpec(name="North Rim SAR",    size=89, admin_email=None, admin_name=None, admin_phone=None),
]


# --- Name pool -------------------------------------------------------------

FIRST_NAMES = [
    "Avery", "Blake", "Casey", "Dakota", "Elliot", "Finley", "Gray", "Harper",
    "Indigo", "Jules", "Kai", "Logan", "Morgan", "Nico", "Oakley", "Parker",
    "Quinn", "River", "Sage", "Tatum", "Umber", "Vesper", "Wren", "Xen",
    "Yael", "Zane", "Aria", "Beck", "Cleo", "Devin", "Ellis", "Frey",
    "Gale", "Hollis", "Iris", "Joss", "Kendall", "Lane", "Marlowe", "Niko",
    "Oren", "Paz", "Reese", "Sloane", "Tegan", "Vale", "Wynn", "Yara",
    "Zion", "Adair",
]
LAST_NAMES = [
    "Adler", "Brooks", "Chen", "Diaz", "Ellis", "Fischer", "Garza", "Holm",
    "Iqbal", "Jansen", "Kowal", "Lerner", "Mendez", "Nakamura", "Olsen",
    "Pak", "Quill", "Rivera", "Sato", "Tate", "Underwood", "Vega", "Walsh",
    "Xu", "Yates", "Zhang", "Bergmann", "Coppola", "Demir", "Espinoza",
    "Fontaine", "Greer", "Halpern", "Ishida", "Jaffe", "Khan", "Lindgren",
    "Moss", "Navarro", "Oduya", "Pereira", "Raines", "Sundberg", "Thiel",
    "Ueno", "Vanderberg", "Wexler", "Yoshida", "Zaragoza", "Burke",
]

PLATFORMS = ("android", "ios", "web")
PLATFORM_WEIGHTS = (0.50, 0.40, 0.10)
DEVICE_COUNT_CHOICES = (0, 1, 2)
DEVICE_COUNT_WEIGHTS = (0.10, 0.75, 0.15)


# --- Wipe ------------------------------------------------------------------

def _wipe(db: Session) -> None:
    """Empty the rows that the seed will repopulate, in FK-safe order."""
    if db.bind is not None and db.bind.dialect.name == "postgresql":
        db.execute(
            text(
                "TRUNCATE TABLE "
                "push_deliveries, incident_events, "
                "web_push_subscriptions, devices, responses, incidents, "
                "delivery_events, email_code_tokens, "
                "team_memberships, users, teams "
                "RESTART IDENTITY CASCADE"
            )
        )
        return

    # SQLite (and any other dialect): delete child tables before parents.
    for model in (
        PushDelivery,
        IncidentEvent,
        WebPushSubscription,
        Device,
        ResponseRecord,
        Incident,
        DeliveryEvent,
        EmailCodeToken,
        TeamMembership,
        User,
        Team,
    ):
        db.execute(delete(model))


# --- Public seeding API ----------------------------------------------------

def seed_into(db: Session, *, rng_seed: int = 42) -> None:
    """Replace the database contents with the three SAR teams.

    The caller owns the transaction — this function only flushes. `seed()`
    commits; the integration test asserts before the fixture tears down.
    """
    rng = random.Random(rng_seed)
    now = utc_now()
    granted_at = now - timedelta(days=14)

    _wipe(db)
    db.flush()

    global_index = 0  # ensures unique generated emails + phone numbers

    for spec in TEAM_SPECS:
        team = Team(name=spec.name, is_active=True)
        db.add(team)
        db.flush()

        dispatcher_count = round(spec.size * 0.10)
        responder_count = spec.size - 1 - dispatcher_count
        assert responder_count >= 0, "Team is too small for one admin + dispatchers"

        # Admin
        if spec.admin_email is not None:
            admin = User(
                name=spec.admin_name or "Team Admin",
                email=spec.admin_email,
                phone=spec.admin_phone or "",
                is_active=True,
            )
        else:
            global_index += 1
            admin = _make_user(rng, global_index)
        db.add(admin)
        db.flush()
        db.add(
            TeamMembership(
                user_id=admin.id,
                team_id=team.id,
                roles=["responder", "dispatcher", "team_admin"],
                role="team_admin",
                granted_at=granted_at,
            )
        )

        # Dispatchers
        for _ in range(dispatcher_count):
            global_index += 1
            user = _make_user(rng, global_index)
            db.add(user)
            db.flush()
            db.add(
                TeamMembership(
                    user_id=user.id,
                    team_id=team.id,
                    roles=["responder", "dispatcher"],
                    role="dispatcher",
                    granted_at=granted_at,
                )
            )

        # Responders
        for _ in range(responder_count):
            global_index += 1
            user = _make_user(rng, global_index)
            db.add(user)
            db.flush()
            db.add(
                TeamMembership(
                    user_id=user.id,
                    team_id=team.id,
                    roles=["responder"],
                    role="responder",
                    granted_at=granted_at,
                )
            )

        # Devices for every member of this team — query the membership rows
        # we just created so we don't have to track the user list ourselves.
        team_user_ids = [
            uid for (uid,) in db.execute(
                text("SELECT user_id FROM team_memberships WHERE team_id = :tid"),
                {"tid": team.id},
            ).all()
        ]
        for user_id in team_user_ids:
            count = rng.choices(DEVICE_COUNT_CHOICES, weights=DEVICE_COUNT_WEIGHTS, k=1)[0]
            for _ in range(count):
                platform = rng.choices(PLATFORMS, weights=PLATFORM_WEIGHTS, k=1)[0]
                db.add(
                    Device(
                        user_id=user_id,
                        platform=platform,
                        push_token=f"seed-{platform}-{user_id}-{rng.randrange(10**9):09d}",
                        last_seen=now - timedelta(hours=rng.randrange(0, 72)),
                        is_active=True,
                        is_verified=True,
                    )
                )
        db.flush()


def _make_user(rng: random.Random, global_index: int) -> User:
    first = rng.choice(FIRST_NAMES)
    last = rng.choice(LAST_NAMES)
    return User(
        name=f"{first} {last}",
        email=f"{first.lower()}.{last.lower()}.{global_index}@example.test",
        phone=f"+1555{global_index:07d}",
        is_active=True,
    )


def seed() -> None:
    Base.metadata.create_all(bind=engine)
    ensure_incident_team_fk(engine)
    ensure_public_ids(engine)
    ensure_response_record_fields(engine)
    ensure_incident_version(engine)
    ensure_team_membership_role(engine)

    with SessionLocal() as db:
        seed_into(db)
        db.commit()


if __name__ == "__main__":
    seed()
