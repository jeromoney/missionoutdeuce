"""FastAPI dependencies for authenticated request handling.

`get_current_principal` resolves the authenticated user from a
`Authorization: Bearer <firebase-id-token>` header, verifies the Firebase ID
token, picks the effective role from the user's active memberships, and —
when the database is Postgres — primes the session with `set_config` so RLS
policies in `app/db/rls.py` see the caller's identity.

`get_firebase_claims` is a lighter dependency used by endpoints that need
Firebase identity but not a full membership check (e.g. GET /users/me, which
must succeed for unprovisioned users with no team memberships).
"""
from dataclasses import dataclass

import firebase_admin
import firebase_admin.auth
from fastapi import Depends, HTTPException, Request
from sqlalchemy import select, text
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.db.session import get_db
from app.models.team_management import TeamMembership, User


_ROLE_PRECEDENCE = ("team_admin", "dispatcher", "responder")


@dataclass(frozen=True)
class Principal:
    user: User
    role: str
    membership: TeamMembership


def user_has_active_membership(user: User) -> bool:
    """True if the user has at least one active membership on an active team."""
    return any(m.is_active and m.team.is_active for m in user.memberships)


def _select_effective_membership(user: User) -> TeamMembership | None:
    active = [m for m in user.memberships if m.is_active and m.team.is_active]
    if not active:
        return None

    def rank(membership: TeamMembership) -> tuple[int, int]:
        try:
            role_rank = _ROLE_PRECEDENCE.index(membership.role)
        except ValueError:
            role_rank = len(_ROLE_PRECEDENCE)
        return (role_rank, membership.id)

    return min(active, key=rank)


def _extract_bearer_token(request: Request) -> str:
    header = request.headers.get("authorization") or request.headers.get("Authorization")
    if not header:
        raise HTTPException(
            status_code=401,
            detail="Missing Authorization header.",
        )
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=401,
            detail="Authorization header must use Bearer scheme.",
        )
    return token.strip()


def _verify_firebase_token(token: str) -> dict:
    """Verify a Firebase ID token and return decoded claims.

    Isolated as a named function so tests can monkeypatch it without
    triggering real Firebase SDK calls or network requests.
    """
    try:
        app = firebase_admin.get_app()
    except ValueError:
        if settings.firebase_credentials_path:
            credential = firebase_admin.credentials.Certificate(settings.firebase_credentials_path)
        else:
            credential = firebase_admin.credentials.ApplicationDefault()
        options = {"projectId": settings.firebase_project_id} if settings.firebase_project_id else {}
        app = firebase_admin.initialize_app(credential=credential, options=options or None)
    try:
        return firebase_admin.auth.verify_id_token(token, app=app)
    except firebase_admin.auth.InvalidIdTokenError as error:
        raise HTTPException(
            status_code=401, detail="Invalid Firebase ID token."
        ) from error
    except Exception as error:
        raise HTTPException(
            status_code=503, detail="Firebase token verification unavailable."
        ) from error


def _load_user_by_email(db: Session, email: str) -> User | None:
    normalized = email.strip().lower()
    return db.scalar(
        select(User)
        .options(selectinload(User.memberships).selectinload(TeamMembership.team))
        .where(User.email == normalized)
    )


def _set_rls_gucs(db: Session, user_id: int, role: str) -> None:
    if db.bind is not None and db.bind.dialect.name == "postgresql":
        db.execute(
            text("SELECT set_config('app.user_id', :uid, true)"),
            {"uid": str(user_id)},
        )
        db.execute(
            text("SELECT set_config('app.role', :role, true)"),
            {"role": role},
        )


def get_firebase_claims(request: Request) -> dict:
    """Verify Firebase ID token and return decoded claims.

    Raises 401 if the token is missing, invalid, or lacks an email claim.
    Does NOT require the user to exist in the database or have any team
    memberships — safe for use on endpoints that serve unprovisioned users.
    """
    token = _extract_bearer_token(request)
    claims = _verify_firebase_token(token)
    if not claims.get("email"):
        raise HTTPException(
            status_code=401, detail="Firebase token missing email claim."
        )
    return claims


def get_current_principal(
    request: Request,
    db: Session = Depends(get_db),
) -> Principal:
    token = _extract_bearer_token(request)
    claims = _verify_firebase_token(token)

    email = claims.get("email")
    if not email:
        raise HTTPException(
            status_code=401, detail="Firebase token missing email claim."
        )

    user = _load_user_by_email(db, email)
    if user is None:
        raise HTTPException(
            status_code=401,
            detail="Authenticated user is not recognized.",
        )

    membership = _select_effective_membership(user)
    if membership is None:
        raise HTTPException(
            status_code=403,
            detail="Authenticated user does not have access to any active teams.",
        )

    _set_rls_gucs(db, user.id, membership.role)
    return Principal(user=user, role=membership.role, membership=membership)
