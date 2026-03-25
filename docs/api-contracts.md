# MissionOut API Contracts

This document is the contract boundary between:

- `backend/`
- `UserInterface/dispatcher/`
- `UserInterface/responder/`

The backend and UI should only coordinate through the contracts documented here and in [data-model.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/data-model.md).
Changes to routes, payloads, or meanings should be proposed here first and then implemented on both sides.

## Principles

- Backend responses should be stable and explicit.
- Field names should be consistent across clients.
- UI clients should not invent alternate schema shapes when the contract already exists.
- Backend implementation details should not leak into UI code.
- A route is not complete until this document reflects its request and response shape.

## Current Routes

## `POST /auth/google`

Purpose:

- Exchange a Google ID token for a verified MissionOut user payload.

Request shape:

```json
{
  "id_token": "google-id-token",
  "requested_role": "Responder"
}
```

Response shape:

```json
{
  "name": "Justin Mercer",
  "initials": "JM",
  "role": "Responder",
  "email": "justin@example.com"
}
```

## `GET /health`

Purpose:

- Basic service health check.

Response:

```json
{
  "status": "ok"
}
```

## `GET /incidents`

Purpose:

- Returns incidents for the dispatcher/admin board.

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

- Returns operational event feed items for the dispatcher/admin interface.

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

- Create a new incident from the admin dispatcher UI.

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

## Realtime Contract

Recommended future event types:

- `incident.created`
- `incident.updated`
- `incident.response_changed`
- `incident.resolved`
- `delivery.event`

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

- This document owns the cross-stack contract.
- Backend owns validation and persistence behind the contract.
- `UserInterface/dispatcher/` and `UserInterface/responder/` should mirror these contracts in their Dart models.
- This document should be updated whenever route shapes change in a meaningful way.