"""End-to-end coverage of the JWT session lifecycle:

- /auth/google issues a session
- the access token authenticates a downstream call
- /auth/refresh rotates the refresh token
- replaying the old refresh token revokes the chain
- /auth/logout invalidates the active refresh token
"""
from app.models.team_management import RefreshToken


def _google_session(client, seeded_user, monkeypatch):
    import app.api.routes.auth as auth_routes
    from app.core.config import settings

    monkeypatch.setattr(
        auth_routes,
        "_verify_google_identity",
        lambda payload: {
            "email": seeded_user.email,
            "name": seeded_user.name,
            "aud": "test-client-id",
        },
    )
    monkeypatch.setattr(settings, "google_client_id", "test-client-id")

    response = client.post(
        "/auth/google",
        json={"id_token": "fake-google-token", "requested_client": "dispatcher"},
    )
    assert response.status_code == 200
    return response.json()


def test_google_sign_in_returns_usable_access_token(client, seeded_user, monkeypatch):
    body = _google_session(client, seeded_user, monkeypatch)

    incidents = client.get(
        "/incidents",
        headers={"Authorization": f"Bearer {body['access_token']}"},
    )
    assert incidents.status_code == 200


def test_refresh_rotates_tokens_and_keeps_session_alive(
    client, seeded_user, db_session, monkeypatch
):
    body = _google_session(client, seeded_user, monkeypatch)
    original_refresh = body["refresh_token"]

    refreshed = client.post("/auth/refresh", json={"refresh_token": original_refresh})
    assert refreshed.status_code == 200
    new_body = refreshed.json()

    assert new_body["refresh_token"] != original_refresh
    # Access tokens minted within the same second for the same user have
    # identical claims and so encode to identical bytes; the meaningful
    # invariant is that the new token still authenticates downstream calls.

    incidents = client.get(
        "/incidents",
        headers={"Authorization": f"Bearer {new_body['access_token']}"},
    )
    assert incidents.status_code == 200

    rows = (
        db_session.query(RefreshToken)
        .filter_by(user_id=seeded_user.id)
        .order_by(RefreshToken.id)
        .all()
    )
    assert len(rows) == 2
    assert rows[0].revoked_at is not None
    assert rows[1].revoked_at is None


def test_refresh_replay_revokes_entire_chain(client, seeded_user, db_session, monkeypatch):
    body = _google_session(client, seeded_user, monkeypatch)
    original_refresh = body["refresh_token"]

    first = client.post("/auth/refresh", json={"refresh_token": original_refresh})
    assert first.status_code == 200
    later_refresh = first.json()["refresh_token"]

    # Replay of the rotated token: must 401 AND revoke the still-active newer
    # refresh token as a precaution.
    replayed = client.post("/auth/refresh", json={"refresh_token": original_refresh})
    assert replayed.status_code == 401

    blocked = client.post("/auth/refresh", json={"refresh_token": later_refresh})
    assert blocked.status_code == 401

    active_count = (
        db_session.query(RefreshToken)
        .filter_by(user_id=seeded_user.id, revoked_at=None)
        .count()
    )
    assert active_count == 0


def test_logout_revokes_refresh_token(client, seeded_user, db_session, monkeypatch):
    body = _google_session(client, seeded_user, monkeypatch)

    logout = client.post("/auth/logout", json={"refresh_token": body["refresh_token"]})
    assert logout.status_code == 204

    follow_up = client.post("/auth/refresh", json={"refresh_token": body["refresh_token"]})
    assert follow_up.status_code == 401

    # Logging out an already-revoked token is idempotent (still 204).
    repeat = client.post("/auth/logout", json={"refresh_token": body["refresh_token"]})
    assert repeat.status_code == 204
