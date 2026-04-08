# Frontend Scope

This directory is owned by the Frontend Product thread.

## Purpose

Own Flutter UI, client behavior, and shared frontend modules.

## Responsibilities

- Flutter widgets and screens
- navigation and routing
- client-side state management
- repositories and view models
- shared Flutter modules
- dispatcher, responder, and Team Management app behavior
- frontend tests

## Constraints

- Do not modify backend logic unless explicitly instructed.
- Do not change database schema from this directory.
- Assume the backend contract is consumed from `../contracts/openapi.json`.
- Do not treat the brochure website as part of the product UI.

## Subareas

- `dispatcher/` for dispatcher web client
- `responder/` for responder client
- `team_admin/` for Team Management app
- `shared_auth/`, `shared_models/`, and `shared_theme/` for shared Flutter code

## Contract Rule

- Do not invent alternate API shapes when the contract already exists.
- If a contract shape is wrong, hand the change off to the Backend API or Architect thread instead of patching around it locally.
