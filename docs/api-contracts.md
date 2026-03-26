# MissionOut API Contracts

This document explains the contract boundary between:

- `backend/`
- `UserInterface/dispatcher/`
- `UserInterface/team_admin/`
- `UserInterface/responder/`

The canonical machine-readable contract lives in [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json).
This file exists to explain the intent, ownership, and usage of that contract alongside [data-model.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/data-model.md).

## Principles

- Backend responses should be stable, explicit, and exported into `contracts/openapi.json`.
- Field names should be consistent across clients.
- UI clients should not invent alternate schema shapes when the contract already exists.
- Backend implementation details should not leak into UI code.
- Dispatcher and Team Management clients should share the same backend API while enforcing different permissions.
- A route change is not complete until the exported OpenAPI contract is regenerated.

## Contract-First Workflow

1. Propose or implement the route/schema change in FastAPI metadata.
2. Regenerate [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json).
3. Review the contract diff.
4. Update UI code and backend implementation to satisfy the new contract.
5. Update this document only when semantics, examples, or guidance need clarification.

## Current Route Summary

The full request and response schema, status codes, and component definitions are in [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json).
This section is a quick human summary of the routes the clients currently rely on.

## `POST /auth/google`

Purpose:

- Exchange a Google ID token for a verified MissionOut user payload.

Request shape:

```json
{
  "id_token": "google-id-token",
  "requested_client": "responder"
}
```

Response shape:

```json
{
  "name": "Justin Mercer",
  "initials": "JM",
  "global_permissions": [],
  "team_memberships": [
    {
      "team_id": 7,
      "team_name": "Chaffee SAR",
      "roles": ["responder", "dispatcher"]
    }
  ],
  "email": "justin@example.com"
}
```

Notes:

- Authentication should return the caller's effective memberships and roles, not collapse them into a single role string.
- Client selection such as `responder`, `dispatcher`, or `team_admin` determines the requested app surface, not the full authorization set.
- The `team_admin` client surface represents the Team Management app, not a global admin console.

## `GET /health`

Purpose:

- Basic service health check.

Response:

```json
{
  "status": "ok",
  "database": "connected"
}
```

## `GET /incidents`

Purpose:

- Returns incidents for the dispatcher board and authorized team-management or super-admin views.

Response shape:

```json
[
  {
    "id": 42,
    "title": "Injured Climber Extraction",
    "team": "Chaffee SAR",
    "location": "Mt. Princeton Southwest Gully",
    "created": "8 min ago",
    "notes": "Subject reports lower-leg injury above treeline.",
    "active": true,
    "responses": [
      {
        "name": "Justin M.",
        "status": "Responding",
        "detail": "En route from Buena Vista with litter trailer.",
        "rank": 0
      }
    ]
  }
]
```

Field definitions:

- `id`: numeric incident identifier
- `title`: short incident name
- `team`: primary responsible team
- `location`: human-readable location
- `created`: formatted client-facing time label
- `notes`: dispatcher notes
- `active`: incident active/resolved state
- `responses`: ordered responder states

## `GET /events/delivery-feed`

Purpose:

- Returns operational event feed items for the dispatcher interface and authorized team-management or super-admin views.

Response shape:

```json
[
  {
    "title": "Primary FCM burst completed",
    "detail": "12 Android devices received the first-wave push.",
    "time": "2m",
    "icon": "notifications",
    "color": "#4F6F95"
  }
]
```

Field definitions:

- `title`: short event label
- `detail`: explanatory event message
- `time`: formatted time label
- `icon`: icon key understood by clients
- `color`: UI hint color

## `POST /incidents`

Purpose:

- Create a new incident from the dispatcher web UI.

Request shape:

```json
{
  "title": "Injured Climber Extraction",
  "team": "Chaffee SAR",
  "location": "Mt. Princeton Southwest Gully",
  "notes": "Subject reports lower-leg injury above treeline.",
  "active": true
}
```

Response shape:

```json
{
  "id": 42,
  "title": "Injured Climber Extraction",
  "team": "Chaffee SAR",
  "location": "Mt. Princeton Southwest Gully",
  "created": "Just now",
  "notes": "Subject reports lower-leg injury above treeline.",
  "active": true,
  "responses": []
}
```

## `PATCH /incidents/{id}`

Purpose:

- Update incident details such as title, location, notes, or active status.

Request shape:

```json
{
  "title": "Updated Incident Title",
  "location": "Updated Location",
  "notes": "Updated notes",
  "active": true
}
```

Response shape:

```json
{
  "id": 42,
  "title": "Updated Incident Title",
  "team": "Chaffee SAR",
  "location": "Updated Location",
  "created": "8 min ago",
  "notes": "Updated notes",
  "active": true,
  "responses": []
}
```

## `POST /incidents/{id}/responses`

Purpose:

- Update a responder's incident-specific state.

Suggested request:

```json
{
  "status": "Responding",
  "detail": "15 minutes out"
}
```

Suggested response:

- updated response record
- or updated incident, depending on chosen backend pattern

## Planned Team Management Routes

These routes are not fully defined in the current scaffold but should remain on the same API surface as dispatcher and responder routes.

Recommended team-scoped capabilities:

- `GET /teams/{team_id}/members`
  Returns team membership records for Team Management and Super Admin workflows.
- `POST /teams/{team_id}/members`
  Creates or invites a user into a team and assigns one or more team-scoped roles.
- `PATCH /teams/{team_id}/members/{membership_id}`
  Updates membership state such as active status or assigned roles.
- `GET /teams/{team_id}/devices`
  Returns device health and registration visibility for team-management workflows.

Guidance:

- Team Management routes should support create, invite, activate, and deactivate flows for one existing team.
- Team Management routes should avoid destructive hard-delete semantics for users with operational history.
- Team Management routes should not create teams or perform global administration.
- Dispatcher permissions should not imply Team Admin access, and Team Admin permissions should not imply dispatch access.

## Realtime Contract

Recommended future event types:

- `incident.created`
- `incident.updated`
- `incident.response_changed`
- `incident.resolved`
- `delivery.event`
- `team.membership_changed`

Suggested payload shape:

```json
{
  "type": "incident.updated",
  "incident_id": 42,
  "data": {
    "title": "Updated Incident Title",
    "location": "Updated Location",
    "notes": "Updated notes",
    "active": true
  }
}
```

## Ownership

- [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json) owns the cross-stack HTTP contract.
- Backend owns validation and persistence behind the contract and exports the OpenAPI artifact.
- `UserInterface/dispatcher/`, `UserInterface/team_admin/`, and `UserInterface/responder/` should mirror these contracts in their client models.
- `UserInterface/team_admin/` is the Team Management app for Team Admin users.
- This document should be updated whenever the semantics, examples, or workflow guidance change in a meaningful way.
