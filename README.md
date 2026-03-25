# MissionOut

MissionOut is a SAR alerting platform organized as a monorepo with separate apps for the dispatcher web experience, responder alerting, and backend services.

## Repo Layout

- `dispatcher/`
  Flutter app for the administrative and dispatcher web interface.
- `responder/`
  Placeholder workspace for the responder app and native alerting code.
- `../backend/`
  FastAPI + PostgreSQL backend for incidents, delivery state, and alert workflows.
- `shared_auth/`
  Shared Flutter auth model package used by the apps.
- `shared_models/`
  Shared Dart domain model and enum package.
- `shared_theme/`
  Shared Flutter theme token package.

## Current Status

- The dispatcher/admin web prototype lives in `dispatcher/`.
- The backend scaffold lives in `../backend/`.
- The dedicated responder app has not been scaffolded yet, but the folder is reserved for that work.

## Run The Web App

```powershell
powershell -ExecutionPolicy Bypass -File .\dispatcher\tool\flutter_with_local_env.ps1 run -d chrome
```

The dispatcher wrapper script automatically looks for:

```text
C:\Users\justi\OneDrive\Documents\Projects\Secrets\missionout-backend.env
```

You can override that path with:

```powershell
$env:MISSIONOUT_DISPATCHER_ENV_FILE="C:\path\to\your\dispatcher.env"
powershell -ExecutionPolicy Bypass -File .\dispatcher\tool\flutter_with_local_env.ps1 run -d chrome
```

Supported keys in the dispatcher env file are:

```text
API_BASE_URL
GOOGLE_CLIENT_ID
```

The shared env file can also contain backend-only settings. The dispatcher only uses the Dart defines it reads at build time.

## Run The Backend

```powershell
cd ..\backend
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e .
copy .env.example .env
python -m app.seed
python run.py
```

## Notes

- `agents.md` at the repo root describes the system roles and architecture.
- The backend currently exposes `GET /health`, `GET /incidents`, and `GET /events/delivery-feed`.
