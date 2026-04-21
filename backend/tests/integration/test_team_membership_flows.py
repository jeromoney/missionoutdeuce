from datetime import timedelta

from app.core.time import utc_now
from app.models.team_management import Device, TeamMembership


def test_add_then_deactivate_member_blocks_incidents_access(
    client, seeded_team, db_session
):
    create = client.post(
        f"/teams/{seeded_team.public_id}/members",
        json={
            "name": "Ada Kepler",
            "email": "ada@gmail.com",
            "phone": "555-3003",
            "roles": ["responder"],
            "is_active": True,
        },
    )
    assert create.status_code == 201
    membership_public_id = create.json()["public_id"]

    members = client.get(f"/teams/{seeded_team.public_id}/members")
    emails = [m["email"] for m in members.json()]
    assert "ada@gmail.com" in emails

    working = client.get("/incidents", headers={"x-missionout-user-email": "ada@gmail.com"})
    assert working.status_code == 200

    deactivate = client.patch(
        f"/teams/{seeded_team.public_id}/members/{membership_public_id}",
        json={"is_active": False},
    )
    assert deactivate.status_code == 200

    blocked = client.get("/incidents", headers={"x-missionout-user-email": "ada@gmail.com"})
    assert blocked.status_code == 401


def test_user_device_surfaces_in_team_device_listing(
    client, seeded_team, seeded_user, db_session
):
    device = Device(
        user_id=seeded_user.id,
        platform="android",
        push_token="team-device-token",
        last_seen=utc_now() - timedelta(minutes=5),
        is_active=True,
        is_verified=True,
    )
    db_session.add(device)
    db_session.commit()

    response = client.get(f"/teams/{seeded_team.public_id}/devices")

    assert response.status_code == 200
    tokens = [d["push_token"] for d in response.json()]
    assert "team-device-token" in tokens
