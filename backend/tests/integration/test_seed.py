"""Smoke test for the three-team seed.

Runs `seed_into` against the SQLite test session and pins the headline
invariants: team count, sizes, admin identity, role distribution, device
coverage, and scalar `role` field population.
"""
from collections import Counter

from sqlalchemy import select

from app.models.team_management import Device, Team, TeamMembership, User
from app.seed import TEAM_SPECS, seed_into


def test_seed_creates_three_teams_with_expected_sizes(db_session):
    seed_into(db_session)

    teams = db_session.scalars(select(Team).order_by(Team.id)).all()
    assert [t.name for t in teams] == [s.name for s in TEAM_SPECS]
    assert [s.size for s in TEAM_SPECS] == [65, 40, 89]

    for team, spec in zip(teams, TEAM_SPECS, strict=True):
        member_count = db_session.scalar(
            select(TeamMembership)
            .where(TeamMembership.team_id == team.id)
            .with_only_columns(TeamMembership.id)
            .limit(None)
        )
        # Use a fresh count query — the limit(None) trick above just exercises
        # the join path; the real assertion uses func.count below.
        from sqlalchemy import func

        count = db_session.scalar(
            select(func.count(TeamMembership.id)).where(TeamMembership.team_id == team.id)
        )
        assert count == spec.size, f"{team.name} should have {spec.size} members, got {count}"


def test_seed_assigns_justin_as_team_one_admin(db_session):
    seed_into(db_session)

    team_one = db_session.scalar(
        select(Team).where(Team.name == TEAM_SPECS[0].name)
    )
    admin_membership = db_session.scalar(
        select(TeamMembership)
        .where(
            TeamMembership.team_id == team_one.id,
            TeamMembership.role == "team_admin",
        )
    )
    assert admin_membership is not None
    assert admin_membership.user.email == "justin.matis@gmail.com"
    assert "team_admin" in admin_membership.roles
    assert "dispatcher" in admin_membership.roles
    assert "responder" in admin_membership.roles


def test_seed_role_distribution_matches_ratio(db_session):
    seed_into(db_session)

    for spec in TEAM_SPECS:
        team = db_session.scalar(select(Team).where(Team.name == spec.name))
        memberships = db_session.scalars(
            select(TeamMembership).where(TeamMembership.team_id == team.id)
        ).all()
        roles = Counter(m.role for m in memberships)
        assert roles["team_admin"] == 1, f"{spec.name} must have exactly one admin"
        expected_dispatchers = round(spec.size * 0.10)
        assert roles["dispatcher"] == expected_dispatchers, (
            f"{spec.name} expected {expected_dispatchers} dispatchers, got {roles['dispatcher']}"
        )
        assert roles["responder"] == spec.size - 1 - expected_dispatchers


def test_seed_every_membership_has_scalar_role(db_session):
    seed_into(db_session)

    missing_role = db_session.scalars(
        select(TeamMembership).where(TeamMembership.role.is_(None))
    ).all()
    assert missing_role == []


def test_seed_majority_of_members_have_at_least_one_device(db_session):
    seed_into(db_session)

    total_members = db_session.scalar(
        select(__import__("sqlalchemy").func.count(TeamMembership.id))
    )
    members_with_device = db_session.scalar(
        select(__import__("sqlalchemy").func.count(User.id.distinct()))
        .select_from(User)
        .join(Device, Device.user_id == User.id)
    )
    coverage = members_with_device / total_members
    # Weights are {0:.10, 1:.75, 2:.15} → ~90% of members have ≥1 device.
    # Allow some slack for RNG-driven variance, but coverage must stay high.
    assert coverage >= 0.80, f"Device coverage too low: {coverage:.2f}"


def test_seed_is_idempotent_on_rerun(db_session):
    from sqlalchemy import func

    seed_into(db_session)
    first_user_count = db_session.scalar(select(func.count(User.id)))
    first_device_count = db_session.scalar(select(func.count(Device.id)))

    seed_into(db_session)
    second_user_count = db_session.scalar(select(func.count(User.id)))
    second_device_count = db_session.scalar(select(func.count(Device.id)))

    assert first_user_count == second_user_count
    assert first_device_count == second_device_count
