from app.models.incident import Incident, ResponseRecord
from app.models.incident_event import IncidentEvent
from app.models.push_delivery import PushDelivery


def test_create_incident_then_see_it_then_respond(client, seeded_user, seeded_team, auth_headers):
    create = client.post(
        "/incidents",
        headers=auth_headers(seeded_user),
        json={
            "title": "Overdue Skier",
            "team_public_id": seeded_team.public_id,
            "location": "East Ridge",
            "notes": "Flagged by partner at 16:00.",
            "active": True,
        },
    )
    assert create.status_code == 201
    incident_public_id = create.json()["public_id"]

    listing = client.get(
        "/incidents",
        headers=auth_headers(seeded_user),
    )
    assert listing.status_code == 200
    titles = [item["title"] for item in listing.json()]
    assert "Overdue Skier" in titles

    respond = client.post(
        f"/incidents/{incident_public_id}/responses",
        headers=auth_headers(seeded_user),
        json={"status": "Responding", "source": "mobile", "rank": 2},
    )
    assert respond.status_code == 201

    follow_up = client.get(
        "/incidents",
        headers=auth_headers(seeded_user),
    )
    incidents = {item["public_id"]: item for item in follow_up.json()}
    new_incident = incidents[incident_public_id]
    response_users = [r["user_public_id"] for r in new_incident["responses"]]
    assert seeded_user.public_id in response_users


def test_incident_delete_cascades_response_records(db_session, seeded_incident, seeded_user):
    assert (
        db_session.query(ResponseRecord)
        .filter_by(incident_id=seeded_incident.id)
        .count()
        == 1
    )

    incident_id = seeded_incident.id
    db_session.delete(seeded_incident)
    db_session.commit()

    assert db_session.query(Incident).filter_by(id=incident_id).count() == 0
    assert (
        db_session.query(ResponseRecord).filter_by(incident_id=incident_id).count() == 0
    )


def test_create_incident_writes_created_and_paged_events(
    client, db_session, seeded_user, seeded_team, seeded_device, seeded_web_push_subscription, auth_headers
):
    create = client.post(
        "/incidents",
        headers=auth_headers(seeded_user),
        json={
            "title": "Flash Flood Watch",
            "team_public_id": seeded_team.public_id,
            "location": "South Fork",
            "notes": "",
            "active": True,
        },
    )
    assert create.status_code == 201
    incident_public_id = create.json()["public_id"]
    incident = db_session.query(Incident).filter_by(public_id=incident_public_id).one()

    # version 1 = incident.created, version 2 = incident.paged (dispatchers).
    assert incident.version == 2

    events = (
        db_session.query(IncidentEvent)
        .filter_by(incident_id=incident.id)
        .order_by(IncidentEvent.version.asc())
        .all()
    )
    assert [(e.version, e.event_type, e.page_group) for e in events] == [
        (1, "incident.created", None),
        (2, "incident.paged", "dispatchers"),
    ]
    assert events[0].payload["incident_public_id"] == incident.public_id
    assert events[0].payload["team_public_id"] == seeded_team.public_id

    # Push deliveries are tied to the paged event and target dispatchers.
    # seeded_user has role=team_admin, which is part of the dispatcher group.
    deliveries = (
        db_session.query(PushDelivery).filter_by(incident_id=incident.id).all()
    )
    assert len(deliveries) == 2
    assert {d.event_type for d in deliveries} == {"incident.paged"}
    channels = sorted(d.channel for d in deliveries)
    assert channels == ["mobile", "web_push"]
    mobile = next(d for d in deliveries if d.channel == "mobile")
    web = next(d for d in deliveries if d.channel == "web_push")
    assert mobile.device_id == seeded_device.id
    assert mobile.web_push_subscription_id is None
    assert web.web_push_subscription_id == seeded_web_push_subscription.id
    assert web.device_id is None


