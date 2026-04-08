# Backend Scope

This directory is owned by the Backend API thread.

## Purpose

Own backend, API, database, and worker-side application logic.

## Responsibilities

- FastAPI routes
- authentication and authorization
- database schema and persistence models
- OpenAPI contract generation
- backend alert targeting and delivery behavior
- worker-facing backend logic
- backend tests under `tests/`

## Constraints

- Do not redesign frontend UI here.
- Do not treat deployment or DNS work as backend work unless the task explicitly requires backend configuration changes.
- Keep internal database integer IDs backend-only.
- Expose `public_id` values at the API boundary for external resources.
- Route or payload changes are not complete until `contracts/openapi.json` is regenerated.

## Adjacent Ownership

- Frontend product work belongs in `../UserInterface/`
- Website work belongs in `../website/`
- Cross-stack semantics belong in `../docs/`

## Testing Rule

- Prefer backend API tests first for new routes.
- Keep test coverage in `tests/unit/`, `tests/api/`, `tests/integration/`, and `tests/contract/` as the suite grows.
