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
- MissionOut should be modeled as an interrupt-driven system with long idle periods, not as a continuous operational queue.

## Product Mode Split

- The dispatcher app initiates the interrupt loop by creating incidents and starting delivery fanout.
- The responder experience is mostly idle until a mission arrives, then shifts into a high-urgency action state.
- The Team Management app is administrative and outside the live dispatch interrupt loop.
- Contract choices should preserve this separation: operational routes belong to dispatch and response, while administrative routes belong to readiness and roster management.

## Contract-First Workflow

1. Propose or implement the route/schema change in FastAPI metadata.
2. Regenerate [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json).
3. Review the contract diff.
4. Update UI code and backend implementation to satisfy the new contract.
5. Update this document only when semantics, examples, or guidance need clarification.

## Current Route Summary

The full request and response schema, status codes, and component definitions are in [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json).
This section is a quick human summary of the routes the clients currently rely on.

## `POST /auth/email-code`

Purpose:

- Start email-based sign-in by asking the backend to send a one-time code to the user's email address.

Request shape:

```json
{
  "email": "justin@example.com",
  "requested_client": "responder"
}
```

Response shape:

```json
{
  "delivery": "email_code",
  "email": "justin@example.com",
  "expires_in_minutes": 15,
  "code_length": 6,
  "message": "If the email is allowed to sign in, a one-time code has been sent."
}
```

Notes:

- This route initiates sign-in but does not return the authenticated user payload yet.
- The backend is responsible for generating and emailing the one-time code.
- The email flow should use the same `requested_client` concept as other auth entry points so the correct app surface can continue sign-in after code entry.

## `POST /auth/email-code/verify`

Purpose:

- Complete email-based sign-in by exchanging the one-time code from the emailed message for the authenticated MissionOut user payload.

Request shape:

