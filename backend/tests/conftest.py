import json
from collections.abc import Callable, Generator
from datetime import timedelta
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import settings
from app.core.security import create_access_token
from app.core.time import utc_now
from app.db.base import Base
from app.db.session import get_db
from app.main import app
from app.models.event import DeliveryEvent
from app.models.incident import Incident, ResponseRecord
from app.models.team_management import (
    Device,
    Team,
    TeamMembership,
    User,
    WebPushSubscription,
)


# Tests run without the production secrets file. Inject a deterministic
# signing key so JWT mint+verify works end-to-end in the suite.
if not settings.jwt_signing_key:
    settings.jwt_signing_key = "d88ea38654a8c1db42e26530aec41989024a30137b4502824c165170e4ccfbd3"


TEST_DATABASE_URL = "sqlite+pysqlite:///:memory:"

engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture()
def db_session(monkeypatch: pytest.MonkeyPatch) -> Generator[Session, None, None]:
    import app.api.routes.health as health_routes
    import app.main as main_module

    monkeypatch.setattr(main_module, "engine", engine)
    monkeypatch.setattr(health_routes, "engine", engine)

    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def client(db_session: Session) -> Generator[TestClient, None, None]:
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture()
def seeded_team(db_session: Session) -> Team:
    team = Team(name="Cinder Valley Rescue", is_active=True)
    db_session.add(team)
    db_session.commit()
    db_session.refresh(team)
    return team


@pytest.fixture()
def seeded_user(db_session: Session, seeded_team: Team) -> User:
    user = User(
        name="Nora Ellison",
        email="one@gmail.com",
        phone="555-1001",
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()

    membership = TeamMembership(
        user_id=user.id,
        team_id=seeded_team.id,
        roles=["responder", "dispatcher", "team_admin"],
        role="team_admin",
        granted_at=utc_now(),
    )
    db_session.add(membership)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture()
def seeded_incident(db_session: Session, seeded_team: Team, seeded_user: User) -> Incident:
    incident = Incident(
        title="Lost Day Hiker",
        team_id=seeded_team.id,
        location="Cinder Valley South Fork",
        notes="Subject overdue from day hike.",
        active=True,
        created_at=utc_now(),
        responses=[
            ResponseRecord(
                user_id=seeded_user.id,
                status="Responding",
                source="seed",
                rank=0,
            )
        ],
    )
    db_session.add(incident)
    db_session.commit()
    db_session.refresh(incident)
    return incident


@pytest.fixture()
def seeded_second_team(db_session: Session) -> Team:
    team = Team(name="Pine Ridge Search", is_active=True)
    db_session.add(team)
    db_session.commit()
    db_session.refresh(team)
    return team


@pytest.fixture()
def seeded_second_user(db_session: Session, seeded_second_team: Team) -> User:
    user = User(
        name="Mateo Alvarez",
        email="two@gmail.com",
        phone="555-2002",
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()

    membership = TeamMembership(
        user_id=user.id,
        team_id=seeded_second_team.id,
        roles=["responder"],
        role="responder",
        granted_at=utc_now(),
    )
    db_session.add(membership)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture()
def seeded_second_admin(db_session: Session, seeded_second_team: Team) -> User:
    user = User(
        name="Quentin Vega",
        email="admin2@gmail.com",
        phone="555-3003",
        is_active=True,
    )
    db_session.add(user)
    db_session.flush()

    membership = TeamMembership(
        user_id=user.id,
        team_id=seeded_second_team.id,
        roles=["team_admin"],
        role="team_admin",
        granted_at=utc_now(),
    )
    db_session.add(membership)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture()
def seeded_device(db_session: Session, seeded_user: User) -> Device:
    device = Device(
        user_id=seeded_user.id,
        platform="ios",
        push_token="test-ios-token",
        last_seen=utc_now(),
        is_active=True,
        is_verified=True,
    )
    db_session.add(device)
    db_session.commit()
    db_session.refresh(device)
    return device


@pytest.fixture()
def seeded_web_push_subscription(
    db_session: Session,
    seeded_user: User,
    seeded_team: Team,
) -> WebPushSubscription:
    subscription = WebPushSubscription(
        user_id=seeded_user.id,
        team_id=seeded_team.id,
        endpoint="https://push.example.com/seeded",
        p256dh="seed-p256dh",
        auth="seed-auth",
        user_agent="pytest/seed",
        client="dispatcher",
        last_seen=utc_now(),
        is_active=True,
    )
    db_session.add(subscription)
    db_session.commit()
    db_session.refresh(subscription)
    return subscription


@pytest.fixture()
def seeded_delivery_event(db_session: Session) -> DeliveryEvent:
    event = DeliveryEvent(
        title="Dispatch acknowledged",
        detail="Nora Ellison acknowledged the Lost Day Hiker alert.",
        time_label="2m",
        icon="notifications",
        color="#4F6F95",
        created_at=utc_now() - timedelta(minutes=2),
    )
    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)
    return event


@pytest.fixture()
def auth_headers() -> Callable[[User], dict[str, str]]:
    def _build(user: User) -> dict[str, str]:
        token, _ = create_access_token(user)
        return {"Authorization": f"Bearer {token}"}

    return _build


@pytest.fixture(scope="session")
def openapi_spec() -> dict:
    spec_path = (
        Path(__file__).resolve().parents[2] / "contracts" / "openapi.json"
    )
    with spec_path.open("r", encoding="utf-8") as handle:
        return json.load(handle)
