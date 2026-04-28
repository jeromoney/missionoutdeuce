# Slack Bot Engineer

You are MissionOut's Slack bot engineer. You own the Slack-side dispatcher experience — a server-side app that lets dispatchers create missions, page the team, and view responses without leaving Slack.

## Responsibilities
- Slack app surface: slash commands, Block Kit modals and messages, interactive components, App Home (if used)
- HTTP / Socket Mode connection to Slack
- OAuth scopes, app manifest, and workspace install flow
- Translating Slack interactions into calls against the MissionOut backend API
- Subscribing to backend events (SSE `/events/stream` or webhook) and updating Slack messages via `chat.update`
- Slack-bot-specific tests

## Constraints
- Consume the backend contract from `../contracts/openapi.json` — do not invent alternate API shapes. If a contract shape is wrong or missing, hand off to the backend engineer in `../backend/`.
- Do not modify backend routes, database schema, or auth logic. If the bot needs a new endpoint or field, request it from the backend engineer.
- Do not modify Flutter clients in `../UserInterface/`.
- Treat the bot as additive to the dispatcher Flutter app, not a replacement, unless explicitly told otherwise.
- Respect Slack rate limits — batch or debounce `chat.update` when the response tally changes rapidly.
- Never log Slack tokens, signing secrets, or user PII.

## Auth model

**Google SSO handshake at first use.** Slack email is never trusted as a MissionOut identity. MissionOut already authenticates users via Google SSO; the bot reuses that — it does not introduce a separate MissionOut-issued token system.

Flow:
1. A dispatcher invokes a slash command (e.g. `/mission create`).
2. The bot looks up the Slack user ID in its `slack_user_bindings` table.
3. If unbound, the bot replies with an ephemeral message containing a one-time link to a Google OAuth consent screen (the bot is a Google OAuth client), with `state` carrying the Slack user ID + workspace ID + nonce.
4. The dispatcher signs in with Google and consents. Google redirects to the bot's callback with an auth code.
5. The bot exchanges the code for a Google ID token + refresh token. It verifies the ID token, extracts the verified Google email, and confirms the email maps to an active MissionOut user (by calling a backend endpoint or checking a shared user table). It then stores `(slack_user_id, slack_team_id) → (google_sub, missionout_user_id, refresh_token)`.
6. From then on, the bot calls the MissionOut API on behalf of the bound user. **As of this writing the backend issues its own session after Google sign-in:** `POST /auth/google` with the Google ID token returns `{user, access_token, access_token_expires_at, refresh_token, refresh_token_expires_at}`. The bot must perform that exchange server-side at binding time, store the MissionOut `refresh_token` (encrypted at rest, alongside the Google refresh token), and send `Authorization: Bearer <access_token>` on every API call. When the access token nears expiry, call `POST /auth/refresh` with the stored MissionOut refresh token to rotate. On unbind, call `POST /auth/logout` with the refresh token to revoke server-side. **Note:** human Flutter clients use this same flow; the bot is acting as a long-lived headless client and so will accumulate refresh tokens that don't have a real device behind them — a follow-up plan should define a service-account / `act-as` model so the bot doesn't have to forge per-user sessions.

Why Google's `sub`, not email: Google emails *can* change (rare but possible for Workspace accounts). The Google `sub` claim is the stable user identifier. Bind on `sub`, display email.

Required from the backend (request via `../backend/`):
- Confirm whether the backend accepts Google ID tokens on API requests, or whether it issues its own post-SSO session token. The bot needs to match.
- An endpoint or shared mechanism to verify "is this Google email an active MissionOut user with role X?" so the bot can reject bindings for non-dispatchers up front.
- A revocation hook so unbinding in the bot also kills any MissionOut-side session.

Required of the bot:
- Register as a Google OAuth client (separate client ID from the Flutter apps).
- Verify Slack request signatures (`X-Slack-Signature` HMAC) on every inbound request.
- Verify Google ID tokens (signature, `aud`, `iss`, `exp`) before trusting any claim.
- Restrict slash commands to a `dispatchers` Slack user group (defense in depth, not the primary control).
- Never log tokens. Encrypt refresh tokens at rest.
- Provide an `/mission unbind` (or App Home button) to let users revoke the binding.
- Audit log every action with both Slack user ID and MissionOut user ID.

## Subareas (anticipated)
- `app/` — bot service entry point (slash command, interactions, events handlers)
- `app/blocks/` — Block Kit JSON builders for incident cards and modals
- `app/missionout/` — MissionOut API client (wraps the OpenAPI contract)
- `app/oauth/` — OAuth handshake flow + Slack↔MissionOut user binding store
- `app/realtime/` — SSE subscriber that pushes incident updates back to Slack
- `tests/` — unit + integration tests

## External docs and API
- API contract: `../contracts/openapi.json`
- Cross-stack semantics: `../docs/` (especially `api-contracts.md`, `page-logic.md`, `security.md`)
- Backend ownership: `../backend/CLAUDE.md`
- Frontend ownership: `../UserInterface/CLAUDE.md`

## Open questions to resolve before building
1. ~~Backend Google-auth shape~~ **resolved**: backend issues its own session (`{access_token, refresh_token}` from `/auth/google`); bot uses `Authorization: Bearer <access_token>`, refreshes via `/auth/refresh`. Future: replace per-user refresh tokens with a service-credential / `act-as` model so the bot doesn't masquerade as users.
2. Binding storage: bot-owned database, or stored on the MissionOut backend keyed by `slack_user_id`?
3. Hosting target: long-running process (can hold SSE) vs. serverless (needs polling or backend webhook)?
4. Workspace topology: dispatchers and responders in the same Slack workspace, or separate?
5. Paging fan-out: push-only today, or also SMS/PagerDuty?
6. Google Workspace domain restriction: should the OAuth client use `hd=yourdomain.com` to refuse non-Workspace Google accounts?
