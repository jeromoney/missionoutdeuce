# MissionOut

MissionOut is a SAR alerting platform organized as a monorepo with separate apps for the dispatcher web experience, responder alerting, and backend services.

`UserInterface/` owns the client applications only.
It should not depend on backend source code directly.
Its integration surface with `backend/` is the documented contract in:

- [docs/boundaries.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/boundaries.md)
- [docs/api-contracts.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/api-contracts.md)
- [docs/data-model.md](/C:/Users/justi/OneDrive/Documents/Projects/missionout/docs/data-model.md)

## Repo Layout

- `dispatcher/`
  Flutter app for the administrative and dispatcher web interface.
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

- The dispatcher/admin web prototype lives in `dispatcher/`.
- The backend lives in the sibling `backend/` folder at the repo root.
- The responder app scaffold lives in `responder/`.

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
- Contract changes should start in `docs/` before UI and backend diverge.