def test_update_incident_default_pages_responders(
    client, db_session, seeded_user, seeded_incident, seeded_device,
    seeded_web_push_subscription, auth_headers,
):
    incident_public_id = seeded_incident.public_id

    response = client.patch(
        f"/incidents/{incident_public_id}",
        headers=auth_headers(seeded_user),
        json={
            "title": "Updated Title",
            "location": "Updated Location",
            "notes": "Updated notes",
            "active": False,
        },
    )
    assert response.status_code == 200

    db_session.refresh(seeded_incident)
    # seeded_incident starts at version 1 (model default, fixture-created).
    # Update bumps to 2 (incident.updated), then default page bumps to 3.
    assert seeded_incident.version == 3

    events = (
        db_session.query(IncidentEvent)
        .filter_by(incident_id=seeded_incident.id)
        .order_by(IncidentEvent.version.asc())
        .all()
    )
    assert [(e.version, e.event_type, e.page_group) for e in events] == [
        (2, "incident.updated", None),
        (3, "incident.paged", "responder"),
    ]
    assert events[0].payload["title"] == "Updated Title"
    assert events[0].payload["active"] is False

    deliveries = (
        db_session.query(PushDelivery).filter_by(incident_id=seeded_incident.id).all()
    )
    assert len(deliveries) == 2
    assert {d.event_type for d in deliveries} == {"incident.paged"}


def test_update_incident_with_dispatchers_page_group(
    client, db_session, seeded_user, seeded_incident, seeded_device,
    seeded_web_push_subscription, auth_headers,
):
    response = client.patch(
        f"/incidents/{seeded_incident.public_id}",
        headers=auth_headers(seeded_user),
        json={
            "title": seeded_incident.title,
            "location": seeded_incident.location,
            "notes": "Dispatcher-only update",
            "active": True,
            "page_group": "dispatchers",
        },
    )
    assert response.status_code == 200

    events = (
        db_session.query(IncidentEvent)
        .filter_by(incident_id=seeded_incident.id)
        .order_by(IncidentEvent.version.asc())
        .all()
    )
    page_event = events[-1]
    assert page_event.event_type == "incident.paged"
    assert page_event.page_group == "dispatchers"

    deliveries = (
        db_session.query(PushDelivery).filter_by(incident_id=seeded_incident.id).all()
    )
    # seeded_user is admin → still targeted under dispatchers filter.
    assert len(deliveries) == 2


def test_update_incident_with_null_page_group_skips_paging(
    client, db_session, seeded_user, seeded_incident, seeded_device,
    seeded_web_push_subscription, auth_headers,
):
    response = client.patch(
        f"/incidents/{seeded_incident.public_id}",
        headers=auth_headers(seeded_user),
        json={
            "title": seeded_incident.title,
            "location": seeded_incident.location,
            "notes": "Silent update.",
            "active": True,
            "page_group": None,
        },
    )
    assert response.status_code == 200

    events = (
        db_session.query(IncidentEvent)
        .filter_by(incident_id=seeded_incident.id)
        .order_by(IncidentEvent.version.asc())
        .all()
    )
    assert [(e.version, e.event_type) for e in events] == [(2, "incident.updated")]

    deliveries = (
        db_session.query(PushDelivery).filter_by(incident_id=seeded_incident.id).all()
    )
    assert deliveries == []


def test_create_then_update_yields_four_event_versions(
    client, db_session, seeded_user, seeded_team, auth_headers
):
    create = client.post(
        "/incidents",
        headers=auth_headers(seeded_user),
        json={
            "title": "Two Hops",
            "team_public_id": seeded_team.public_id,
            "location": "Ridge",
            "notes": "",
            "active": True,
        },
    )
    assert create.status_code == 201
    incident_public_id = create.json()["public_id"]

    update = client.patch(
        f"/incidents/{incident_public_id}",
        headers=auth_headers(seeded_user),
        json={
            "title": "Two Hops",
            "location": "Ridge",
            "notes": "Status update.",
            "active": True,
        },
    )
    assert update.status_code == 200

    incident = db_session.query(Incident).filter_by(public_id=incident_public_id).one()
    versions = (
        db_session.query(IncidentEvent.version, IncidentEvent.event_type, IncidentEvent.page_group)
        .filter_by(incident_id=incident.id)
        .order_by(IncidentEvent.version.asc())
        .all()
    )
    assert versions == [
        (1, "incident.created", None),
        (2, "incident.paged", "dispatchers"),
        (3, "incident.updated", None),
        (4, "incident.paged", "responder"),
    ]
