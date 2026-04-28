from datetime import timedelta
from unittest.mock import patch

import jwt
import pytest
from fastapi import HTTPException

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    revoke_refresh_token,
    rotate_refresh_token,
)
from app.core.time import utc_now
from app.models.team_management import RefreshToken


def test_create_then_decode_access_token_round_trip(seeded_user):
    token, expires_at = create_access_token(seeded_user)
    assert isinstance(token, str)
    assert expires_at > utc_now()

    claims = decode_access_token(token)
    assert claims["sub"] == seeded_user.public_id
    assert claims["email"] == seeded_user.email
    assert claims["type"] == "access"
    assert claims["iss"] == settings.jwt_issuer


def test_decode_rejects_expired_token(seeded_user):
    issued = utc_now() - timedelta(hours=2)
    payload = {
        "sub": seeded_user.public_id,
        "email": seeded_user.email,
        "type": "access",
        "iss": settings.jwt_issuer,
        "iat": int(issued.timestamp()),
        "exp": int((issued + timedelta(seconds=1)).timestamp()),
    }
    expired = jwt.encode(payload, settings.jwt_signing_key, algorithm="HS256")
    with pytest.raises(HTTPException) as exc:
        decode_access_token(expired)
    assert exc.value.status_code == 401


def test_decode_rejects_wrong_issuer(seeded_user):
    payload = {
        "sub": seeded_user.public_id,
        "email": seeded_user.email,
        "type": "access",
        "iss": "someone-else",
        "iat": int(utc_now().timestamp()),
        "exp": int((utc_now() + timedelta(minutes=5)).timestamp()),
    }
    bad = jwt.encode(payload, settings.jwt_signing_key, algorithm="HS256")
    with pytest.raises(HTTPException) as exc:
        decode_access_token(bad)
    assert exc.value.status_code == 401


def test_decode_rejects_non_access_type(seeded_user):
    payload = {
        "sub": seeded_user.public_id,
        "email": seeded_user.email,
        "type": "refresh",
        "iss": settings.jwt_issuer,
        "iat": int(utc_now().timestamp()),
        "exp": int((utc_now() + timedelta(minutes=5)).timestamp()),
    }
    wrong = jwt.encode(payload, settings.jwt_signing_key, algorithm="HS256")
    with pytest.raises(HTTPException) as exc:
        decode_access_token(wrong)
    assert exc.value.status_code == 401


def test_create_refresh_token_persists_only_hash(db_session, seeded_user):
    plaintext, expires_at = create_refresh_token(db_session, seeded_user)
    assert isinstance(plaintext, str) and len(plaintext) > 30
    assert expires_at > utc_now()

    rows = db_session.query(RefreshToken).filter_by(user_id=seeded_user.id).all()
    assert len(rows) == 1
    assert rows[0].token_hash != plaintext
    assert len(rows[0].token_hash) == 64


def test_rotate_refresh_token_happy_path(db_session, seeded_user):
    plaintext, _ = create_refresh_token(db_session, seeded_user)
    db_session.commit()

    user, access, _, new_refresh, _ = rotate_refresh_token(db_session, plaintext)
    assert user.id == seeded_user.id
    assert access  # signed JWT
    assert new_refresh != plaintext

    decoded = decode_access_token(access)
    assert decoded["sub"] == seeded_user.public_id

    rows = db_session.query(RefreshToken).filter_by(user_id=seeded_user.id).order_by(RefreshToken.id).all()
    assert len(rows) == 2
    assert rows[0].revoked_at is not None
    assert rows[0].replaced_by_id == rows[1].id
    assert rows[1].revoked_at is None


def test_rotate_refresh_token_replay_revokes_chain(db_session, seeded_user):
    plaintext, _ = create_refresh_token(db_session, seeded_user)
    db_session.commit()

    rotate_refresh_token(db_session, plaintext)
    db_session.commit()

    with pytest.raises(HTTPException) as exc:
        rotate_refresh_token(db_session, plaintext)
    assert exc.value.status_code == 401

    active = (
        db_session.query(RefreshToken)
        .filter_by(user_id=seeded_user.id, revoked_at=None)
        .count()
    )
    assert active == 0


def test_rotate_refresh_token_rejects_unknown_token(db_session):
    with pytest.raises(HTTPException) as exc:
        rotate_refresh_token(db_session, "definitely-not-a-real-token")
    assert exc.value.status_code == 401


def test_rotate_refresh_token_rejects_expired(db_session, seeded_user):
    plaintext, _ = create_refresh_token(db_session, seeded_user)
    db_session.flush()
    record = db_session.query(RefreshToken).filter_by(user_id=seeded_user.id).one()
    record.expires_at = utc_now() - timedelta(seconds=1)
    db_session.commit()

    with pytest.raises(HTTPException) as exc:
        rotate_refresh_token(db_session, plaintext)
    assert exc.value.status_code == 401


def test_revoke_refresh_token_is_idempotent(db_session, seeded_user):
    plaintext, _ = create_refresh_token(db_session, seeded_user)
    db_session.commit()

    revoke_refresh_token(db_session, plaintext)
    db_session.commit()

    record = db_session.query(RefreshToken).filter_by(user_id=seeded_user.id).one()
    assert record.revoked_at is not None
    first_revoked = record.revoked_at

    revoke_refresh_token(db_session, plaintext)
    db_session.refresh(record)
    assert record.revoked_at == first_revoked

    revoke_refresh_token(db_session, "no-such-token")
