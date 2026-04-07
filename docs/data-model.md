# MissionOut Data Model

This document defines the shared entities used across:

- `backend/`
- `UserInterface/dispatcher/`
- `UserInterface/team_admin/`
- `UserInterface/responder/`

This file is the language boundary between backend and UI.
Backend storage models and UI view models may differ internally, but the concepts and field meanings shared across the stack should be documented here first.

## Principles

- The backend owns authoritative runtime state.
- Frontend apps should model the same concepts, even if they only use a subset of fields.
- Fields should be stable and predictable across web, responder, and backend services.
- Emergency alerting features should prefer explicit state over derived guesswork.
- Internal implementation details should not be treated as the contract.
- The product should be modeled around long idle periods interrupted by rare high-consequence missions.

## Core Entities

## Incident

Represents an operational mission or callout.

Fields:

- `id`
  Unique identifier for the incident.
  `team_id`
  Foreign key unique identifier for the associated team
- `title`
  Short dispatcher-facing incident name.
- `location`
  Human-readable location text.
- `notes`
  Dispatcher notes, hazards, updates, and mission context.
- `created`
  Canonical creation timestamp.
- `active`
  Boolean indicating whether the incident is still operationally active.
- `responses`
  List of responder response records tied to the incident.

Notes:

- `title`, `location`, `notes`, and `active` may change over time.
- `created` should be exposed as a real timestamp and formatted per client.
- Most teams will have zero active incidents most of the time, and multiple simultaneous incidents should be treated as an exception case rather than the default design center.
- `GET /incidents` exposes only incidents whose `created` timestamp falls within the last 7 calendar days. Historical incident access, if added later, should use a separate route or explicit query contract.
- Incident visibility for that route is derived from the authenticated user's team memberships and global permissions rather than a client-provided `team_id` filter.
- Incident dispatch targeting is team-scoped: when an incident is created, it should get pushed to all active devices owned by active members of that incident's team.
- Browser Web Push targeting follows the same team-scoped rule through active backend-owned subscriptions for active team members.

## ResponseRecord

Represents a responder's current state for a specific incident.

Fields:

- `name`
  Human-readable responder name.
- `status`
  Current responder state for the incident.
- `detail`
  Additional context such as ETA, availability note, or delivery state.
- `rank`
  Sort priority for display ordering.

Expected statuses:

- `Responding`
- `Pending`
- `Not Available`

Notes:

- UI color should be derived from `status` by each client.
- `rank` is currently a UI convenience field.
- Long term, status ordering may be derived from shared enums rather than stored directly.

## DeliveryEvent

Represents a delivery, acknowledgement, or escalation event shown in operational logs.

Fields:

- `title`
  Short summary of the event.
- `detail`
  Longer explanation of what happened.
- `time`
  Canonical event timestamp.
- `icon`
  Event icon key for clients.
- `color`
  UI hint color for the event.

Notes:

- Delivery events are operational feed items, not the full alert-delivery audit model.
- The long-term backend may also track lower-level delivery attempt records separately.

## RealtimeEvent

Represents a one-way live update delivered to open web clients over SSE.

Likely fields:

- `type`
- `incident_id`
- `team_id`
- `created`
- `data`

Notes:

- `RealtimeEvent` is a transport event for `GET /events/stream`, not the source-of-truth incident record.
- It should be sufficient to prompt a web client to refresh or patch local state while the tab is open.
- Closed-tab browser notifications should use a future Web Push model instead of SSE.

## Future Entities

These are part of the intended MissionOut architecture even if they are not fully implemented in the current scaffold.

## Team

Represents an operational SAR unit or organization.

Likely fields:

- `id`
- `name`
- `organization_id`
- `is_active`

## User

Represents a human account in the system.

Likely fields:

- `id`
- `name`
- `email`
- `phone`
- `is_active`

Notes:

- A user may authenticate through Google auth or an email sign-in link issued by the backend.
- Email should be treated as a first-class identity field because it is used both for login and for team membership administration.

## Device

Represents a registered delivery target for a responder.

Likely fields:

- `id`
- `user_id`
- `platform`
- `push_token`
- `last_seen`
- `is_active`

Notes:

- Devices are delivery targets, not just passive metadata.
- Incident fanout should target active devices belonging to active users who are active members of the incident's team.

## WebPushSubscription

Represents a browser push subscription saved by the backend for future Web Push delivery.

Likely fields:

- `id`
- `user_id`
- `team_id`
- `endpoint`
- `p256dh`
- `auth`
- `user_agent`
- `client`
- `last_seen`
- `is_active`

Notes:

- `WebPushSubscription` is separate from mobile `Device` records because browser subscriptions use Web Push endpoints and encryption keys rather than FCM or APNs device tokens directly.
- The backend owns registration and cleanup through `POST /devices/web-push` and `DELETE /devices/web-push`.
- Team scope should come from the authenticated user context and active memberships rather than a client claiming arbitrary ownership.
- Web Push subscriptions participate in the same incident-delivery targeting rule as mobile devices for closed-tab browser alerts.

## TeamMembership

Represents a user's membership and granted roles in a team.

Likely fields:

- `id`
- `user_id`
- `team_id`
- `roles`
- `is_active`
- `granted_at`
- `revoked_at`

Expected roles:

- `responder`
- `dispatcher`
- `team_admin`

Notes:

- Team-scoped roles should allow a user to hold both `dispatcher` and `team_admin` for the same team when explicitly granted.
- A single membership should represent one `user_id` plus one `team_id`, with the full set of granted team-scoped roles attached to that membership.
- `super_admin` should be modeled outside team membership or as a separate global permission concept, not as a normal team-scoped role.
- The Team Management app should use Team Admin permissions only for one existing team and should prefer deactivation over hard deletion so historical incidents and responses remain auditable.
- Team membership administration supports readiness before and between missions; it is not part of the live dispatch interrupt loop.

## AlertDelivery

Represents a concrete attempt to deliver an alert to a device.

Likely fields:

- `id`
- `incident_id`
- `device_id`
- `status`
- `attempt_count`
- `last_attempt_at`

Notes:

- Alert delivery records should be created from the team-scoped targeting set for an incident.
- That targeting set is all active devices and active browser Web Push subscriptions owned by active members of the incident's team.

## Source of Truth

- Machine-readable HTTP contract: [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json)
- Human-readable shared semantics: this file and [api-contracts.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/api-contracts.md)
- Backend validation source: backend Pydantic schemas
- Backend persistence source: SQLAlchemy models and database schema
- Frontend mapping source: Dart models in each client app
