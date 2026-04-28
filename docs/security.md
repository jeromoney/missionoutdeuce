#Rules for data access
## DB Table Rules
 - The following table outlines the access roles for the 3 roles. Data access will be further limited by a Postgres RLS policy matrix, which is below
 -
| Table/Resource         | team_admin | dispatcher | responder |
|------------------------|------------|------------|-----------|
| email_link_tokens      | backend    | backend    | backend   |
| web_push_subscriptions | SUD        | SUD        | SUD       |
| responses              | SIUD       | SIUD       | SIUD      |
| incidents              | SIUD       | SIU        | S         |
| incident_events        | backend    | backend    | backend   |
| push_deliveries        | backend    | backend    | backend   |
| email_code_tokens      | backend    | backend    | backend   |
| devices                | SUD        | SUD        | SUD       |
| delivery_events        | S          | S          |           |
| team_memberships       | SIUD       | S          | S         |
| users                  | SIUD       | SU         | SU        |
| teams                  | S          | S          | S         |

## Postgres RLS policy matrix
 - 
| Table/Resource         | team_admin                          | dispatcher                         | responder                                  |
|------------------------|-------------------------------------|------------------------------------|---------------------------------------------|
| web_push_subscriptions | own team / own user as needed       | own team / own user as needed      | own records only                            |
| responses              | rows for incidents in their team    | rows for incidents in their team   | rows for incidents in their team            |
| incidents              | incidents in their team             | incidents in their team            | incidents in their team, read-only          |
| devices                | own team / own user as needed       | own team / own user as needed      | own device rows only                        |
| delivery_events        | events for incidents in their team  | events for incidents in their team | none                                        |
| team_memberships       | memberships in their team           | memberships in their team, read    | memberships in their team, read             |
| users                  | users in their team                 | users in their team, read          | users in their team, read                   |
| teams                  | their team                          | their team                         | their team                                  |

## Authentication and session model

MissionOut authenticates every API call using a backend-signed JWT bearer token. The earlier scaffold trusted a client-supplied user-email request header, which any caller could forge to impersonate any user. That header model has been removed end-to-end and replaced with the session model below.

### Access tokens (JWT)

- Algorithm: HS256.
- Claims: `sub` (user `public_id`), `email`, `iat`, `exp`, `iss=missionout-backend`, `type=access`. Identity-only — **no role or membership claims**.
- Expiry: 60 minutes.
- Transport: `Authorization: Bearer <access_token>` on every authenticated route.
- Validation: `backend/app/api/deps.py::get_current_principal` verifies the signature, expiry, issuer, and `type=access`, then loads the user by `sub` and recomputes role and team membership from the database on every request.
- **Security consequence:** because role and membership are recomputed per request, a role demotion or team removal takes effect immediately on the next request. There is no token denylist, and no need for one.

### Refresh tokens

- Format: opaque random string (not a JWT). The plaintext value leaves the server only at issue time and at rotation time.
- Storage: SHA-256 hashed in the `refresh_tokens` table. The plaintext is never persisted.
- Expiry: 180 days.
- Rotation: every successful `POST /auth/refresh` consumes the presented token and issues a new one. Each row carries a `replaced_by_id` pointer that links the chain.
- Replay detection: presenting an already-rotated refresh token is treated as evidence of compromise. The backend returns `401` and revokes every active refresh token in that user's chain. The user must re-authenticate.
- Revocation: server-side. `POST /auth/logout` revokes the presented refresh token. Outstanding access tokens minted from that chain remain valid until their natural ≤1h expiry — this is the accepted revocation window.

### Signing key

- The HS256 signing secret lives in `JWT_SIGNING_KEY` in `Secrets/missionout-backend.env`. It is backend-only and must never be shipped to clients.
- Rotating the signing key invalidates **every** live access token immediately, since they will all fail signature verification.
- Refresh tokens survive a signing-key rotation: they are opaque random values stored as SHA-256 hashes, not JWTs, so they are not signed by `JWT_SIGNING_KEY`. After a rotation, clients automatically recover by calling `POST /auth/refresh` and receiving a freshly signed access token.

### Relationship to RLS

- Postgres RLS still keys off the `app.user_id` and `app.role` GUCs that `get_current_principal` sets per request. That mechanism is unchanged.
- The only thing that changed is the **source of identity** used to populate those GUCs: it is now the verified `sub` claim from the Bearer JWT instead of a client-supplied email header.
- The DB Table Rules and RLS policy matrix above remain authoritative for what each role can see and modify.