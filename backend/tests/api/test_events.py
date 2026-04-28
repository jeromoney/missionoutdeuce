from datetime import timedelta

from app.core.time import utc_now
from app.models.event import DeliveryEvent
from app.models.team_management import User


def test_get_delivery_feed_empty(client, seeded_user, auth_headers):
    response = client.get(
        "/events/delivery-feed",
        headers=auth_headers(seeded_user),
    )

    assert response.status_code == 200
    assert response.json() == []


def test_get_delivery_feed_returns_events_ordered_desc(client, seeded_user, db_session, auth_headers):
    now = utc_now()
    older = DeliveryEvent(
        title="Older event",
        detail="Earlier delivery",
        time_label="10m",
        icon="notifications",
        color="#4F6F95",
        created_at=now - timedelta(minutes=10),
    )
    newer = DeliveryEvent(
        title="Newer event",
        detail="Later delivery",
        time_label="1m",
        icon="task_alt",
        color="#3F6D91",
        created_at=now - timedelta(minutes=1),
    )
    db_session.add_all([older, newer])
    db_session.commit()

    response = client.get(
        "/events/delivery-feed",
        headers=auth_headers(seeded_user),
    )

    assert response.status_code == 200
    body = response.json()
    assert [item["title"] for item in body] == ["Newer event", "Older event"]
    assert set(body[0].keys()) == {"title", "detail", "time", "icon", "color"}


def test_get_events_stream_requires_user_header(client):
    response = client.get("/events/stream")

    assert response.status_code == 401


def test_get_events_stream_rejects_inactive_user(client, db_session, seeded_user, auth_headers):
    headers = auth_headers(seeded_user)
    seeded_user.is_active = False
    db_session.commit()

    response = client.get("/events/stream", headers=headers)

    assert response.status_code == 401


def test_get_events_stream_rejects_user_without_active_teams(client, db_session, auth_headers):
    user = User(
        name="Solo Sam",
        email="solo@gmail.com",
        phone="",
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    response = client.get("/events/stream", headers=auth_headers(user))

    assert response.status_code == 403
