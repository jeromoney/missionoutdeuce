from datetime import timedelta

from app.core.time import utc_now
from app.models.team_management import EmailCodeToken


def test_post_email_code_returns_generic_202_for_unknown_email(client):
    response = client.post(
        "/auth/email-code",
        json={
            "email": "missing@gmail.com",
            "requested_client": "dispatcher",
        },
    )

    assert response.status_code == 202
    body = response.json()
    assert body["delivery"] == "email_code"
    assert body["email"] == "missing@gmail.com"
    assert body["message"] == "If the email is allowed to sign in, a one-time code has been sent."


def test_post_email_code_returns_202_for_provisioned_user(client, seeded_user, monkeypatch):
    import app.api.routes.auth as auth_routes

    sent_payload: dict[str, str] = {}

    def fake_send_email_code_via_resend(*, recipient_email: str, code: str, requested_client: str):
        sent_payload["recipient_email"] = recipient_email
        sent_payload["code"] = code
        sent_payload["requested_client"] = requested_client

    monkeypatch.setattr(auth_routes, "_send_email_code_via_resend", fake_send_email_code_via_resend)

    response = client.post(
        "/auth/email-code",
        json={
            "email": seeded_user.email,
            "requested_client": "dispatcher",
        },
    )

    assert response.status_code == 202
    body = response.json()
    assert body["delivery"] == "email_code"
    assert body["email"] == seeded_user.email
    assert body["code_length"] == 6
    assert sent_payload["recipient_email"] == seeded_user.email
    assert sent_payload["requested_client"] == "dispatcher"


def test_post_email_code_does_not_send_for_unknown_email(client, db_session, monkeypatch):
    import app.api.routes.auth as auth_routes

    send_count = {"count": 0}

    def fake_send_email_code_via_resend(*, recipient_email: str, code: str, requested_client: str):
        send_count["count"] += 1

    monkeypatch.setattr(auth_routes, "_send_email_code_via_resend", fake_send_email_code_via_resend)

    response = client.post(
        "/auth/email-code",
        json={
            "email": "missing@gmail.com",
            "requested_client": "dispatcher",
        },
    )

    assert response.status_code == 202
    assert send_count["count"] == 0
    assert db_session.query(EmailCodeToken).count() == 0


def test_post_email_code_rate_limits_repeated_requests(client, seeded_user, monkeypatch):
    import app.api.routes.auth as auth_routes
    from app.core.config import settings

    monkeypatch.setattr(auth_routes, "_send_email_code_via_resend", lambda **_: None)
    monkeypatch.setattr(settings, "email_code_rate_limit_attempts", 2)
    monkeypatch.setattr(settings, "email_code_rate_limit_window_minutes", 15)

    first = client.post(
        "/auth/email-code",
        json={
            "email": seeded_user.email,
            "requested_client": "dispatcher",
        },
    )
    second = client.post(
        "/auth/email-code",
        json={
            "email": seeded_user.email,
            "requested_client": "dispatcher",
        },
    )
    third = client.post(
        "/auth/email-code",
        json={
            "email": seeded_user.email,
            "requested_client": "dispatcher",
        },
    )

    assert first.status_code == 202
    assert second.status_code == 202
    assert third.status_code == 429
    assert third.json()["detail"] == (
        "Too many email sign-in code requests. Please wait before requesting another code."
    )


def test_post_email_code_verify_requires_existing_user(client, db_session):
    import app.api.routes.auth as auth_routes

    orphan_token = EmailCodeToken(
        email="deleted@gmail.com",
        code_hash=auth_routes._hash_email_code(email="deleted@gmail.com", code="123456"),
        requested_client="dispatcher",
        expires_at=utc_now() + timedelta(minutes=15),
    )
    db_session.add(orphan_token)
    db_session.commit()

    response = client.post(
        "/auth/email-code/verify",
        json={
            "email": "deleted@gmail.com",
            "code": "123456",
        },
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid email sign-in code."