```json
{
  "email": "justin@example.com",
  "code": "123456"
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

- The code is expected to be short-lived and single-use.
- Once verified, this route returns the same authenticated user shape as other successful auth flows.
- If the code is expired, malformed, or already consumed, the backend should reject the verification attempt.

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

- Users may authenticate with either email-code sign-in or Google auth.
- Authentication should return the caller's effective memberships and roles, not collapse them into a single role string.
- Client selection such as `responder`, `dispatcher`, or `team_admin` determines the requested app surface, not the full authorization set.
- The `team_admin` client surface represents the Team Management app, not a global admin console.

## Email-Code Flow

1. The client calls `POST /auth/email-code` with the user's email address and requested client surface.
2. The backend generates a short-lived one-time code and sends that code by email.
3. The user reads the code from their email app.
4. The client submits the email address and code to `POST /auth/email-code/verify`.
5. The backend validates the code, resolves the user identity and memberships, and returns the authenticated user payload.

## Multi-Client Routing

- `requested_client` selects the intended MissionOut surface such as `responder`, `dispatcher`, or `team_admin`.
- Because the email flow uses code entry rather than a link callback, it is less dependent on the user opening email in the same browser or on the same device.
- The same email and code can be entered into the intended authorized MissionOut client surface, subject to expiry and single-use validation.

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
- The collection is limited to incidents created within the last 7 calendar days.
- Team scope is derived from the signed-in user's authenticated memberships and permissions, not from a client-supplied team identifier.

Query parameters:

- None. Clients call `GET /incidents` without a `team_id` filter.

Response shape:

```json
[
  {
    "id": 42,
    "title": "Injured Climber Extraction",
    "team": "Chaffee SAR",
    "location": "Mt. Princeton Southwest Gully",
    "created": "2026-03-26T17:24:41.760280",
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
- `team`: primary responsible team display name
- `location`: human-readable location
- `created`: canonical incident creation timestamp
- `notes`: dispatcher notes
- `active`: incident active/resolved state
- `responses`: ordered responder states

Backend note:

- Incidents are normalized to a team foreign key in backend storage, while the API continues returning `team` as the display name for client compatibility.
- `GET /incidents` is intentionally a recent-activity feed, not a full historical export. Older incidents fall out of this route once their `created` timestamp is more than 7 calendar days old.
- The backend should derive team visibility from the authenticated user's memberships and global permissions. Clients should not send a team selector for this route.

## `GET /events/delivery-feed`

Purpose:

- Returns operational event feed items for the dispatcher interface and authorized team-management or super-admin views.

Response shape:

```json
[
  {
    "title": "Primary FCM burst completed",
    "detail": "12 Android devices received the first-wave push.",
    "time": "2026-03-26T17:24:41.755484",
    "icon": "notifications",
    "color": "#4F6F95"
  }
]
```

Field definitions:

- `title`: short event label
- `detail`: explanatory event message
- `time`: canonical event timestamp
- `icon`: icon key understood by clients
- `color`: UI hint color

## `GET /events/stream`

Purpose:

- Provides a supplemental Server-Sent Events stream for open web clients.
- Supports lightweight browser alert testing and live dispatcher updates while the web app tab is already open.
- Does not replace native mobile alert delivery or future browser push for closed tabs.

Transport:

- `text/event-stream`
- one-way backend-to-client updates over SSE

Suggested event types:

- `incident.created`
- `incident.updated`
- `incident.response_changed`
- `delivery.event`

Suggested event shape:

```text
event: incident.created
data: {"incident_id":42,"team_id":1,"title":"Injured Climber Extraction","created":"2026-03-26T17:24:41.760280"}
```

Guidance:

- This endpoint is intended as a simple open-tab alert path for testing and supplemental awareness.
- Clients should reconnect when the stream drops and refresh authoritative state from standard REST routes as needed.
- If the page is closed, this stream stops. Future closed-tab browser notifications should use Web Push and a service worker instead.

## `POST /devices/web-push`

Purpose:

- Registers or refreshes a browser push subscription for the authenticated user.
- Stores the subscription endpoint and encryption keys needed for future Web Push delivery when the page is closed.

Suggested request shape:

```json
{
  "endpoint": "https://fcm.googleapis.com/fcm/send/abc123",
  "keys": {
    "p256dh": "base64-p256dh-key",
    "auth": "base64-auth-key"
  },
  "user_agent": "Mozilla/5.0",
  "client": "dispatcher"
}
```

Suggested response shape:

```json
{
  "id": 9,
  "platform": "web",
  "is_active": true,
  "last_seen": "2026-03-26T17:24:41.760280"
}
```

Notes:

- In the current scaffold, authenticated user context is provided through the same `x-missionout-user-email` request header used by `GET /incidents`.
- The backend owns the subscription record and should not trust a client-supplied user id.
- The backend may scope subscriptions by authenticated membership or active client surface, but the registration entry point stays centralized.

## `GET /devices/web-push/public-key`

Purpose:

- Returns the configured VAPID public key and subject for browser Web Push registration.

Response shape:

```json
{
  "public_key": "BMj...base64url-vapid-public-key...",
  "subject": "mailto:justin.matis.com@gmail.com"
}
```

Notes:

- The frontend should fetch this value from the backend rather than hardcoding or inventing a key.
- The matching VAPID private key must remain backend-only.

## `DELETE /devices/web-push`

Purpose:

- Deactivates or removes a browser push subscription when the user logs out, disables notifications, or the service worker rotates subscriptions.

Suggested request shape:

```json
{
  "endpoint": "https://fcm.googleapis.com/fcm/send/abc123"
}
```

Suggested response:

- status `204`

Notes:

- The backend should allow idempotent unregister behavior so clients can safely retry cleanup.
- This route is the companion to `POST /devices/web-push` and supports the browser Web Push path for closed browser tabs.

## `POST /incidents`

Purpose:

- Create a new incident from the dispatcher web UI.
- Trigger dispatch targeting for the incident's team after the incident record is created.

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
  "created": "2026-03-26T17:24:41.760280",
  "notes": "Subject reports lower-leg injury above treeline.",
  "active": true,
  "responses": []
}
```

Notes:

- Creating an incident is expected to begin the dispatch flow, not just persist a row.
- This route is the boundary where the system moves from idle state into interrupt state.
- When an incident is created, it should get pushed to all active devices owned by active members of that incident's team.
- Closed-tab browser delivery follows the same team-targeting rule through active backend-owned Web Push subscriptions for active team members.
- Delivery fanout and retry behavior may be handled asynchronously by workers, but the targeting rule is part of the shared contract semantics.

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
  "created": "2026-03-26T17:24:41.760280",
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

## `GET /teams/{team_id}/members`

Purpose:

- Returns team membership records for Team Management and Super Admin workflows.

Response shape:

```json
[
  {
    "id": 1,
    "user_id": 1,
    "team_id": 1,
    "name": "Justin Mercer",
    "email": "justin@example.com",
    "phone": "555-0101",
    "roles": ["responder", "dispatcher"],
    "is_active": true,
    "granted_at": "2026-03-26T17:24:41.769162",
    "revoked_at": null
  }
]
```

## `POST /teams/{team_id}/members`

Purpose:

- Creates or invites a user into a team and assigns one or more team-scoped roles.

Request shape:

```json
{
  "name": "Avery Teamlead",
  "email": "avery@example.com",
  "phone": "555-0110",
  "roles": ["team_admin"],
  "is_active": true
}
```

Response:

- created membership record
- status `201`

## `PATCH /teams/{team_id}/members/{membership_id}`

Purpose:

- Updates membership state such as active status or assigned roles.

Request shape:

```json
{
  "roles": ["responder"],
  "is_active": false
}
```

Response:

- updated membership record

## `GET /teams/{team_id}/devices`

Purpose:

- Returns device health and registration visibility for team-management workflows.

Response shape:

```json
[
  {
    "id": 3,
    "user_id": 3,
    "user_name": "Mike Donnelly",
    "platform": "android",
    "push_token": "fcm-token-mike",
    "last_seen": "2026-03-26T17:24:41.764113",
    "is_active": false,
    "is_verified": false
  }
]
```

Guidance:

- Team Management routes should support create, invite, activate, and deactivate flows for one existing team.
- Team Management routes should avoid destructive hard-delete semantics for users with operational history.
- Team Management routes should not create teams or perform global administration.
- Dispatcher permissions should not imply Team Admin access, and Team Admin permissions should not imply dispatch access.
- Team Management routes are administrative readiness tools and should not be treated as part of the live incident interrupt flow.

## Realtime Contract

Recommended future event types:

- `incident.created`
- `incident.updated`
- `incident.response_changed`
- `incident.resolved`
- `delivery.event`
- `team.membership_changed`

Recommended transport split:

- `GET /events/stream` for open-tab SSE updates in dispatcher and Team Management web clients
- `POST /devices/web-push` and `DELETE /devices/web-push` for browser push subscription registration
- Web Push plus a service worker for closed-tab browser notifications
- Native FCM and APNs remain the primary responder alert path

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
