"""FastAPI dependencies for authenticated request handling.

`get_current_principal` resolves the authenticated user from a
`Authorization: Bearer <jwt>` header, verifies the access token signature
and expiry, picks the effective role from the user's active memberships, and
— when the database is Postgres — primes the session with `SET LOCAL
app.user_id` and `SET LOCAL app.role` so RLS policies in `app/db/rls.py` see
the caller's identity.

Note that `SET LOCAL` only persists within the current transaction; a
`db.commit()` inside a handler will clear the setting. Handlers that need to
commit mid-request and continue hitting RLS-protected tables must re-run
`SET LOCAL` themselves.

TODO(rls): migrate local dev + CI to Postgres so SET LOCAL is exercised in
tests. Today the suite runs on SQLite and this dependency is effectively a
no-op for the context-setting step.
"""
from dataclasses import dataclass

from fastapi import Depends, HTTPException, Request
from sqlalchemy import select, text
from sqlalchemy.orm import Session, selectinload

from app.core.security import decode_access_token
from app.db.session import get_db
from app.models.team_management import TeamMembership, User


_ROLE_PRECEDENCE = ("team_admin", "dispatcher", "responder")


@dataclass(frozen=True)
class Principal:
    user: User
    role: str
    membership: TeamMembership


def _select_effective_membership(user: User) -> TeamMembership | None:
    active = [m for m in user.memberships if m.team.is_active]
    if not active:
        return None
    # Pick the highest-privilege role across the user's active memberships.
    # Ties are broken by stable ordering on membership id.
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


def get_current_principal(
    request: Request,
    db: Session = Depends(get_db),
) -> Principal:
    token = _extract_bearer_token(request)
    claims = decode_access_token(token)

    user = db.scalar(
        select(User)
        .options(selectinload(User.memberships).selectinload(TeamMembership.team))
        .where(User.public_id == claims["sub"])
    )
    if user is None or not user.is_active:
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

    if db.bind is not None and db.bind.dialect.name == "postgresql":
        # Equivalent to `SET LOCAL app.user_id = ...` but supports bound params.
        # Postgres' SET grammar does not accept placeholders via the extended
        # query protocol; set_config(is_local=true) matches SET LOCAL scope.
        db.execute(
            text("SELECT set_config('app.user_id', :uid, true)"),
            {"uid": str(user.id)},
        )
        db.execute(
            text("SELECT set_config('app.role', :role, true)"),
            {"role": membership.role},
        )

    return Principal(user=user, role=membership.role, membership=membership)
