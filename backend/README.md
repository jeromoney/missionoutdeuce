# MissionOut Backend

FastAPI + PostgreSQL scaffold for the MissionOut web and responder clients.

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
   Set `GOOGLE_CLIENT_ID` to your Google web client id.
3. Install dependencies:

```powershell
cd backend
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

## External Secrets File

The backend will automatically look for:

```text
..\Secrets\missionout-backend.env
```

relative to the repo root. In your current layout that means:

```text
C:\Users\justi\OneDrive\Documents\Projects\Secrets\missionout-backend.env
```

You can also override the location explicitly:

```powershell
$env:MISSIONOUT_ENV_FILE="C:\Users\justi\OneDrive\Documents\Projects\Secrets\missionout-backend.env"
python run.py
```

If no external file is found, the backend falls back to `backend/.env`.

## Render Deploy

The repo includes a Render blueprint at [render.yaml](/Users/justi/OneDrive/Documents/Projects/missionout/render.yaml).

After creating the `missionout-backend` service and `missionout-db` database in Render, set:

```text
GOOGLE_CLIENT_ID=<your-google-web-client-id>
ALLOWED_ORIGINS=https://<your-admin-web-domain>
```

If you want both local and deployed frontends to work during testing, use a comma-separated list:

```text
ALLOWED_ORIGINS=https://<your-admin-web-domain>,http://localhost:3000,http://127.0.0.1:3000
```

## Available Routes

- `GET /health`
- `GET /incidents`
- `GET /events/delivery-feed`
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

## Response Shape Notes

The frontend currently expects:

- incidents with `title`, `team`, `location`, `created`, `notes`, `active`, and `responses`
- events with `title`, `detail`, `time`, `icon`, and `color`
