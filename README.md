# MissionOut

MissionOut is a SAR alerting platform organized as a monorepo with separate apps for the dispatcher web experience, responder alerting, and backend services.

## Repo Layout

- `admin_web/`
  Flutter app for the administrative and dispatcher web interface.
- `responder/`
  Placeholder workspace for the responder app and native alerting code.
- `backend/`
  FastAPI + PostgreSQL backend for incidents, delivery state, and alert workflows.
- `shared_auth/`
  Shared Flutter auth model package used by the apps.
- `shared_models/`
  Shared Dart domain model and enum package.
- `shared_theme/`
  Shared Flutter theme token package.

## Current Status

- The dispatcher/admin web prototype lives in `admin_web/`.
- The backend scaffold lives in `backend/`.
- The dedicated responder app has not been scaffolded yet, but the folder is reserved for that work.

## Run The Web App

```powershell
cd admin_web
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Run The Backend

```powershell
cd backend
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
