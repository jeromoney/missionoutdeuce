import pytest

from app.main import app


_HTTP_METHODS = {"get", "post", "put", "patch", "delete", "options", "head"}


@pytest.fixture(scope="module")
def live_spec() -> dict:
    return app.openapi()


def _operations(spec: dict) -> set[tuple[str, str]]:
    operations: set[tuple[str, str]] = set()
    for path, methods in spec.get("paths", {}).items():
        for method in methods:
            if method.lower() in _HTTP_METHODS:
                operations.add((path, method.lower()))
    return operations


def test_committed_paths_match_live_spec(openapi_spec, live_spec):
    committed = _operations(openapi_spec)
    live = _operations(live_spec)

    missing_from_live = committed - live
    unexpected_in_live = live - committed

    assert not missing_from_live, (
        "Routes present in contracts/openapi.json but missing from the live app: "
        f"{sorted(missing_from_live)}"
    )
    assert not unexpected_in_live, (
        "Routes in the live app but missing from contracts/openapi.json — "
        f"regenerate the contract: {sorted(unexpected_in_live)}"
    )


def _response_schema(spec: dict, path: str, method: str, status: str):
    operation = spec["paths"][path][method]
    response = operation.get("responses", {}).get(status, {})
    content = response.get("content", {}).get("application/json", {})
    return content.get("schema")


def _resolve_ref(spec: dict, schema):
    if not isinstance(schema, dict):
        return schema
    if "$ref" in schema:
        ref = schema["$ref"]
        if ref.startswith("#/"):
            parts = ref[2:].split("/")
            node = spec
            for part in parts:
                node = node[part]
            return _resolve_ref(spec, node)
    return schema


def _schema_field_names(spec: dict, schema) -> set[str]:
    resolved = _resolve_ref(spec, schema)
    if not isinstance(resolved, dict):
        return set()
    if resolved.get("type") == "array":
        return _schema_field_names(spec, resolved.get("items") or {})
    return set((resolved.get("properties") or {}).keys())


def test_success_response_fields_match(openapi_spec, live_spec):
    committed_ops = _operations(openapi_spec)
    live_ops = _operations(live_spec)
    shared = sorted(committed_ops & live_ops)

    mismatches: list[str] = []
    for path, method in shared:
        for status in ("200", "201"):
            committed_schema = _response_schema(openapi_spec, path, method, status)
            live_schema = _response_schema(live_spec, path, method, status)
            if committed_schema is None and live_schema is None:
                continue
            if committed_schema is None or live_schema is None:
                mismatches.append(
                    f"{method.upper()} {path} status {status}: "
                    f"committed has schema={committed_schema is not None}, "
                    f"live has schema={live_schema is not None}"
                )
                continue
            committed_fields = _schema_field_names(openapi_spec, committed_schema)
            live_fields = _schema_field_names(live_spec, live_schema)
            if committed_fields != live_fields:
                mismatches.append(
                    f"{method.upper()} {path} status {status}: "
                    f"added={sorted(live_fields - committed_fields)} "
                    f"removed={sorted(committed_fields - live_fields)}"
                )

    assert not mismatches, "Response schema drift vs contracts/openapi.json:\n" + "\n".join(mismatches)
