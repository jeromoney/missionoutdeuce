# Firebase Auth as Identity Provider

Firebase Auth handles all credential verification (Google Sign-In, Email Link passwordless). The Flutter app sends Firebase ID tokens directly as Bearer tokens on every API call; the backend validates them via Firebase Admin SDK and looks up the MissionOut user by email. The backend no longer issues JWTs, stores refresh tokens, or owns any sign-in flow logic.

## Considered Options

**Backend-issued JWTs with Firebase credential exchange** — Firebase would verify Google/email credentials, the backend would still issue its own access tokens and manage refresh token rotation. This preserves the current backend session model but duplicates token lifecycle machinery alongside Firebase.

**Firebase ID token as bearer (chosen)** — Firebase owns the full token lifecycle. The backend's only auth responsibility is validating the incoming Firebase ID token and looking up the user by email. No refresh token table, no `/auth/refresh` endpoint, no signing key rotation concerns.

## Consequences

- `/auth/google`, `/auth/email-code`, `/auth/email-code/verify`, `/auth/refresh`, `/auth/logout` are all removed from the backend.
- A new `/users/me` endpoint returns the MissionOut profile (all team memberships) after Firebase auth succeeds on the client.
- Firebase can authenticate any Google account or email address. Users with no active MissionOut membership are rejected by `/users/me` (403), not at the Firebase layer — the client must handle an explicit "unprovisioned" state distinct from "not signed in."
- The `refresh_tokens` and `email_code_tokens` DB tables become droppable once the migration is complete.
- Email OTP (Resend-delivered 6-digit codes) is retired in favour of Firebase Email Link.
- Active team selection is client-owned. After `/users/me` loads, the client presents a team picker (auto-skipped for single-team users). The selected team is sent as `X-Team-Id` on every subsequent API call. The backend validates team membership and sets RLS GUCs accordingly. The last-used team ID is persisted locally per user so the picker is bypassed on return visits.
