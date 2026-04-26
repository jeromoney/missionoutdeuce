"""Targeting matrix + audit invariants for incident_events / push_deliveries."""
import pytest
from sqlalchemy.exc import IntegrityError

from app.core.time import utc_now
from app.models.incident import Incident
from app.models.incident_event import IncidentEvent
from app.models.push_delivery import PushDelivery
from app.models.team_management import Device, User, TeamMembership, WebPushSubscription
from app.schemas.incident import IncidentCreate
from app.services import incidents as incident_service


def _create_payload(team_public_id: str) -> IncidentCreate:
    return IncidentCreate(
        title="Audit Trace",
        team_public_id=team_public_id,
        location="Anywhere",
        notes="",
        active=True,
    )


def test_inactive_user_devices_are_excluded(db_session, seeded_team, seeded_user):
    # Make the inactive user a dispatcher so they would be a page target if
    # active; the assertion proves inactivity is what excludes them, not role.
    inactive_user = User(
        name="Inactive Inez",
        email="inactive@example.com",
        phone="",
        is_active=False,
    )
    db_session.add(inactive_user)
    db_session.flush()
    db_session.add(
        TeamMembership(
            user_id=inactive_user.id,
            team_id=seeded_team.id,
            roles=["dispatcher"],
            role="dispatcher",
            granted_at=utc_now(),
        )
    )
    db_session.add(
        Device(
            user_id=inactive_user.id,
            platform="ios",
            push_token="inactive-user-token",
            last_seen=utc_now(),
            is_active=True,
            is_verified=True,
        )
    )
    db_session.commit()

    incident = incident_service.create_incident(
        db=db_session,
        payload=_create_payload(seeded_team.public_id),
        team=seeded_team,
    )

    deliveries = (
        db_session.query(PushDelivery).filter_by(incident_id=incident.id).all()
    )
    assert "inactive-user-token" not in {
        d.device.push_token for d in deliveries if d.device is not None
    }


def test_inactive_device_is_excluded(db_session, seeded_team, seeded_user):
    db_session.add(
        Device(
            user_id=seeded_user.id,
            platform="android",
            push_token="dormant-token",
            last_seen=utc_now(),
            is_active=False,
            is_verified=True,
        )
    )
    db_session.commit()

    incident = incident_service.create_incident(
        db=db_session,
        payload=_create_payload(seeded_team.public_id),
        team=seeded_team,
    )
    tokens = {
        d.device.push_token
        for d in db_session.query(PushDelivery).filter_by(incident_id=incident.id).all()
        if d.device is not None
    }
    assert "dormant-token" not in tokens


def test_inactive_subscription_is_excluded(db_session, seeded_team, seeded_user):
    db_session.add(
        WebPushSubscription(
            user_id=seeded_user.id,
            team_id=seeded_team.id,
            endpoint="https://push.example.com/dormant",
            p256dh="x",
            auth="y",
            user_agent="ua",
            client="dispatcher",
            last_seen=utc_now(),
            is_active=False,
        )
    )
    db_session.commit()

    incident = incident_service.create_incident(
        db=db_session,
        payload=_create_payload(seeded_team.public_id),
        team=seeded_team,
    )
    endpoints = {
        d.web_push_subscription.endpoint
        for d in db_session.query(PushDelivery).filter_by(incident_id=incident.id).all()
        if d.web_push_subscription is not None
    }
    assert "https://push.example.com/dormant" not in endpoints


def test_dispatchers_page_group_filters_out_responder_only_members(
    db_session, seeded_team, seeded_user
):
    # A pure-responder member of the same team must NOT receive the initial
    # page (which is always page_group="dispatchers" on create).
    responder_user = User(
        name="Roxanne Responder",
        email="roxanne@example.com",
        phone="",
        is_active=True,
    )
    db_session.add(responder_user)
    db_session.flush()
    db_session.add(
        TeamMembership(
            user_id=responder_user.id,
            team_id=seeded_team.id,
            roles=["responder"],
            role="responder",
            granted_at=utc_now(),
        )
    )
    db_session.add(
        Device(
            user_id=responder_user.id,
            platform="ios",
            push_token="responder-token",
            last_seen=utc_now(),
            is_active=True,
            is_verified=True,
        )
    )
    db_session.commit()

    incident = incident_service.create_incident(
        db=db_session,
        payload=_create_payload(seeded_team.public_id),
        team=seeded_team,
    )
    tokens = {
        d.device.push_token
        for d in db_session.query(PushDelivery).filter_by(incident_id=incident.id).all()
        if d.device is not None
    }
    assert "responder-token" not in tokens


