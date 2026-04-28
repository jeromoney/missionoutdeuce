# Doc update request: JWT bearer sessions replace `x-missionout-user-email`

**Filed by:** backend engineer
**Date:** 2026-04-27
**Owner to action:** docs team (read-only from backend per `backend/CLAUDE.md`)
**Related plan:** `~/.claude/plans/steady-beaming-minsky.md`
**Code already merged:** see backend changes below

## Why

The header-trust auth model (`x-missionout-user-email`) was a security risk — any caller could impersonate any user by setting the header. We replaced it with backend-signed JWTs (1h access + 180d server-side refresh). The code is already in place; the docs in `docs/` are now stale and need to catch up so cross-stack readers (especially the slack-bot engineer who explicitly consumes `api-contracts.md`) don't follow the old model.

## What changed in code

- **Auth header:** `Authorization: Bearer <jwt>` instead of `x-missionout-user-email: <email>`. Verified in `backend/app/api/deps.py::get_current_principal`.
- **Sign-in endpoints** (`POST /auth/google`, `POST /auth/email-code/verify`) now return `AuthSessionRead` instead of bare `AuthUserRead`:
  ```json
  {
    "user": { "public_id": "...", "name": "...", "initials": "...", "global_permissions": [], "team_memberships": [...], "email": "..." },
    "access_token": "<jwt>",
    "access_token_expires_at": "2026-04-27T13:00:00+00:00",
    "refresh_token": "<opaque>",
    "refresh_token_expires_at": "2026-10-24T12:00:00+00:00"
  }
  ```
- **New routes:**
  - `POST /auth/refresh` — body `{refresh_token}` → `AuthSessionRead`. Rotates the refresh token. Replaying a rotated token revokes the entire chain for that user.
  - `POST /auth/logout` — body `{refresh_token}` → `204`. Idempotent.
- **Token claims (access):** `sub` (user public_id), `email`, `iat`, `exp`, `iss=missionout-backend`, `type=access`. HS256.
- **Refresh token storage:** SHA-256 hashed in the new `refresh_tokens` table; plaintext leaves the server only at issue/rotate time. Includes `replaced_by_id` chain for replay detection.
- **Authoritative contract:** `contracts/openapi.json` has been regenerated and reflects all of the above.

## Files that need updating

### `docs/api-contracts.md`

1. **`POST /auth/email-code/verify`** (lines ~82–122) — replace the response shape with the new `AuthSessionRead` envelope. Note that `user` is now nested.
2. **`POST /auth/google`** (lines ~124–165) — same envelope change. Also clarify that the response delivers a MissionOut session credential, not just an identity confirmation.
3. **Add a new section: `POST /auth/refresh`** — request `{refresh_token}`, response `AuthSessionRead` (rotated). Document that:
   - The presented refresh token is single-use (rotate-on-use).
   - Replaying a rotated token returns `401` AND revokes every active refresh token for that user.
   - Refresh tokens last 180 days; access tokens last 1 hour.
4. **Add a new section: `POST /auth/logout`** — request `{refresh_token}`, response `204`. Idempotent.
5. **Authentication transport section** (currently the line ~355 note about `x-missionout-user-email`) — rewrite to: every authenticated route requires `Authorization: Bearer <access_token>`. Clients call `/auth/refresh` to rotate before expiry, and `/auth/logout` to revoke a session.
6. **Email-Code Flow** (lines ~167–173) — step 5 now returns a session, not just a user payload.

### `docs/security.md`

Add a section covering:

- JWT access tokens: HS256, identity-only claims (`sub` = user public_id, `email`, `iat`, `exp`, `iss`), 60-minute expiry. Role/membership is **not** baked into the token — it's recomputed from the DB on every request via `get_current_principal`, so role demotions and team removals take effect immediately without needing a token denylist.
- Refresh tokens: opaque, 180-day expiry, server-side revocable. Stored as SHA-256 hash only. Rotated on every `/auth/refresh`. Replay of a rotated token revokes the entire chain for the owning user.
- Signing key: `JWT_SIGNING_KEY` lives in `Secrets/missionout-backend.env`. Rotating the key invalidates all live access tokens immediately; refresh tokens still work because they're DB-backed and not signed by the JWT key.
- Logout: `POST /auth/logout` revokes the refresh token. Access tokens remain valid until natural expiry (≤1h); this is the accepted revocation window.
- RLS still keys off `app.user_id` and `app.role` set by `get_current_principal` — that's unchanged. The only thing that changed is the source of identity (Bearer JWT instead of header).

### `docs/CLAUDE.md` / `docs/AGENTS.md`

Confirm whether either of these files links to the auth flow or sets cross-stack rules around it. If either describes the old header model, update accordingly.

## Out of scope for this request

- Slack bot service-credential design — separate plan. `slack_bot/CLAUDE.md` already has a one-paragraph note about the new bearer flow and a follow-up to define `act-as` semantics.
- `flutter_secure_storage` for client-side token storage — also a follow-up.

## How to verify the doc update

1. `grep -ri "x-missionout-user-email" docs/` should return zero hits.
2. Every example response under `/auth/*` in `api-contracts.md` should match a schema in `contracts/openapi.json`. Spot-check `/auth/google` and `/auth/refresh`.
3. Read `security.md` end-to-end and confirm a slack-bot engineer or new contributor could implement Bearer + refresh correctly from docs alone, without reading code.
