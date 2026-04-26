from datetime import timedelta

from app.core.time import utc_now
from app.models.team_management import Device, TeamMembership, User


def test_list_team_members_returns_404_for_unknown_team(client, seeded_user):
    response = client.get(
        "/teams/missing-team/members",
        headers={"x-missionout-user-email": seeded_user.email},
    )

    assert response.status_code == 404


def test_list_team_members_returns_seeded_membership(client, seeded_team, seeded_user):
    response = client.get(
        f"/teams/{seeded_team.public_id}/members",
        headers={"x-missionout-user-email": seeded_user.email},
    )

    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["email"] == seeded_user.email
    assert body[0]["team_public_id"] == seeded_team.public_id
    assert body[0]["user_public_id"] == seeded_user.public_id
    assert set(body[0]["roles"]) == {"responder", "dispatcher", "team_admin"}
    assert body[0]["is_active"] is True


def test_create_team_member_creates_user_and_membership(client, seeded_team, seeded_user, db_session):
    response = client.post(
        f"/teams/{seeded_team.public_id}/members",
        headers={"x-missionout-user-email": seeded_user.email},
        json={
            "name": "River Chen",
            "email": "river@gmail.com",
            "phone": "555-7777",
            "roles": ["responder"],
            "is_active": True,
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["email"] == "river@gmail.com"
    assert body["roles"] == ["responder"]

    user = db_session.query(User).filter_by(email="river@gmail.com").one()
    membership = db_session.query(TeamMembership).filter_by(user_id=user.id).one()
    assert membership.team_id == seeded_team.id


def test_create_team_member_reuses_existing_user_for_new_team(
    client, seeded_user, seeded_second_team, seeded_second_admin, db_session
):
    response = client.post(
        f"/teams/{seeded_second_team.public_id}/members",
        headers={"x-missionout-user-email": seeded_second_admin.email},
        json={
            "name": seeded_user.name,
            "email": seeded_user.email,
            "phone": seeded_user.phone,
            "roles": ["team_admin"],
            "is_active": True,
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["user_public_id"] == seeded_user.public_id
    assert body["team_public_id"] == seeded_second_team.public_id
    assert db_session.query(User).filter_by(email=seeded_user.email).count() == 1


def test_create_team_member_rejects_duplicate_membership(client, seeded_team, seeded_user):
    response = client.post(
        f"/teams/{seeded_team.public_id}/members",
        headers={"x-missionout-user-email": seeded_user.email},
        json={
            "name": seeded_user.name,
            "email": seeded_user.email,
            "phone": seeded_user.phone,
            "roles": ["responder"],
            "is_active": True,
        },
    )

    assert response.status_code == 409


def test_create_team_member_returns_404_for_unknown_team(client, seeded_user):
    response = client.post(
        "/teams/does-not-exist/members",
        headers={"x-missionout-user-email": seeded_user.email},
        json={
            "name": "Ghost",
            "email": "ghost@gmail.com",
            "phone": "",
            "roles": ["responder"],
            "is_active": True,
        },
    )

    assert response.status_code == 404


def test_update_team_member_updates_roles_only(client, seeded_team, seeded_user, db_session):
    membership = (
        db_session.query(TeamMembership)
        .filter_by(user_id=seeded_user.id, team_id=seeded_team.id)
        .one()
    )

    response = client.patch(
        f"/teams/{seeded_team.public_id}/members/{membership.public_id}",
        headers={"x-missionout-user-email": seeded_user.email},
        json={"roles": ["responder"]},
    )

    assert response.status_code == 200
    assert response.json()["roles"] == ["responder"]
    db_session.refresh(seeded_user)
    assert seeded_user.is_active is True


def test_update_team_member_updates_is_active_only(client, seeded_team, seeded_user, db_session):
    membership = (
        db_session.query(TeamMembership)
        .filter_by(user_id=seeded_user.id, team_id=seeded_team.id)
        .one()
    )

    response = client.patch(
        f"/teams/{seeded_team.public_id}/members/{membership.public_id}",
        headers={"x-missionout-user-email": seeded_user.email},
        json={"is_active": False},
    )

    assert response.status_code == 200
    assert response.json()["is_active"] is False
    db_session.refresh(seeded_user)
    assert seeded_user.is_active is False


def test_update_team_member_returns_404_for_unknown_membership(client, seeded_team, seeded_user):
    response = client.patch(
        f"/teams/{seeded_team.public_id}/members/not-a-real-id",
        headers={"x-missionout-user-email": seeded_user.email},
        json={"is_active": True},
    )

    assert response.status_code == 404


def test_update_team_member_rejects_membership_on_other_team(
    client, seeded_team, seeded_second_team, seeded_user, seeded_second_admin, db_session
):
    membership = (
        db_session.query(TeamMembership)
        .filter_by(user_id=seeded_user.id, team_id=seeded_team.id)
        .one()
    )

    response = client.patch(
        f"/teams/{seeded_second_team.public_id}/members/{membership.public_id}",
        headers={"x-missionout-user-email": seeded_second_admin.email},
        json={"is_active": False},
    )

    assert response.status_code == 404


def test_delete_team_member_removes_membership(client, seeded_team, seeded_user, db_session):
    membership = (
        db_session.query(TeamMembership)
        .filter_by(user_id=seeded_user.id, team_id=seeded_team.id)
        .one()
    )

    response = client.delete(
        f"/teams/{seeded_team.public_id}/members/{membership.public_id}",
        headers={"x-missionout-user-email": seeded_user.email},
    )

    assert response.status_code == 204
    assert (
        db_session.query(TeamMembership).filter_by(public_id=membership.public_id).count() == 0
    )


def test_delete_team_member_returns_404_for_unknown_membership(client, seeded_team, seeded_user):
    response = client.delete(
        f"/teams/{seeded_team.public_id}/members/unknown-membership",
        headers={"x-missionout-user-email": seeded_user.email},
    )

    assert response.status_code == 404


def test_list_team_devices_empty(client, seeded_team, seeded_user):
    response = client.get(
        f"/teams/{seeded_team.public_id}/devices",
        headers={"x-missionout-user-email": seeded_user.email},
    )

    assert response.status_code == 200
    assert response.json() == []


def test_list_team_devices_orders_by_last_seen_desc(client, seeded_team, seeded_user, db_session):
    now = utc_now()
    older = Device(
        user_id=seeded_user.id,
        platform="ios",
        push_token="older-token",
        last_seen=now - timedelta(hours=1),
        is_active=True,
        is_verified=True,
    )
    newer = Device(
        user_id=seeded_user.id,
        platform="android",
        push_token="newer-token",
        last_seen=now,
        is_active=True,
        is_verified=True,
    )
    db_session.add_all([older, newer])
    db_session.commit()

    response = client.get(
        f"/teams/{seeded_team.public_id}/devices",
        headers={"x-missionout-user-email": seeded_user.email},
    )

    assert response.status_code == 200
    body = response.json()
    assert [device["push_token"] for device in body] == ["newer-token", "older-token"]
    assert body[0]["user_public_id"] == seeded_user.public_id
    assert body[0]["user_name"] == seeded_user.name
