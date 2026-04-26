from unittest.mock import patch

import pytest
from fastapi import HTTPException
from starlette.requests import Request

from app.api.deps import Principal, _select_effective_membership, get_current_principal
from app.core.time import utc_now
from app.models.team_management import Team, TeamMembership, User


def _make_request(headers: dict[str, str] | None = None) -> Request:
    raw_headers = [
        (key.lower().encode("latin-1"), value.encode("latin-1"))
        for key, value in (headers or {}).items()
    ]
    scope = {"type": "http", "method": "GET", "path": "/", "headers": raw_headers}
    return Request(scope)


def test_missing_header_returns_401(db_session):
    with pytest.raises(HTTPException) as exc_info:
        get_current_principal(_make_request(), db_session)
    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Missing authenticated user context."


def test_unknown_email_returns_401(db_session):
    with pytest.raises(HTTPException) as exc_info:
        get_current_principal(
            _make_request({"x-missionout-user-email": "ghost@example.com"}),
            db_session,
        )
    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Authenticated user is not recognized."


def test_user_without_membership_returns_403(db_session):
    user = User(name="Solo Sam", email="solo@example.com", phone="", is_active=True)
    db_session.add(user)
    db_session.commit()

    with pytest.raises(HTTPException) as exc_info:
        get_current_principal(
            _make_request({"x-missionout-user-email": user.email}),
            db_session,
        )
    assert exc_info.value.status_code == 403


def test_returns_principal_for_valid_user(db_session, seeded_user):
    principal = get_current_principal(
        _make_request({"x-missionout-user-email": seeded_user.email}),
        db_session,
    )
    assert isinstance(principal, Principal)
    assert principal.user.id == seeded_user.id
    assert principal.role == "team_admin"


def test_email_match_is_case_insensitive(db_session, seeded_user):
    principal = get_current_principal(
        _make_request({"x-missionout-user-email": seeded_user.email.upper()}),
        db_session,
    )
    assert principal.user.id == seeded_user.id


def test_set_local_is_noop_on_sqlite(db_session, seeded_user):
    # The dependency must not emit SET LOCAL / set_config on SQLite so the
    # existing in-memory test suite can run without RLS support.
    # TODO(rls): once local dev/CI moves to Postgres, replace this with a
    # test that verifies SET LOCAL does fire and policies apply.
    with patch.object(db_session, "execute", wraps=db_session.execute) as spy:
        get_current_principal(
            _make_request({"x-missionout-user-email": seeded_user.email}),
            db_session,
        )
        rendered_calls = [
            str(call.args[0]) for call in spy.call_args_list if call.args
        ]
    assert not any("set_config" in text.lower() for text in rendered_calls)
    assert not any("set local" in text.lower() for text in rendered_calls)


def test_effective_membership_prefers_highest_privilege_role(db_session):
    user = User(name="Multi", email="multi@example.com", phone="", is_active=True)
    db_session.add(user)
    db_session.flush()

    team_a = Team(name="Alpha", is_active=True)
    team_b = Team(name="Beta", is_active=True)
    db_session.add_all([team_a, team_b])
    db_session.flush()

    responder_membership = TeamMembership(
        user_id=user.id,
        team_id=team_a.id,
        roles=["responder"],
        role="responder",
        granted_at=utc_now(),
    )
    admin_membership = TeamMembership(
        user_id=user.id,
        team_id=team_b.id,
        roles=["team_admin"],
        role="team_admin",
        granted_at=utc_now(),
    )
    db_session.add_all([responder_membership, admin_membership])
    db_session.commit()
    db_session.refresh(user)

    effective = _select_effective_membership(user)
    assert effective is not None
    assert effective.role == "team_admin"
    assert effective.team_id == team_b.id


def test_effective_membership_falls_back_for_unknown_role(db_session):
    user = User(name="Off-Roster", email="off@example.com", phone="", is_active=True)
    db_session.add(user)
    db_session.flush()

    team = Team(name="Roster Team", is_active=True)
    db_session.add(team)
    db_session.flush()

    db_session.add(
        TeamMembership(
            user_id=user.id,
            team_id=team.id,
            roles=["observer"],
            role="observer",
            granted_at=utc_now(),
        )
    )
    db_session.commit()
    db_session.refresh(user)

    # Membership exists but the role string is unknown to the precedence
    # tuple; the fallback ranks it last and still returns the membership.
    membership = _select_effective_membership(user)
    assert membership is not None
    assert membership.role == "observer"


def test_effective_membership_skips_inactive_teams(db_session):
    user = User(name="Hidden", email="hidden@example.com", phone="", is_active=True)
    db_session.add(user)
    db_session.flush()

    inactive_team = Team(name="Inactive", is_active=False)
    db_session.add(inactive_team)
    db_session.flush()

    membership = TeamMembership(
        user_id=user.id,
        team_id=inactive_team.id,
        roles=["team_admin"],
        role="team_admin",
        granted_at=utc_now(),
    )
    db_session.add(membership)
    db_session.commit()
    db_session.refresh(user)

    assert _select_effective_membership(user) is None
