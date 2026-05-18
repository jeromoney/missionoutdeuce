"""Tests for GET /users/me."""


def test_get_me_returns_provisioned_user(client, seeded_user, seeded_team, auth_headers):
    response = client.get("/users/me", headers=auth_headers(seeded_user))

    assert response.status_code == 200
    body = response.json()
    assert body["public_id"] == seeded_user.public_id
    assert body["email"] == seeded_user.email
    assert body["name"] == seeded_user.name
    assert len(body["team_memberships"]) == 1
    assert body["team_memberships"][0]["team_name"] == seeded_team.name
    assert body["team_memberships"][0]["team_public_id"] == seeded_team.public_id


def test_get_me_returns_empty_memberships_for_unprovisioned_user(
    client, firebase_registry
):
    firebase_registry["new-user-token"] = {
        "email": "newbie@example.com",
        "name": "New User",
    }
    response = client.get(
        "/users/me", headers={"Authorization": "Bearer new-user-token"}
    )

    assert response.status_code == 200
    body = response.json()
    assert body["public_id"] == ""
    assert body["email"] == "newbie@example.com"
    assert body["name"] == "New User"
    assert body["team_memberships"] == []


def test_get_me_requires_valid_firebase_token(client):
    response = client.get(
        "/users/me", headers={"Authorization": "Bearer invalid-firebase-token"}
    )
    assert response.status_code == 401


def test_get_me_requires_authorization_header(client):
    response = client.get("/users/me")
    assert response.status_code == 401


def test_get_me_with_valid_team_id_header(client, seeded_user, seeded_team, auth_headers):
    response = client.get(
        "/users/me",
        headers={
            **auth_headers(seeded_user),
            "X-Team-Id": seeded_team.public_id,
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["public_id"] == seeded_user.public_id


def test_get_me_rejects_invalid_team_id_header(client, seeded_user, auth_headers):
    response = client.get(
        "/users/me",
        headers={
            **auth_headers(seeded_user),
            "X-Team-Id": "nonexistent-team-id",
        },
    )
    assert response.status_code == 403
    assert "X-Team-Id" in response.json()["detail"]


def test_get_me_initials_from_two_word_name(client, firebase_registry):
    firebase_registry["initials-token"] = {
        "email": "jane.doe@example.com",
        "name": "Jane Doe",
    }
    response = client.get(
        "/users/me", headers={"Authorization": "Bearer initials-token"}
    )
    assert response.status_code == 200
    assert response.json()["initials"] == "JD"


def test_get_me_only_returns_active_memberships(
    client, db_session, seeded_user, seeded_team, auth_headers
):
    from app.models.team_management import Team, TeamMembership
    from app.core.time import utc_now

    inactive_team = Team(name="Disbanded Crew", is_active=False)
    db_session.add(inactive_team)
    db_session.flush()
    db_session.add(
        TeamMembership(
            user_id=seeded_user.id,
            team_id=inactive_team.id,
            roles=["responder"],
            role="responder",
            granted_at=utc_now(),
        )
    )
    db_session.commit()

    response = client.get("/users/me", headers=auth_headers(seeded_user))
    assert response.status_code == 200
    memberships = response.json()["team_memberships"]
    team_names = [m["team_name"] for m in memberships]
    assert seeded_team.name in team_names
    assert "Disbanded Crew" not in team_names
