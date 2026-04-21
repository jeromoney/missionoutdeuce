from app.models.team_management import WebPushSubscription


def _subscription_payload(endpoint: str = "https://push.example.com/abc", **overrides) -> dict:
    payload = {
        "endpoint": endpoint,
        "keys": {"p256dh": "test-p256dh", "auth": "test-auth"},
        "user_agent": "pytest/1.0",
        "client": "dispatcher",
    }
    payload.update(overrides)
    return payload


def test_get_web_push_public_key_returns_configured_values(client, monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "web_push_public_key", "test-public-key")
    monkeypatch.setattr(settings, "web_push_subject", "mailto:ops@example.com")

    response = client.get("/devices/web-push/public-key")

    assert response.status_code == 200
    body = response.json()
    assert body["public_key"] == "test-public-key"
    assert body["subject"] == "mailto:ops@example.com"


def test_get_web_push_public_key_returns_500_when_unconfigured(client, monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "web_push_public_key", None)
    monkeypatch.setattr(settings, "web_push_subject", None)

    response = client.get("/devices/web-push/public-key")

    assert response.status_code == 500


def test_post_web_push_requires_user_header(client):
    response = client.post("/devices/web-push", json=_subscription_payload())

    assert response.status_code == 401


def test_post_web_push_rejects_unknown_user(client):
    response = client.post(
        "/devices/web-push",
        json=_subscription_payload(),
        headers={"x-missionout-user-email": "missing@gmail.com"},
    )

    assert response.status_code == 404


def test_post_web_push_creates_new_subscription(client, auth_headers, seeded_user, seeded_team, db_session):
    response = client.post(
        "/devices/web-push",
        json=_subscription_payload(team_public_id=seeded_team.public_id),
        headers=auth_headers(seeded_user),
    )

    assert response.status_code == 201
    body = response.json()
    assert body["user_public_id"] == seeded_user.public_id
    assert body["team_public_id"] == seeded_team.public_id
    assert body["endpoint"] == "https://push.example.com/abc"
    assert body["is_active"] is True
    assert db_session.query(WebPushSubscription).count() == 1


def test_post_web_push_updates_existing_subscription_returns_200(
    client, auth_headers, seeded_user, seeded_web_push_subscription, db_session
):
    response = client.post(
        "/devices/web-push",
        json=_subscription_payload(endpoint=seeded_web_push_subscription.endpoint, user_agent="pytest/updated"),
        headers=auth_headers(seeded_user),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["public_id"] == seeded_web_push_subscription.public_id
    db_session.refresh(seeded_web_push_subscription)
    assert seeded_web_push_subscription.user_agent == "pytest/updated"
    assert db_session.query(WebPushSubscription).count() == 1


def test_post_web_push_conflicts_when_endpoint_belongs_to_other_user(
    client, auth_headers, seeded_web_push_subscription, seeded_second_user
):
    response = client.post(
        "/devices/web-push",
        json=_subscription_payload(endpoint=seeded_web_push_subscription.endpoint),
        headers=auth_headers(seeded_second_user),
    )

    assert response.status_code == 409


def test_post_web_push_rejects_team_user_does_not_belong_to(
    client, auth_headers, seeded_user, seeded_second_team
):
    response = client.post(
        "/devices/web-push",
        json=_subscription_payload(team_public_id=seeded_second_team.public_id),
        headers=auth_headers(seeded_user),
    )

    assert response.status_code == 403


def test_delete_web_push_deactivates_subscription(
    client, auth_headers, seeded_user, seeded_web_push_subscription, db_session
):
    response = client.request(
        "DELETE",
        "/devices/web-push",
        json={"endpoint": seeded_web_push_subscription.endpoint},
        headers=auth_headers(seeded_user),
    )

    assert response.status_code == 204
    db_session.refresh(seeded_web_push_subscription)
    assert seeded_web_push_subscription.is_active is False


def test_delete_web_push_is_noop_for_unknown_endpoint(client, auth_headers, seeded_user):
    response = client.request(
        "DELETE",
        "/devices/web-push",
        json={"endpoint": "https://push.example.com/not-registered"},
        headers=auth_headers(seeded_user),
    )

    assert response.status_code == 204
