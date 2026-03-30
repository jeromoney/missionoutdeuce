from datetime import datetime, timedelta
import hashlib
import logging
import secrets
from urllib.parse import urlencode

from fastapi import APIRouter, Depends, HTTPException, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
import requests
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.db.session import get_db
from app.models.team_management import EmailLinkToken, TeamMembership, User
from app.schemas.auth import (
    AuthTeamMembershipRead,
    AuthUserRead,
    EmailLinkRequest,
    EmailLinkSentRead,
    EmailLinkVerifyRequest,
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
                team_id=membership.team_id,
                team_name=membership.team.name,
                roles=list(membership.roles),
            )
            for membership in sorted(active_memberships, key=lambda membership: membership.team_id)
        ]

    return AuthUserRead(
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


def _hash_email_link_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _build_email_link_callback(token: str, requested_client: str) -> str:
    query = urlencode({"token": token, "requested_client": requested_client})
    return f"{settings.email_link_callback_base_url}?{query}"


def _send_email_link_via_resend(*, recipient_email: str, callback_url: str, requested_client: str):
    if not settings.resend_api_key or not settings.resend_from_email:
        raise HTTPException(
            status_code=500,
            detail="Resend email delivery is not configured on the backend.",
        )

    subject = "Your MissionOut sign-in link"
    html = (
        "<p>Use the secure link below to finish signing in to MissionOut.</p>"
        f"<p><a href=\"{callback_url}\">Sign in to {requested_client}</a></p>"
        f"<p>This link expires in {settings.email_link_expires_in_minutes} minutes and can only be used once.</p>"
    )
    text = (
        "Use this secure MissionOut sign-in link:\n"
        f"{callback_url}\n\n"
        f"This link expires in {settings.email_link_expires_in_minutes} minutes and can only be used once."
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
    "/email-link",
    response_model=EmailLinkSentRead,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Request Email Sign-In Link",
    description=(
        "Starts email-based sign-in by asking the backend to send a sign-in link "
        "to the supplied email address. The emailed link should land on a "
        "MissionOut-controlled HTTPS callback that can continue in web or hand "
        "off to the appropriate native app for the requested client surface."
    ),
)
def request_email_link(payload: EmailLinkRequest, db: Session = Depends(get_db)):
    expires_at = datetime.utcnow() + timedelta(minutes=settings.email_link_expires_in_minutes)
    raw_token = secrets.token_urlsafe(32)
    token_record = EmailLinkToken(
        email=payload.email.strip().lower(),
        token_hash=_hash_email_link_token(raw_token),
        requested_client=payload.requested_client,
        expires_at=expires_at,
    )
    db.add(token_record)

    callback_url = _build_email_link_callback(raw_token, payload.requested_client)
    _send_email_link_via_resend(
        recipient_email=payload.email,
        callback_url=callback_url,
        requested_client=payload.requested_client,
    )
    db.commit()

    return EmailLinkSentRead(
        email=payload.email,
        expires_in_minutes=settings.email_link_expires_in_minutes,
        message="If the email is allowed to sign in, a sign-in link has been sent.",
    )


@router.post(
    "/email-link/verify",
    response_model=AuthUserRead,
    summary="Verify Email Sign-In Link",
    description=(
        "Completes email-link sign-in by exchanging a one-time emailed token for "
        "the authenticated MissionOut user payload. This endpoint is redeemed by "
        "whichever authorized client actually receives the callback link, such as "
        "web or a native app."
    ),
)
def verify_email_link(payload: EmailLinkVerifyRequest, db: Session = Depends(get_db)):
    token_record = db.scalar(
        select(EmailLinkToken).where(
            EmailLinkToken.token_hash == _hash_email_link_token(payload.token)
        )
    )
    if token_record is None:
        raise HTTPException(status_code=401, detail="Invalid email sign-in link.")

    now = datetime.utcnow()
    if token_record.consumed_at is not None:
        raise HTTPException(status_code=401, detail="Email sign-in link has already been used.")
    if token_record.expires_at < now:
        raise HTTPException(status_code=401, detail="Email sign-in link has expired.")

    email = token_record.email
    user = _load_or_create_user(
        db=db,
        email=email,
        name=email.split("@", 1)[0].replace(".", " ").title() or email,
    )
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
