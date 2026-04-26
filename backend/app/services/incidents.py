"""Incident write paths.

Per docs/page-logic.md:

- POST /incidents writes two `incident_events` rows in one transaction:
  `incident.created` (audit) and `incident.paged` with `page_group="dispatchers"`
  (the initial page is always limited to dispatchers). Push deliveries fan out
  to dispatchers only.
- PATCH /incidents always writes `incident.updated`. If `payload.page_group`
  is non-null, an `incident.paged` row is written too and push deliveries fan
  out filtered by that group. Default is `"responder"` (page everyone); the
  caller can pass `"dispatchers"` or `null` to scope or skip the page.

Push deliveries are tagged with `event_type="incident.paged"` because they
exist to satisfy the page, not the audit-only created/updated record.

If any step fails the whole batch rolls back; partial writes are not possible.
"""
from __future__ import annotations

from typing import Iterable

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.models.incident import Incident
from app.models.incident_event import IncidentEvent
from app.models.push_delivery import PushDelivery
from app.models.team_management import (
    Device,
    Team,
    TeamMembership,
    User,
    WebPushSubscription,
)
from app.schemas.incident import IncidentCreate, IncidentUpdate, PageGroup


_DISPATCH_ROLES = ("team_admin", "dispatcher")


def _payload_snapshot(incident: Incident, team: Team | None) -> dict:
    return {
        "incident_public_id": incident.public_id,
        "team_public_id": team.public_id if team is not None else None,
        "title": incident.title,
        "location": incident.location,
        "notes": incident.notes,
        "active": incident.active,
        "version": incident.version,
        "created": incident.created_at.isoformat() if incident.created_at else None,
    }


def _targets_for_page_group(
    db: Session, team_id: int, page_group: PageGroup
) -> tuple[list[Device], list[WebPushSubscription]]:
    """Active devices + active web push subscriptions for the page group.

    `page_group="responder"` pages every active member of the team regardless
    of role. `page_group="dispatchers"` restricts to members whose
    `TeamMembership.role` is `team_admin` or `dispatcher`.
    """
    device_q = (
        select(Device)
        .join(Device.user)
        .join(User.memberships)
        .where(
            TeamMembership.team_id == team_id,
            User.is_active.is_(True),
            Device.is_active.is_(True),
        )
    )
    sub_q = (
        select(WebPushSubscription)
        .join(WebPushSubscription.user)
        .join(User.memberships)
        .where(
            TeamMembership.team_id == team_id,
            User.is_active.is_(True),
            WebPushSubscription.is_active.is_(True),
        )
    )
    if page_group == "dispatchers":
        dispatch_filter = TeamMembership.role.in_(_DISPATCH_ROLES)
        device_q = device_q.where(dispatch_filter)
        sub_q = sub_q.where(dispatch_filter)

    devices = list(db.scalars(device_q).unique())
    subs = list(db.scalars(sub_q).unique())
    return devices, subs


def _build_delivery_rows(
    incident: Incident,
    event_type: str,
    devices: Iterable[Device],
    subscriptions: Iterable[WebPushSubscription],
) -> list[PushDelivery]:
    rows: list[PushDelivery] = []
    for device in devices:
        rows.append(
            PushDelivery(
                incident_id=incident.id,
                device_id=device.id,
                web_push_subscription_id=None,
                channel="mobile",
                event_type=event_type,
                state="created",
            )
        )
    for subscription in subscriptions:
        rows.append(
            PushDelivery(
                incident_id=incident.id,
                device_id=None,
                web_push_subscription_id=subscription.id,
                channel="web_push",
                event_type=event_type,
                state="created",
            )
        )
    return rows


def _enqueue_page(
    db: Session,
    incident: Incident,
    team: Team | None,
    page_group: PageGroup,
) -> None:
    """Append an `incident.paged` event row + push deliveries for `page_group`."""
    incident.version = incident.version + 1
    db.add(
        IncidentEvent(
            incident_id=incident.id,
            version=incident.version,
            event_type="incident.paged",
            page_group=page_group,
            payload=_payload_snapshot(incident, team),
        )
    )
    if incident.team_id is not None:
        devices, subs = _targets_for_page_group(db, incident.team_id, page_group)
        delivery_rows = _build_delivery_rows(
            incident, "incident.paged", devices, subs
        )
        if delivery_rows:
            db.add_all(delivery_rows)


def create_incident(
    db: Session,
    payload: IncidentCreate,
    team: Team,
) -> Incident:
    incident = Incident(
        title=payload.title,
        team_id=team.id,
        location=payload.location,
        notes=payload.notes,
        active=payload.active,
        version=1,
    )
    db.add(incident)
    db.flush()  # populate incident.id for the FK

    # Audit event first, version 1.
    db.add(
        IncidentEvent(
            incident_id=incident.id,
            version=incident.version,
            event_type="incident.created",
            payload=_payload_snapshot(incident, team),
        )
    )

    # Initial page is always limited to dispatchers.
    _enqueue_page(db, incident, team, "dispatchers")

    db.commit()
    db.refresh(incident)
    return incident


def update_incident(
    db: Session,
    incident: Incident,
    payload: IncidentUpdate,
) -> Incident:
    incident.title = payload.title
    incident.location = payload.location
    incident.notes = payload.notes
    incident.active = payload.active
    incident.version = (incident.version or 1) + 1

    db.add(
        IncidentEvent(
            incident_id=incident.id,
            version=incident.version,
            event_type="incident.updated",
            payload=_payload_snapshot(incident, incident.team_ref),
        )
    )

    if payload.page_group is not None:
        _enqueue_page(db, incident, incident.team_ref, payload.page_group)

    db.commit()
    db.refresh(incident)
    return incident
