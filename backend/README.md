# MissionOut Backend

FastAPI + PostgreSQL backend for MissionOut.

This folder should not depend on code inside `UserInterface/`.
Its public surface area for the UI is the shared contract:

- [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json)
- [docs/boundaries.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/boundaries.md)
- [docs/api-contracts.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/api-contracts.md)
- [docs/data-model.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/data-model.md)

## Stack

- FastAPI
- SQLAlchemy 2.x
- PostgreSQL via `psycopg`
- Alembic ready

## Quick Start

1. Create a database named `missionout`.
2. Choose one local config approach:
   - Copy `.env.example` to `.env` and update `DATABASE_URL` if needed.
   - Or keep secrets outside the repo in `..\Secrets\missionout-backend.env`.
   Set `GOOGLE_CLIENT_ID` to your Google web client id. If you have more than one web client that should be accepted by the backend, you can provide a comma-separated list.
   Set `EMAIL_CODE_EXPIRES_IN_MINUTES` if you want a non-default expiry for one-time email sign-in codes.
   Set `EMAIL_CODE_LENGTH` if you want a non-default code length. The current contract default is 6.
   Set `RESEND_API_KEY` and `RESEND_FROM_EMAIL` so the backend can send one-time email-code sign-in messages through Resend.
3. Install dependencies:

```powershell
cd ..\\backend
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e .
```

4. Seed starter data:

```powershell
python -m app.seed
```

5. Run the API:

```powershell
python run.py
```

## Contract Workflow

Export the current OpenAPI contract:

```powershell
python scripts/export_openapi.py
```

Verify the checked-in contract is current:

```powershell
python scripts/check_openapi.py
```

CI also runs the same verification through [.github/workflows/contract-check.yml](/C:/Users/justi/OneDrive/Documents/Projects/missionout/.github/workflows/contract-check.yml).

## External Secrets File

The backend will automatically look for:

```text
..\Secrets\missionout-backend.env
```

relative to the backend folder. In your current layout that means:

```text
C:\Users\justi\OneDrive\Documents\Projects\Secrets\missionout-backend.env
```

You can also override the location explicitly:

```powershell
$env:MISSIONOUT_ENV_FILE="C:\Users\justi\OneDrive\Documents\Projects\Secrets\missionout-backend.env"
python run.py
```

If no external file is found, the backend falls back to `.env` in the backend folder.

## Render Deploy

This repo includes Render blueprints at [render.yaml](/C:/Users/justi/OneDrive/Documents/Projects/missionout/render.yaml) and [backend/render.yaml](/C:/Users/justi/OneDrive/Documents/Projects/missionout/backend/render.yaml).

Use the repo-root blueprint when connecting the full repository to Render. It deploys the FastAPI service from `backend/` and attaches the managed PostgreSQL database automatically.

The blueprint installs dependencies from `uv.lock` with a frozen sync so deploys stay pinned to the audited lockfile.

After creating the `missionout-backend` service and `missionout-db` database in Render, set:

```text
GOOGLE_CLIENT_ID=<your-google-web-client-id>
ALLOWED_ORIGINS=https://<your-admin-web-domain>
```

If you want both local and deployed frontends to work during testing, use a comma-separated list:

```text
ALLOWED_ORIGINS=https://<your-admin-web-domain>,http://localhost:3000,http://127.0.0.1:3000
```

The backend also allows localhost and `127.0.0.1` on arbitrary ports by default through `ALLOWED_ORIGIN_REGEX`, which keeps Flutter web development working when the local port changes between runs.

Your current deployed API base URL is:

```text
https://missionout-backend.onrender.com
```

## Available Routes

- `GET /`
- `GET /health`
- `GET /incidents`
- `GET /teams/{team_id}/members`
- `POST /teams/{team_id}/members`
- `PATCH /teams/{team_id}/members/{membership_id}`
- `GET /teams/{team_id}/devices`
- `GET /events/delivery-feed`
- `POST /auth/email-code`
- `POST /auth/email-code/verify`
- `POST /auth/google`

## Frontend Connection

From the Flutter app root:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

For Google auth, also pass the Google web client id:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000 --dart-define=GOOGLE_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
```

For the deployed backend instead:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://missionout-backend.onrender.com
```

## Contract Rule

If a route or payload changes here, regenerate [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json) in the same change and update `docs/` when the semantics changed.
