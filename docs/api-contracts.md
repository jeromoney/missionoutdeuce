# MissionOut API Contracts

This document describes the shared API contract between:

- `admin_web/`
- `responder/`
- `backend/`

The backend implementation is authoritative, but this document should stay aligned with the real routes and schemas.

## Principles

- Backend responses should be stable and explicit.
- Field names should be consistent across clients.
- Clients should avoid inventing alternate schema shapes when the backend contract already exists.

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

## Planned Routes

These are recommended next contracts for the current UI work.

## `POST /incidents`

Purpose:

- Create a new incident from the admin dispatcher UI.

Suggested request:

```json
{
  "title": "Injured Climber Extraction",
  "team": "Chaffee SAR",
  "location": "Mt. Princeton Southwest Gully",
  "notes": "Subject reports lower-leg injury above treeline.",
  "active": true
}
```

Suggested response:

- return the created incident in the same shape used by `GET /incidents`

## `PATCH /incidents/{id}`

Purpose:

- Update incident details such as title, location, notes, or active status.

Suggested request:

```json
{
  "title": "Updated Incident Title",
  "location": "Updated Location",
  "notes": "Updated notes",
  "active": true
}
```

Suggested response:

- return the updated incident in the same shape used by `GET /incidents`

## `POST /incidents/{id}/responses`

Purpose:

- Update a responder’s incident-specific state.

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

- Backend owns API truth and validation.
- `admin_web/` and `responder/` should mirror backend contracts in their Dart models.
- This document should be updated whenever route shapes change in a meaningful way.
