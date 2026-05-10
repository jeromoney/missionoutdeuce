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


def test_post_google_rejects_unknown_email(client, monkeypatch):
    import app.api.routes.auth as auth_routes
    from app.core.config import settings

    monkeypatch.setattr(
        auth_routes,
        "_verify_google_identity",
        lambda payload: {
            "email": "unknown@gmail.com",
            "name": "Unknown User",
            "aud": "test-client-id",
        },
    )
    monkeypatch.setattr(settings, "google_client_id", "test-client-id")

    response = client.post(
        "/auth/google",
        json={
            "id_token": "fake-google-token",
            "requested_client": "dispatcher",
        },
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Contact your administrator for support referencing unknown@gmail.com."


def test_post_google_returns_provisioned_user(client, seeded_user, monkeypatch):
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
        json={
            "id_token": "fake-google-token",
            "requested_client": "dispatcher",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["user"]["public_id"] == seeded_user.public_id
    assert body["user"]["email"] == seeded_user.email
    assert body["access_token"]
    assert body["refresh_token"]


def test_post_email_code_verify_happy_path(client, seeded_user, monkeypatch, db_session):
    import app.api.routes.auth as auth_routes

    captured: dict[str, str] = {}

    def fake_send(*, recipient_email: str, code: str, requested_client: str):
        captured["code"] = code

    monkeypatch.setattr(auth_routes, "_send_email_code_via_resend", fake_send)

    request = client.post(
        "/auth/email-code",
        json={"email": seeded_user.email, "requested_client": "dispatcher"},
    )
    assert request.status_code == 202

    verify = client.post(
        "/auth/email-code/verify",
        json={"email": seeded_user.email, "code": captured["code"]},
    )

    assert verify.status_code == 200
    body = verify.json()
    assert body["user"]["public_id"] == seeded_user.public_id
    assert body["user"]["email"] == seeded_user.email
    assert body["user"]["team_memberships"][0]["team_name"] == "Cinder Valley Rescue"
    assert body["access_token"]
    assert body["refresh_token"]

    token_record = (
        db_session.query(EmailCodeToken).filter_by(email=seeded_user.email).one()
    )
    assert token_record.consumed_at is not None


def test_post_email_code_verify_rejects_expired_code(client, seeded_user, db_session):
    import app.api.routes.auth as auth_routes

    expired_token = EmailCodeToken(
        email=seeded_user.email,
        code_hash=auth_routes._hash_email_code(email=seeded_user.email, code="111111"),
        requested_client="dispatcher",
        expires_at=utc_now() - timedelta(minutes=1),
    )
    db_session.add(expired_token)
    db_session.commit()

    response = client.post(
        "/auth/email-code/verify",
        json={"email": seeded_user.email, "code": "111111"},
    )

    assert response.status_code == 401
    assert "expired" in response.json()["detail"].lower()


def test_post_email_code_verify_rejects_reused_code(client, seeded_user, db_session):
    import app.api.routes.auth as auth_routes

    consumed_token = EmailCodeToken(
        email=seeded_user.email,
        code_hash=auth_routes._hash_email_code(email=seeded_user.email, code="222222"),
        requested_client="dispatcher",
        expires_at=utc_now() + timedelta(minutes=15),
        consumed_at=utc_now(),
    )
    db_session.add(consumed_token)
    db_session.commit()

    response = client.post(
        "/auth/email-code/verify",
        json={"email": seeded_user.email, "code": "222222"},
    )

    assert response.status_code == 401
    assert "already been used" in response.json()["detail"].lower()


def test_post_email_code_verify_locks_token_after_max_failed_attempts(
    client, seeded_user, db_session, monkeypatch
):
    import app.api.routes.auth as auth_routes
    from app.core.config import settings

    monkeypatch.setattr(settings, "email_code_max_verify_attempts", 5)
    monkeypatch.setattr(settings, "email_code_verify_rate_limit_attempts", 999)

    captured: dict[str, str] = {}

    def fake_send(*, recipient_email: str, code: str, requested_client: str):
        captured["code"] = code

    monkeypatch.setattr(auth_routes, "_send_email_code_via_resend", fake_send)

    issued = client.post(
        "/auth/email-code",
        json={"email": seeded_user.email, "requested_client": "dispatcher"},
    )
    assert issued.status_code == 202
    real_code = captured["code"]
    wrong_code = "000000" if real_code != "000000" else "000001"

    for _ in range(5):
        bad = client.post(
            "/auth/email-code/verify",
            json={"email": seeded_user.email, "code": wrong_code},
        )
        assert bad.status_code == 401
        assert bad.json()["detail"] == "Invalid email sign-in code."

    token = (
        db_session.query(EmailCodeToken).filter_by(email=seeded_user.email).one()
    )
    db_session.refresh(token)
    assert token.failed_attempts == 5
    assert token.consumed_at is not None

    correct_after_lock = client.post(
        "/auth/email-code/verify",
        json={"email": seeded_user.email, "code": real_code},
    )
    assert correct_after_lock.status_code == 401
    assert correct_after_lock.json()["detail"] == "Email sign-in code has already been used."


def test_post_email_code_verify_rate_limits_across_multiple_codes(
    client, seeded_user, db_session, monkeypatch
):
    import app.api.routes.auth as auth_routes
    from app.core.config import settings

    monkeypatch.setattr(settings, "email_code_max_verify_attempts", 5)
    monkeypatch.setattr(settings, "email_code_verify_rate_limit_attempts", 10)
    monkeypatch.setattr(settings, "email_code_verify_rate_limit_window_minutes", 15)
    monkeypatch.setattr(settings, "email_code_rate_limit_attempts", 999)

    captured_codes: list[str] = []

    def fake_send(*, recipient_email: str, code: str, requested_client: str):
        captured_codes.append(code)

    monkeypatch.setattr(auth_routes, "_send_email_code_via_resend", fake_send)

    for _ in range(2):
        issued = client.post(
            "/auth/email-code",
            json={"email": seeded_user.email, "requested_client": "dispatcher"},
        )
        assert issued.status_code == 202

    real_codes = set(captured_codes)
    wrong_code = "000000"
    while wrong_code in real_codes:
        wrong_code = f"{(int(wrong_code) + 1) % 10**6:06d}"

    # 5 wrong guesses lock the most recent token; the next 5 lock the older
    # one. After 10 failed attempts in the window the per-email limiter fires.
    for _ in range(10):
        bad = client.post(
            "/auth/email-code/verify",
            json={"email": seeded_user.email, "code": wrong_code},
        )
        assert bad.status_code == 401

    blocked = client.post(
        "/auth/email-code/verify",
        json={"email": seeded_user.email, "code": wrong_code},
    )
    assert blocked.status_code == 429
    assert blocked.json()["detail"] == (
        "Too many sign-in code verification attempts. "
        "Please request a new code and try again later."
    )

    total_failed = sum(
        token.failed_attempts
        for token in db_session.query(EmailCodeToken)
        .filter_by(email=seeded_user.email)
        .all()
    )
    assert total_failed >= 10


def test_post_google_rejects_aud_not_in_allowed_ids(client, monkeypatch):
    import app.api.routes.auth as auth_routes
    from app.core.config import settings

    def fake_verify_oauth2_token(token, request, audience):
        return {"aud": "unapproved-client-id", "email": "one@gmail.com", "name": "x"}

    monkeypatch.setattr(
        auth_routes.id_token, "verify_oauth2_token", fake_verify_oauth2_token
    )
    monkeypatch.setattr(settings, "google_client_id", "approved-client-id")

    response = client.post(
        "/auth/google",
        json={"id_token": "fake-google-token", "requested_client": "dispatcher"},
    )

    assert response.status_code == 401
    assert "audience" in response.json()["detail"].lower()


def test_post_google_rejects_verified_payload_missing_email(client, monkeypatch):
    import app.api.routes.auth as auth_routes
    from app.core.config import settings

    monkeypatch.setattr(
        auth_routes,
        "_verify_google_identity",
        lambda payload: {"aud": "test-client-id", "name": "Nameless"},
    )
    monkeypatch.setattr(settings, "google_client_id", "test-client-id")

    response = client.post(
        "/auth/google",
        json={"id_token": "fake-google-token", "requested_client": "dispatcher"},
    )

    assert response.status_code == 400
    assert "email" in response.json()["detail"].lower()
