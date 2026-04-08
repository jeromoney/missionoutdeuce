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
    assert body[0]["team"] == "Cinder Valley Rescue"
    assert body[0]["active"] is True
    assert body[0]["responses"][0]["status"] == "Responding"


def test_post_incidents_creates_incident(client, seeded_team):
    response = client.post(
        "/incidents",
        json={
            "title": "Injured Climber Extraction",
            "team": seeded_team.name,
            "location": "Mt. Princeton Southwest Gully",
            "notes": "Lower-leg injury above treeline.",
            "active": True,
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Injured Climber Extraction"
    assert body["team"] == seeded_team.name
    assert body["location"] == "Mt. Princeton Southwest Gully"
    assert body["notes"] == "Lower-leg injury above treeline."
    assert body["active"] is True
    assert body["responses"] == []
    assert "id" in body
    assert "created" in body


def test_patch_incident_updates_fields(client, seeded_incident):
    response = client.patch(
        f"/incidents/{seeded_incident.id}",
        json={
            "title": "Updated Incident Title",
            "location": "Updated Location",
            "notes": "Updated notes",
            "active": False,
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == seeded_incident.id
    assert body["title"] == "Updated Incident Title"
    assert body["location"] == "Updated Location"
    assert body["notes"] == "Updated notes"
    assert body["active"] is False


def test_post_incident_response_creates_response_record(client, seeded_incident):
    response = client.post(
        f"/incidents/{seeded_incident.id}/responses",
        json={
            "name": "Pat R.",
            "status": "Responding",
            "detail": "15 minutes out",
            "rank": 1,
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["name"] == "Pat R."
    assert body["status"] == "Responding"
    assert body["detail"] == "15 minutes out"
    assert body["rank"] == 1
