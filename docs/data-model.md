# MissionOut Data Model

This document defines the core shared entities used across:

- `admin_web/`
- `responder/`
- `backend/`

The backend remains the implementation source of truth, but this file is the human-readable contract for the system's data model.

## Principles

- The backend owns authoritative state.
- Frontend apps should model the same concepts, even if they only use a subset of fields.
- Fields should be stable and predictable across web, responder, and backend services.
- Emergency alerting features should prefer explicit state over derived guesswork.

## Core Entities

## Incident

Represents an operational mission or callout.

Fields:

- `id`
  Unique identifier for the incident.
- `title`
  Short dispatcher-facing incident name.
- `location`
  Human-readable location text.
- `notes`
  Dispatcher notes, hazards, updates, and mission context.
- `created`
  Client-facing relative or formatted timestamp string.
- `active`
  Boolean indicating whether the incident is still operationally active.
- `responses`
  List of responder response records tied to the incident.

Notes:

- `title`, `location`, `notes`, and `active` may change over time.
- `created` may be represented internally as a timestamp and formatted per client.

## ResponseRecord

Represents a responder’s current state for a specific incident.

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
  UI-facing time label.
- `icon`
  Event icon key for clients.
- `color`
  UI hint color for the event.

Notes:

- Delivery events are operational feed items, not the full alert-delivery audit model.
- The long-term backend may also track lower-level delivery attempt records separately.

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
- `phone`
- `is_active`

## Device

Represents a registered delivery target for a responder.

Likely fields:

- `id`
- `user_id`
- `platform`
- `push_token`
- `last_seen`
- `is_active`

## TeamMembership

Represents a user’s membership and role in a team.

Likely fields:

- `id`
- `user_id`
- `team_id`
- `role`

Expected roles:

- `responder`
- `dispatcher`
- `team_admin`
- `super_admin`

## AlertDelivery

Represents a concrete attempt to deliver an alert to a device.

Likely fields:

- `id`
- `incident_id`
- `device_id`
- `status`
- `attempt_count`
- `last_attempt_at`

## Source of Truth

- Human-readable shared contract: this file
- API and validation source: backend Pydantic schemas
- Persistence source: backend SQLAlchemy models and database schema
- Frontend mapping source: Dart models in each client app
