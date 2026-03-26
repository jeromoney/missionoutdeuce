# MissionOut

MissionOut is organized into two implementation areas and two contract layers:

- `backend/` for the FastAPI API and persistence layer
- `UserInterface/` for Flutter client applications and UI-only shared packages
- `contracts/` for the machine-readable API contract
- `docs/` for human-readable boundary, workflow, and data semantics

## Boundary Rule

Backend and UI only talk to each other through the shared contract.
That contract has two forms:

- canonical HTTP contract: [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json)
- human-readable boundary notes: [docs/api-contracts.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/api-contracts.md), [docs/data-model.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/data-model.md), and [docs/boundaries.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/boundaries.md)

Neither side should import source files from the other side.

## Layout

- `backend/`
- `UserInterface/`
- `contracts/`
- `docs/`

## Working Agreement

When a route, payload, or shared meaning changes:

1. Update backend route/schema metadata.
2. Regenerate [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json).
3. Update `docs/` if the meaning, ownership, or workflow changed.
4. Update backend and UI implementation against the exported contract.
5. Verify the contract export is current.