def test_unique_incident_version_constraint_trips(db_session, seeded_incident):
    db_session.add(
        IncidentEvent(
            incident_id=seeded_incident.id,
            version=1,
            event_type="incident.created",
            payload={},
        )
    )
    db_session.add(
        IncidentEvent(
            incident_id=seeded_incident.id,
            version=1,
            event_type="incident.created",
            payload={},
        )
    )
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()


def test_push_delivery_check_constraint_blocks_zero_targets(db_session, seeded_incident):
    db_session.add(
        PushDelivery(
            incident_id=seeded_incident.id,
            device_id=None,
            web_push_subscription_id=None,
            channel="mobile",
            event_type="incident.created",
        )
    )
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()


def test_push_delivery_check_constraint_blocks_two_targets(
    db_session, seeded_incident, seeded_device, seeded_web_push_subscription
):
    db_session.add(
        PushDelivery(
            incident_id=seeded_incident.id,
            device_id=seeded_device.id,
            web_push_subscription_id=seeded_web_push_subscription.id,
            channel="mobile",
            event_type="incident.created",
        )
    )
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()


def test_paged_event_payload_snapshots_incident_state(db_session, seeded_team, seeded_user):
    incident = incident_service.create_incident(
        db=db_session,
        payload=_create_payload(seeded_team.public_id),
        team=seeded_team,
    )
    paged = (
        db_session.query(IncidentEvent)
        .filter_by(incident_id=incident.id, event_type="incident.paged")
        .one()
    )
    payload = paged.payload
    assert payload["incident_public_id"] == incident.public_id
    assert payload["team_public_id"] == seeded_team.public_id
    assert payload["title"] == "Audit Trace"
    assert payload["location"] == "Anywhere"
    assert payload["notes"] == ""
    assert payload["active"] is True
    assert payload["created"] is not None


def test_paged_event_payload_version_matches_row_version(db_session, seeded_team, seeded_user):
    # On create: incident.created is v1, incident.paged is v2.
    incident = incident_service.create_incident(
        db=db_session,
        payload=_create_payload(seeded_team.public_id),
        team=seeded_team,
    )
    paged_create = (
        db_session.query(IncidentEvent)
        .filter_by(incident_id=incident.id, event_type="incident.paged")
        .one()
    )
    assert paged_create.version == 2
    assert paged_create.payload["version"] == paged_create.version

    # On update with default page_group="responder": updated is v3, paged is v4.
    from app.schemas.incident import IncidentUpdate

    incident_service.update_incident(
        db=db_session,
        incident=incident,
        payload=IncidentUpdate(
            title=incident.title,
            location=incident.location,
            notes="bumped",
            active=incident.active,
        ),
    )
    paged_update = (
        db_session.query(IncidentEvent)
        .filter_by(incident_id=incident.id, event_type="incident.paged", version=4)
        .one()
    )
    assert paged_update.payload["version"] == 4


def test_empty_targeting_set_still_writes_events(db_session, seeded_team, seeded_user):
    # seeded_user is admin but the team has no devices/subs in this test.
    incident = incident_service.create_incident(
        db=db_session,
        payload=_create_payload(seeded_team.public_id),
        team=seeded_team,
    )
    events = (
        db_session.query(IncidentEvent)
        .filter_by(incident_id=incident.id)
        .order_by(IncidentEvent.version.asc())
        .all()
    )
    deliveries = db_session.query(PushDelivery).filter_by(incident_id=incident.id).all()
    # Both audit and page rows are written even when there are no push targets.
    assert [(e.event_type, e.page_group) for e in events] == [
        ("incident.created", None),
        ("incident.paged", "dispatchers"),
    ]
    assert deliveries == []
