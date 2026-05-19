# MissionOut

MissionOut is an emergency alerting platform. Dispatchers send incident alerts; responders acknowledge and respond; team admins manage team membership and configuration.

## Language

### Identity and Authentication

**Firebase Auth**:
The external identity provider. Authenticates users via Google Sign-In or Email Link. Issues Firebase ID tokens. Does not know about MissionOut memberships.
_Avoid_: "auth provider", "Firebase", "OAuth provider"

**Firebase ID Token**:
A short-lived JWT issued by Firebase after a successful sign-in. Sent as the Bearer token on every API call. Validated by the backend via Firebase Admin SDK.
_Avoid_: "access token" (that term previously referred to backend-issued JWTs)

**Email Link**:
Firebase's passwordless sign-in method. A one-time magic link is emailed to the user; tapping it completes sign-in. Replaces the retired Email OTP flow.
_Avoid_: "magic link", "email code", "OTP", "passwordless email"

**Sign-In Method**:
One of the pluggable strategies a client app uses to authenticate within Firebase Auth. Current methods: Google Sign-In, Email Link.
_Avoid_: "auth strategy", "login method"

**MissionOut Profile**:
The app's representation of an authenticated user: `publicId`, `name`, `email`, and all **Team Memberships**. Returned by `/users/me` after Firebase authentication succeeds. Distinct from Firebase identity.
_Avoid_: "user profile", "auth user", "session"

**Active Team**:
The team a user has selected for their current session. Sent as `X-Team-Id` on every API call. Auto-selected when the user belongs to exactly one team; otherwise chosen from a picker. Persisted locally per user so the picker is bypassed on return visits.
_Avoid_: "current team", "selected team", "active context"

**Unprovisioned User**:
A user who has successfully authenticated with Firebase but has no active MissionOut team membership (200 with empty memberships from `/users/me`), or whose account is entirely unknown to the backend (non-200 from `/users/me`). Both cases are treated identically: the client remains on the sign-in screen and shows a persistent banner with the user's authenticated email — "Contact your local administrator referencing this email: {email}". The user stays neither signed in nor fully signed out of Firebase.
_Avoid_: "unauthorized user", "unknown user"

### Roles and Clients

**Role**:
A user's permission level within a team: `responder`, `dispatcher`, or `team_admin`. Computed from the DB on every request — never embedded in tokens.
_Avoid_: "permission level", "user type"

**Client**:
One of the three app surfaces: `responder`, `dispatcher`, `team_admin`. Each surface enables specific sign-in methods and UI features.
_Avoid_: "app", "surface", "platform"

### Domain

**Incident**:
An emergency event created by a dispatcher and broadcast to responders on a team.
_Avoid_: "alert", "event", "emergency"

**Response**:
A responder's acknowledgement of an Incident.
_Avoid_: "acknowledgement", "reply", "RSVP"

**Team Membership**:
A user's association with a team, carrying one or more Roles. A user may belong to multiple teams.
_Avoid_: "membership", "user-team association"

## Relationships

- A **Team** has one or more **Team Memberships**
- A **Team Membership** grants a **User** one or more **Roles** within that team
- A **User** authenticates via **Firebase Auth** and receives a **Firebase ID Token**
- The backend exchanges a **Firebase ID Token** for a **MissionOut Profile** via `/users/me`
- A **User** without an active **Team Membership** is an **Unprovisioned User**
- A **Dispatcher** creates **Incidents**; **Responders** submit **Responses** to them

## Flagged ambiguities

- "access token" previously referred to backend-issued JWTs. The backend no longer issues JWTs. The term now refers exclusively to **Firebase ID Token** when it appears in auth context.
- "email code" and "OTP" previously referred to the Resend-delivered 6-digit sign-in code. That flow is retired. The term **Email Link** is the canonical passwordless method.
