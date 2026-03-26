# MissionOut Boundaries

MissionOut is organized around a hard boundary:

- `backend/` owns persistence, validation, and HTTP delivery
- `UserInterface/` owns user-facing experiences and client-side state
- `contracts/` owns the machine-readable API contract
- `docs/` owns the human-readable explanation of that contract

## Rules

- Backend and UI communicate only through the shared contract.
- Cross-stack route paths and payload shapes belong in [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json).
- Cross-stack field meanings, ownership rules, and workflow expectations belong in `docs/`.
- Internal code structure on either side is private unless it is explicitly documented as part of a contract.
- When a contract changes, regenerate `contracts/openapi.json` before or alongside implementation changes.

## What Belongs In Docs

- Shared entity definitions
- Allowed enum values and status meanings
- Realtime event names and payloads
- Ownership and change-management rules

## What Belongs In Contracts

- Route paths and methods
- Request and response payload shapes
- Response status codes
- Schema definitions used by multiple endpoints

## What Does Not Belong In Docs

- Backend ORM internals
- Flutter widget structure
- Styling details
- Database migration mechanics
- Client-only presentation helpers

## Change Flow

1. Update backend schemas and route metadata intentionally.
2. Regenerate [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json).
3. Update the relevant file in `docs/` if semantics or workflow changed.
4. Update UI models and API clients to match.
5. Verify the exported contract is current.
