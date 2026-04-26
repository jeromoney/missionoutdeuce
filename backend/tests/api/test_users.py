def test_patch_user_active_requires_header(client):
    response = client.patch("/user/active", json={"is_active": False})

    assert response.status_code == 401


def test_patch_user_active_returns_401_for_unknown_email(client):
    response = client.patch(
        "/user/active",
        json={"is_active": False},
        headers={"x-missionout-user-email": "ghost@gmail.com"},
    )

    assert response.status_code == 401


def test_patch_user_active_returns_403_for_responder_only(client, seeded_second_user):
    response = client.patch(
        "/user/active",
        json={"is_active": False},
        headers={"x-missionout-user-email": seeded_second_user.email},
    )

    assert response.status_code == 403


def test_patch_user_active_toggles_is_active(client, seeded_user, db_session):
    # Deactivation persists to the DB. After deactivation the user can no
    # longer authenticate against `/user/active`, so reactivation must happen
    # out-of-band (e.g. via a team admin flow) — verified at the DB layer here
    # instead of a second round-trip.
    first = client.patch(
        "/user/active",
        json={"is_active": False},
        headers={"x-missionout-user-email": seeded_user.email},
    )
    assert first.status_code == 200
    assert first.json() == {"public_id": seeded_user.public_id, "is_active": False}
    db_session.refresh(seeded_user)
    assert seeded_user.is_active is False

    seeded_user.is_active = True
    db_session.commit()

    second = client.patch(
        "/user/active",
        json={"is_active": False},
        headers={"x-missionout-user-email": seeded_user.email},
    )
    assert second.status_code == 200
    assert second.json()["is_active"] is False


def test_patch_user_active_matches_email_case_insensitively(client, seeded_user):
    response = client.patch(
        "/user/active",
        json={"is_active": False},
        headers={"x-missionout-user-email": seeded_user.email.upper()},
    )

    assert response.status_code == 200
    assert response.json()["public_id"] == seeded_user.public_id
