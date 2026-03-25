# MissionOut Backend

FastAPI + PostgreSQL scaffold for the MissionOut web and responder clients.

## Stack

- FastAPI
- SQLAlchemy 2.x
- PostgreSQL via `psycopg`
- Alembic ready

## Quick Start

1. Create a database named `missionout`.
2. Copy `.env.example` to `.env` and update `DATABASE_URL` if needed.
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
