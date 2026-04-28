"""Token primitives for backend-issued sessions.

Authentication is split into two credentials:

- A short-lived (default 1h) HS256 access JWT carrying identity-only claims
  (`sub` = user public_id, `email`). `get_current_principal` verifies the JWT
  and re-loads role/team membership from the database on every request, so
  role demotions take effect immediately without needing token revocation.

- A long-lived (default 180d) opaque refresh token. The plaintext value is
  returned to the client once at issue time and never persisted; the server
  only keeps a SHA-256 hash. Each /auth/refresh call rotates the token: the
  presented row is marked used + revoked, a new row is issued, and the chain
  is linked via `replaced_by_id`. Replaying an already-rotated token is
  treated as theft and revokes the entire chain for that user.
"""
from datetime import datetime, timedelta
import hashlib
import secrets

import jwt
from fastapi import HTTPException
from sqlalchemy import select, update
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.core.time import ensure_utc, utc_now
from app.models.team_management import RefreshToken, TeamMembership, User


_ACCESS_TOKEN_TYPE = "access"
_JWT_ALGORITHM = "HS256"


def _signing_key() -> str:
    if not settings.jwt_signing_key:
        raise HTTPException(
            status_code=500,
            detail="JWT_SIGNING_KEY is not configured on the backend.",
        )
    return settings.jwt_signing_key


def create_access_token(user: User) -> tuple[str, datetime]:
    issued_at = utc_now()
    expires_at = issued_at + timedelta(minutes=settings.access_token_minutes)
    payload = {
        "sub": user.public_id,
        "email": user.email,
        "type": _ACCESS_TOKEN_TYPE,
        "iss": settings.jwt_issuer,
        "iat": int(issued_at.timestamp()),
        "exp": int(expires_at.timestamp()),
    }
    token = jwt.encode(payload, _signing_key(), algorithm=_JWT_ALGORITHM)
    return token, expires_at


def decode_access_token(token: str) -> dict:
    try:
        claims = jwt.decode(
            token,
            _signing_key(),
            algorithms=[_JWT_ALGORITHM],
            issuer=settings.jwt_issuer,
            options={"require": ["exp", "iat", "iss", "sub"]},
        )
    except jwt.ExpiredSignatureError as error:
        raise HTTPException(status_code=401, detail="Access token has expired.") from error
    except jwt.InvalidTokenError as error:
        raise HTTPException(status_code=401, detail="Invalid access token.") from error

    if claims.get("type") != _ACCESS_TOKEN_TYPE:
        raise HTTPException(status_code=401, detail="Invalid access token type.")
    return claims


def _hash_refresh_token(plaintext: str) -> str:
    return hashlib.sha256(plaintext.encode("utf-8")).hexdigest()


def _generate_refresh_plaintext() -> str:
    return secrets.token_urlsafe(48)


def create_refresh_token(
    db: Session,
    user: User,
    *,
    user_agent: str | None = None,
) -> tuple[str, datetime]:
    """Mint a new refresh token row. Returns (plaintext, expires_at).

    The plaintext value is the only time the token is exposed; only its
    SHA-256 hash is stored.
    """
    plaintext = _generate_refresh_plaintext()
    expires_at = utc_now() + timedelta(days=settings.refresh_token_days)
    record = RefreshToken(
        user_id=user.id,
        token_hash=_hash_refresh_token(plaintext),
        expires_at=expires_at,
        user_agent=(user_agent[:255] if user_agent else None),
    )
    db.add(record)
    db.flush()
    return plaintext, expires_at


def _load_refresh_with_user(db: Session, token_hash: str) -> RefreshToken | None:
    return db.scalar(
        select(RefreshToken)
        .options(
            selectinload(RefreshToken.user)
            .selectinload(User.memberships)
            .selectinload(TeamMembership.team)
        )
        .where(RefreshToken.token_hash == token_hash)
    )


def _revoke_chain_for_user(db: Session, user_id: int) -> None:
    db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=utc_now())
    )


def rotate_refresh_token(
    db: Session,
    presented: str,
    *,
    user_agent: str | None = None,
) -> tuple[User, str, datetime, str, datetime]:
    """Exchange a refresh token for a new access + refresh pair.

    Returns (user, access_token, access_expires_at, new_refresh_plaintext,
    refresh_expires_at). On replay (presented token already revoked), revokes
    every active refresh token for the owning user as a precaution and
    raises 401.
    """
    presented_hash = _hash_refresh_token(presented)
    record = _load_refresh_with_user(db, presented_hash)
    if record is None:
        raise HTTPException(status_code=401, detail="Invalid refresh token.")

    now = utc_now()
    if record.revoked_at is not None:
        _revoke_chain_for_user(db, record.user_id)
        db.commit()
        raise HTTPException(status_code=401, detail="Refresh token has been revoked.")
    if ensure_utc(record.expires_at) < now:
        raise HTTPException(status_code=401, detail="Refresh token has expired.")

    user = record.user
    if user is None or not user.is_active:
        raise HTTPException(status_code=401, detail="Refresh token user is not active.")

    new_plaintext, new_expires_at = create_refresh_token(db, user, user_agent=user_agent)
    new_record = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == _hash_refresh_token(new_plaintext))
    )
    record.last_used_at = now
    record.revoked_at = now
    record.replaced_by_id = new_record.id if new_record is not None else None

    access_token, access_expires_at = create_access_token(user)
    return user, access_token, access_expires_at, new_plaintext, new_expires_at


def revoke_refresh_token(db: Session, presented: str) -> None:
    """Idempotent: if the token doesn't match a row, do nothing."""
    record = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == _hash_refresh_token(presented))
    )
    if record is None or record.revoked_at is not None:
        return
    record.revoked_at = utc_now()
