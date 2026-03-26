# MissionOut

MissionOut is a SAR alerting platform organized as a monorepo with separate apps for the dispatcher web experience, responder alerting, and backend services.

`UserInterface/` owns the client applications only.
It should not depend on backend source code directly.
Its integration surface with `backend/` is the shared contract:

- [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json)
- [docs/boundaries.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/boundaries.md)
- [docs/api-contracts.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/api-contracts.md)
- [docs/data-model.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/data-model.md)

## Repo Layout

- `dispatcher/`
  Flutter app for dispatcher-only live incident workflows.
- `team_admin/`
  Flutter app for single-team administration workflows.
- `responder/`
  Flutter app for responder-facing experiences.
- `shared_auth/`
  Shared Flutter auth model package used by the apps.
- `shared_models/`
  Shared Dart domain model and enum package.
- `shared_theme/`
  Shared Flutter theme token package.

These shared packages are UI-only code inside `UserInterface/`.
They are not a contract surface for `backend/`.

## Current Status

- The dispatcher web prototype lives in `dispatcher/`.
- The Team Admin web prototype lives in `team_admin/`.
- The backend lives in the sibling `backend/` folder at the repo root.
- The responder app scaffold lives in `responder/`.

## Run The Web App

```powershell
powershell -ExecutionPolicy Bypass -File .\dispatcher\tool\flutter_with_local_env.ps1 run -d chrome
```

For the Team Admin app:

```powershell
cd .\team_admin
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
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

For local backend testing, set `API_BASE_URL=http://127.0.0.1:8000`.

For the deployed backend instead, set `API_BASE_URL=https://missionout-backend.onrender.com`.

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
- Contract changes should start with [contracts/openapi.json](/C:/Users/justi/OneDrive/Documents/Projects/missionout/contracts/openapi.json), with `docs/` explaining the meaning and workflow around that contract.
