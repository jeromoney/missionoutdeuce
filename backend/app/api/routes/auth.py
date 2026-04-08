from datetime import datetime, timedelta
import hashlib
import logging
import secrets
from fastapi import APIRouter, Depends, HTTPException, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
import requests
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.core.time import ensure_utc, utc_now
from app.db.session import get_db
from app.models.team_management import EmailCodeToken, TeamMembership, User
from app.schemas.auth import (
    AuthTeamMembershipRead,
    AuthUserRead,
    EmailCodeRequest,
    EmailCodeSentRead,
    EmailCodeVerifyRequest,
    GoogleAuthRequest,
)


router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger(__name__)

GOOGLE_USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo"
GOOGLE_ACCESS_TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo"
RESEND_EMAILS_URL = "https://api.resend.com/emails"


def _build_auth_user_read(*, email: str, name: str, user: User | None) -> AuthUserRead:
    parts = [part for part in name.split() if part]
    if len(parts) >= 2:
        initials = f"{parts[0][0]}{parts[1][0]}".upper()
    elif parts:
        initials = parts[0][:2].upper()
    else:
        initials = "MO"

    team_memberships: list[AuthTeamMembershipRead] = []
    if user is not None:
        active_memberships = [
            membership
            for membership in user.memberships
            if membership.is_active and membership.team.is_active
        ]
        team_memberships = [
            AuthTeamMembershipRead(
                team_public_id=membership.team.public_id,
                team_name=membership.team.name,
                roles=list(membership.roles),
            )
            for membership in sorted(active_memberships, key=lambda membership: membership.team_id)
        ]

    return AuthUserRead(
        public_id=user.public_id if user is not None else "",
        name=name,
        initials=initials,
        global_permissions=[],
        team_memberships=team_memberships,
        email=email,
    )


def _load_or_create_user(*, db: Session, email: str, name: str) -> User:
    user = db.scalar(
        select(User)
        .options(selectinload(User.memberships).selectinload(TeamMembership.team))
        .where(User.email == email)
    )
    if user is None:
        user = User(
            name=name,
            email=email,
            phone="",
            is_active=True,
        )
        db.add(user)
        db.commit()
        user = db.scalar(
            select(User)
            .options(selectinload(User.memberships).selectinload(TeamMembership.team))
            .where(User.email == email)
        )

    if user is None:
        raise HTTPException(
            status_code=500,
            detail="Could not load authenticated user.",
        )

    return user


def _load_existing_user(*, db: Session, email: str) -> User | None:
    return db.scalar(
        select(User)
        .options(selectinload(User.memberships).selectinload(TeamMembership.team))
        .where(User.email == email)
    )


def _normalize_email(email: str) -> str:
    return email.strip().lower()


def _hash_email_code(*, email: str, code: str) -> str:
    normalized_email = _normalize_email(email)
    return hashlib.sha256(f"{normalized_email}:{code}".encode("utf-8")).hexdigest()


def _send_email_code_via_resend(*, recipient_email: str, code: str, requested_client: str):
    if not settings.resend_api_key or not settings.resend_from_email:
        raise HTTPException(
            status_code=500,
            detail="Resend email delivery is not configured on the backend.",
        )

    subject = "Your MissionOut sign-in code"
    html = (
        "<p>Use the one-time code below to finish signing in to MissionOut.</p>"
        f"<p style=\"font-size: 24px; font-weight: 700; letter-spacing: 0.2em;\">{code}</p>"
        f"<p>Enter this code in the {requested_client} sign-in flow.</p>"
        f"<p>This {settings.email_code_length}-digit code expires in {settings.email_code_expires_in_minutes} minutes and can only be used once.</p>"
    )
    text = (
        "Use this one-time MissionOut sign-in code:\n"
        f"{code}\n\n"
        f"Enter it in the {requested_client} sign-in flow. "
        f"This {settings.email_code_length}-digit code expires in {settings.email_code_expires_in_minutes} minutes and can only be used once."
    )
    payload = {
        "from": settings.resend_from_email,
        "to": [recipient_email],
        "subject": subject,
        "html": html,
        "text": text,
    }
    headers = {
        "Authorization": f"Bearer {settings.resend_api_key}",
        "Content-Type": "application/json",
        "User-Agent": "missionout-backend/0.1",
    }

    try:
        response = requests.post(
            RESEND_EMAILS_URL,
            headers=headers,
            json=payload,
            timeout=10,
        )
    except requests.RequestException as error:  # pragma: no cover - external delivery
        raise HTTPException(
            status_code=502,
            detail="Resend email delivery request failed.",
        ) from error

    if response.status_code < 200 or response.status_code >= 300:
        logger.error(
            "Resend email delivery failed for %s: status=%s body=%s",
            recipient_email,
            response.status_code,
            response.text,
        )
        raise HTTPException(
            status_code=502,
            detail="Resend email delivery failed.",
        )


def _enforce_email_code_rate_limit(*, db: Session, normalized_email: str) -> None:
    now = utc_now()
    window_start = now - timedelta(minutes=settings.email_code_rate_limit_window_minutes)
    recent_attempt_count = db.scalar(
        select(func.count(EmailCodeToken.id)).where(
            EmailCodeToken.email == normalized_email,
            EmailCodeToken.created_at >= window_start,
        )
    )
    if recent_attempt_count is not None and recent_attempt_count >= settings.email_code_rate_limit_attempts:
        raise HTTPException(
            status_code=429,
            detail=(
                "Too many email sign-in code requests. "
                "Please wait before requesting another code."
            ),
        )


