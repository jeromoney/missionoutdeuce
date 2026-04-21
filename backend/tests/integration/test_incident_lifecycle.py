from app.models.incident import Incident, ResponseRecord


def test_create_incident_then_see_it_then_respond(client, seeded_user, seeded_team):
    create = client.post(
        "/incidents",
        headers={"x-missionout-user-email": seeded_user.email},
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
        headers={"x-missionout-user-email": seeded_user.email},
    )
    assert listing.status_code == 200
    titles = [item["title"] for item in listing.json()]
    assert "Overdue Skier" in titles

    respond = client.post(
        f"/incidents/{incident_public_id}/responses",
        headers={"x-missionout-user-email": seeded_user.email},
        json={"status": "Responding", "source": "mobile", "rank": 2},
    )
    assert respond.status_code == 201

    follow_up = client.get(
        "/incidents",
        headers={"x-missionout-user-email": seeded_user.email},
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
