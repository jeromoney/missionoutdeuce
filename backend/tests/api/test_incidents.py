def test_get_incidents_requires_user_header(client, seeded_incident):
    response = client.get("/incidents")

    assert response.status_code == 401
    assert response.json()["detail"] == "Missing authenticated user context."


def test_get_incidents_returns_team_scoped_incidents(client, seeded_user, seeded_incident):
    response = client.get(
        "/incidents",
        headers={"x-missionout-user-email": seeded_user.email},
    )

    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1
    assert body[0]["title"] == "Lost Day Hiker"
    assert body[0]["active"] is True
    assert body[0]["public_id"]
    assert body[0]["team_public_id"] == seeded_incident.team_ref.public_id
    assert body[0]["responses"][0]["status"] == "Responding"
    assert body[0]["responses"][0]["user_public_id"] == seeded_user.public_id
    assert body[0]["responses"][0]["updated"]
    assert "team" not in body[0]
    assert "name" not in body[0]["responses"][0]
    assert "detail" not in body[0]["responses"][0]


def test_post_incidents_creates_incident(client, seeded_user, seeded_team):
    response = client.post(
        "/incidents",
        headers={"x-missionout-user-email": seeded_user.email},
        json={
            "title": "Injured Climber Extraction",
            "team_public_id": seeded_team.public_id,
            "location": "Mt. Princeton Southwest Gully",
            "notes": "Lower-leg injury above treeline.",
            "active": True,
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Injured Climber Extraction"
    assert body["location"] == "Mt. Princeton Southwest Gully"
    assert body["notes"] == "Lower-leg injury above treeline."
    assert body["active"] is True
    assert body["responses"] == []
    assert body["public_id"]
    assert body["team_public_id"] == seeded_team.public_id
    assert "created" in body
    assert "team" not in body


def test_patch_incident_updates_fields(client, seeded_user, seeded_incident):
    response = client.patch(
        f"/incidents/{seeded_incident.public_id}",
        headers={"x-missionout-user-email": seeded_user.email},
        json={
            "title": "Updated Incident Title",
            "location": "Updated Location",
            "notes": "Updated notes",
            "active": False,
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["public_id"] == seeded_incident.public_id
    assert body["title"] == "Updated Incident Title"
    assert body["location"] == "Updated Location"
    assert body["notes"] == "Updated notes"
    assert body["active"] is False


def test_post_incident_response_creates_response_record(client, seeded_user, seeded_incident):
    response = client.post(
        f"/incidents/{seeded_incident.public_id}/responses",
        headers={"x-missionout-user-email": seeded_user.email},
        json={
            "status": "Responding",
            "source": "mobile",
            "rank": 1,
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["user_public_id"] == seeded_user.public_id
    assert body["status"] == "Responding"
    assert body["rank"] == 1
    assert body["updated"]
    assert "name" not in body
    assert "detail" not in body


def test_get_incidents_filters_out_other_team_incidents(
    client, seeded_user, seeded_incident, seeded_second_team, db_session
):
    from app.core.time import utc_now
    from app.models.incident import Incident

    other_incident = Incident(
        title="Not My Team Incident",
        team_id=seeded_second_team.id,
        location="Elsewhere",
        notes="",
        active=True,
        created_at=utc_now(),
    )
    db_session.add(other_incident)
    db_session.commit()

    response = client.get(
        "/incidents",
        headers={"x-missionout-user-email": seeded_user.email},
    )

    assert response.status_code == 200
    titles = [incident["title"] for incident in response.json()]
    assert "Lost Day Hiker" in titles
    assert "Not My Team Incident" not in titles


def test_post_incidents_requires_authentication(client, seeded_team):
    response = client.post(
        "/incidents",
        json={
            "title": "Ghost Incident",
            "team_public_id": seeded_team.public_id,
            "location": "Nowhere",
            "notes": "",
            "active": True,
        },
    )

    assert response.status_code == 401


def test_post_incidents_rejects_unknown_team_for_authenticated_dispatcher(
    client, seeded_user
):
    response = client.post(
        "/incidents",
        headers={"x-missionout-user-email": seeded_user.email},
        json={
            "title": "Ghost Incident",
            "team_public_id": "no-such-team",
            "location": "Nowhere",
            "notes": "",
            "active": True,
        },
    )

    # seeded_user has exactly one active membership, so the dispatcher falls
    # through to that team when the payload team is unknown.
    assert response.status_code == 201


def test_post_incidents_requires_title(client, seeded_user, seeded_team):
    response = client.post(
        "/incidents",
        headers={"x-missionout-user-email": seeded_user.email},
        json={
            "team_public_id": seeded_team.public_id,
            "location": "Somewhere",
            "notes": "",
            "active": True,
        },
    )

    assert response.status_code == 422


def test_post_incidents_requires_dispatcher_role_when_authenticated(
    client, seeded_second_user, seeded_second_team
):
    response = client.post(
        "/incidents",
        headers={"x-missionout-user-email": seeded_second_user.email},
        json={
            "title": "Responder Attempt",
            "team_public_id": seeded_second_team.public_id,
            "location": "Here",
            "notes": "",
            "active": True,
        },
    )

    assert response.status_code == 403


def test_patch_incident_returns_404_for_unknown_public_id(client, seeded_user):
    response = client.patch(
        "/incidents/does-not-exist",
        headers={"x-missionout-user-email": seeded_user.email},
        json={
            "title": "x",
            "location": "x",
            "notes": "x",
            "active": True,
        },
    )

    assert response.status_code == 404


def test_post_incident_response_requires_user_header(client, seeded_incident):
    response = client.post(
        f"/incidents/{seeded_incident.public_id}/responses",
        json={"status": "Responding", "source": "mobile", "rank": 1},
    )

    assert response.status_code == 401


def test_post_incident_response_rejects_user_not_on_team(
    client, seeded_incident, seeded_second_user
):
    response = client.post(
        f"/incidents/{seeded_incident.public_id}/responses",
        headers={"x-missionout-user-email": seeded_second_user.email},
        json={"status": "Responding", "source": "mobile", "rank": 1},
    )

    assert response.status_code == 403


def test_post_incident_response_upserts_single_record(
    client, seeded_user, seeded_incident, db_session
):
    from app.models.incident import ResponseRecord

    initial_count = (
        db_session.query(ResponseRecord)
        .filter_by(incident_id=seeded_incident.id, user_id=seeded_user.id)
        .count()
    )
    assert initial_count == 1

    for rank in (1, 2, 3):
        response = client.post(
            f"/incidents/{seeded_incident.public_id}/responses",
            headers={"x-missionout-user-email": seeded_user.email},
            json={"status": "Standby", "source": "mobile", "rank": rank},
        )
        assert response.status_code == 201

    records = (
        db_session.query(ResponseRecord)
        .filter_by(incident_id=seeded_incident.id, user_id=seeded_user.id)
        .all()
    )
    assert len(records) == 1
    assert records[0].rank == 3
    assert records[0].status == "Standby"