def _verify_google_identity(payload: GoogleAuthRequest) -> dict:
    if payload.id_token:
        try:
            token_info = id_token.verify_oauth2_token(
                payload.id_token,
                google_requests.Request(),
                None,
            )
        except Exception as error:  # pragma: no cover - external verification
            raise HTTPException(
                status_code=401,
                detail="Invalid Google token",
            ) from error

        audience = token_info.get("aud")
        if audience not in settings.google_client_ids:
            raise HTTPException(
                status_code=401,
                detail="Google token audience is not allowed for this backend.",
            )

        return token_info

    if not payload.access_token:
        raise HTTPException(
            status_code=400,
            detail="Missing Google token.",
        )

    try:
        tokeninfo_response = requests.get(
            GOOGLE_ACCESS_TOKENINFO_URL,
            params={"access_token": payload.access_token},
            timeout=10,
        )
    except requests.RequestException as error:  # pragma: no cover - external verification
        raise HTTPException(
            status_code=502,
            detail="Google token verification request failed.",
        ) from error

    if tokeninfo_response.status_code != 200:
        raise HTTPException(
            status_code=401,
            detail="Invalid Google access token",
        )

    token_info = tokeninfo_response.json()
    audience = token_info.get("aud") or token_info.get("issued_to")
    if audience not in settings.google_client_ids:
        raise HTTPException(
            status_code=401,
            detail="Google token audience is not allowed for this backend.",
        )

    try:
        userinfo_response = requests.get(
            GOOGLE_USERINFO_URL,
            headers={"Authorization": f"Bearer {payload.access_token}"},
            timeout=10,
        )
    except requests.RequestException as error:  # pragma: no cover - external verification
        raise HTTPException(
            status_code=502,
            detail="Google userinfo request failed.",
        ) from error

    if userinfo_response.status_code != 200:
        raise HTTPException(
            status_code=401,
            detail="Unable to load Google user profile.",
        )

    userinfo = userinfo_response.json()
    userinfo.setdefault("aud", audience)
    return userinfo


@router.post(
    "/email-code",
    response_model=EmailCodeSentRead,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Request Email Sign-In Code",
    description=(
        "Starts email-based sign-in by asking the backend to send a one-time "
        "verification code to the supplied email address. The code is entered "
        "directly into the MissionOut client for the requested surface."
    ),
)
def request_email_code(payload: EmailCodeRequest, db: Session = Depends(get_db)):
    normalized_email = _normalize_email(payload.email)
    user = _load_existing_user(db=db, email=normalized_email)
    if user is not None and user.is_active:
        _enforce_email_code_rate_limit(db=db, normalized_email=normalized_email)

        expires_at = utc_now() + timedelta(minutes=settings.email_code_expires_in_minutes)
        upper_bound = 10 ** settings.email_code_length
        raw_code = f"{secrets.randbelow(upper_bound):0{settings.email_code_length}d}"
        token_record = EmailCodeToken(
            email=normalized_email,
            code_hash=_hash_email_code(email=normalized_email, code=raw_code),
            requested_client=payload.requested_client,
            expires_at=expires_at,
        )
        db.add(token_record)

        _send_email_code_via_resend(
            recipient_email=payload.email,
            code=raw_code,
            requested_client=payload.requested_client,
        )
        db.commit()

    return EmailCodeSentRead(
        email=payload.email,
        expires_in_minutes=settings.email_code_expires_in_minutes,
        code_length=settings.email_code_length,
        message="If the email is allowed to sign in, a one-time code has been sent.",
    )


@router.post(
    "/email-code/verify",
    response_model=AuthUserRead,
    summary="Verify Email Sign-In Code",
    description=(
        "Completes email-code sign-in by exchanging a one-time emailed code for "
        "the authenticated MissionOut user payload."
    ),
)
def verify_email_code(payload: EmailCodeVerifyRequest, db: Session = Depends(get_db)):
    normalized_email = _normalize_email(payload.email)
    token_record = db.scalar(
        select(EmailCodeToken)
        .where(
            EmailCodeToken.email == normalized_email,
            EmailCodeToken.code_hash == _hash_email_code(email=normalized_email, code=payload.code),
        )
        .order_by(EmailCodeToken.created_at.desc())
    )
    if token_record is None:
        raise HTTPException(status_code=401, detail="Invalid email sign-in code.")

    now = utc_now()
    if token_record.consumed_at is not None:
        raise HTTPException(status_code=401, detail="Email sign-in code has already been used.")
    if ensure_utc(token_record.expires_at) < now:
        raise HTTPException(status_code=401, detail="Email sign-in code has expired.")

    email = token_record.email
    user = _load_existing_user(db=db, email=email)
    if user is None or not user.is_active:
        raise HTTPException(status_code=401, detail="Invalid email sign-in code.")
    token_record.consumed_at = now
    db.commit()

    return _build_auth_user_read(email=user.email, name=user.name, user=user)


@router.post("/google", response_model=AuthUserRead)
def google_auth(payload: GoogleAuthRequest, db: Session = Depends(get_db)):
    if not settings.google_client_ids:
        raise HTTPException(
            status_code=500,
            detail="GOOGLE_CLIENT_ID is not configured on the backend.",
        )

    token_info = _verify_google_identity(payload)

    email = token_info.get("email")
    name = token_info.get("name") or email or "MissionOut User"
    if not email:
        raise HTTPException(
            status_code=400,
            detail="Google account email missing",
        )

    user = _load_or_create_user(db=db, email=email, name=name)
    return _build_auth_user_read(email=email, name=name, user=user)
