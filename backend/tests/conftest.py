from collections.abc import Generator
from datetime import datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.time import utc_now
from app.db.base import Base
from app.db.session import get_db
from app.main import app
from app.models.incident import Incident, ResponseRecord
from app.models.team_management import Team, TeamMembership, User


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
        is_active=True,
        granted_at=utc_now(),
        revoked_at=None,
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
