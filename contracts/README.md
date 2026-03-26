# MissionOut Contracts

`contracts/` is the machine-readable boundary between `backend/` and `UserInterface/`.

## Source Of Truth

- `openapi.json`
  Canonical HTTP contract generated from the FastAPI app.

## Working Rules

1. Change the backend schema or route metadata intentionally.
2. Regenerate `openapi.json`.
3. Update the human-readable notes in `docs/` if semantics or workflow guidance changed.
4. Update frontend and backend implementation against the regenerated contract.

Neither side should depend on the other side's internal source layout.
The integration surface is the versioned contract in this folder.
