import pytest

jsonschema = pytest.importorskip("jsonschema")

from app.main import app


@pytest.fixture(scope="module")
def live_spec() -> dict:
    return app.openapi()


def _deref(spec: dict, schema):
    if isinstance(schema, dict) and "$ref" in schema:
        ref = schema["$ref"]
        if ref.startswith("#/"):
            parts = ref[2:].split("/")
            node = spec
            for part in parts:
                node = node[part]
            return _deref(spec, node)
    return schema


def _resolve_schema(spec: dict, schema):
    schema = _deref(spec, schema)
    if isinstance(schema, dict):
        resolved: dict = {}
        for key, value in schema.items():
            if key == "properties" and isinstance(value, dict):
                resolved[key] = {
                    prop_name: _resolve_schema(spec, prop_schema)
                    for prop_name, prop_schema in value.items()
                }
            elif key == "items":
                resolved[key] = _resolve_schema(spec, value)
            elif key in {"allOf", "anyOf", "oneOf"} and isinstance(value, list):
                resolved[key] = [_resolve_schema(spec, item) for item in value]
            else:
                resolved[key] = value
        return resolved
    return schema


def _response_schema(spec: dict, path: str, method: str, status: str):
    operation = spec["paths"][path][method]
    response = operation.get("responses", {}).get(status, {})
    content = response.get("content", {}).get("application/json", {})
    raw = content.get("schema")
    return _resolve_schema(spec, raw) if raw is not None else None


def test_get_incidents_matches_live_schema(client, seeded_user, seeded_incident, live_spec):
    schema = _response_schema(live_spec, "/incidents", "get", "200")
    assert schema is not None

    response = client.get(
        "/incidents",
        headers={"x-missionout-user-email": seeded_user.email},
    )
    assert response.status_code == 200
    jsonschema.validate(response.json(), schema)


def test_get_team_members_matches_live_schema(client, seeded_team, seeded_user, live_spec):
    schema = _response_schema(
        live_spec, "/teams/{team_public_id}/members", "get", "200"
    )
    assert schema is not None

    response = client.get(
        f"/teams/{seeded_team.public_id}/members",
        headers={"x-missionout-user-email": seeded_user.email},
    )
    assert response.status_code == 200
    jsonschema.validate(response.json(), schema)


def test_get_delivery_feed_matches_live_schema(
    client, seeded_user, seeded_delivery_event, live_spec
):
    schema = _response_schema(live_spec, "/events/delivery-feed", "get", "200")
    assert schema is not None

    response = client.get(
        "/events/delivery-feed",
        headers={"x-missionout-user-email": seeded_user.email},
    )
    assert response.status_code == 200
    jsonschema.validate(response.json(), schema)
