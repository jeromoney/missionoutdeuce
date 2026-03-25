# MissionOut

MissionOut is organized into two implementation areas and one shared contract area:

- `backend/` for the API and persistence layer
- `UserInterface/` for Flutter client applications and UI-only shared packages
- `docs/` for the contract both sides use to coordinate

## Boundary Rule

Backend and UI only talk to each other through the documents in `docs/`.
That means:

- route shapes live in [docs/api-contracts.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/api-contracts.md)
- shared entity definitions live in [docs/data-model.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/data-model.md)
- boundary expectations live in [docs/boundaries.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/boundaries.md)

## Layout

- `backend/`
- `UserInterface/`
- `docs/`

## Working Agreement

When a backend route or a UI expectation changes:

1. Update `docs/`.
2. Update backend implementation.
3. Update UI implementation.
4. Verify both still match.