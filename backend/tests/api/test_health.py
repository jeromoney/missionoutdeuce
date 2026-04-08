def test_get_root_returns_meta(client):
    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "name": "MissionOut API",
        "status": "ok",
        "health": "/health",
        "docs": "/docs",
    }


def test_get_health_returns_ok(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "database": "connected",
    }
