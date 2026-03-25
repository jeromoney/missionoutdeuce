# MissionOut Boundaries

MissionOut is organized around a hard boundary:

- `backend/` owns persistence, validation, and HTTP delivery
- `UserInterface/` owns user-facing experiences and client-side state
- `docs/` is the only shared contract surface between them

## Rules

- Backend and UI communicate only through documented HTTP contracts.
- Cross-stack field names, route paths, and entity meanings belong in `docs/`.
- Internal code structure on either side is private unless it is explicitly documented as part of a contract.
- When a contract changes, update `docs/` before or alongside implementation changes.

## What Belongs In Docs

- Route paths and methods
- Request and response payloads
- Shared entity definitions
- Allowed enum values and status meanings
- Realtime event names and payloads

## What Does Not Belong In Docs

- Backend ORM internals
- Flutter widget structure
- Styling details
- Database migration mechanics
- Client-only presentation helpers

## Change Flow

1. Update the relevant file in `docs/`.
2. Update backend schemas and routes to match.
3. Update UI models and API clients to match.
4. Verify both sides still agree on the documented contract.