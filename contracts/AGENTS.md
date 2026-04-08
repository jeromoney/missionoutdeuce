# Contracts Scope

This directory is shared by the Architect / Planning, Backend API, and QA / Testing threads.

## Purpose

Own the machine-readable API contract and keep it aligned with backend implementation and documented semantics.

## Responsibilities

- `openapi.json` as the exported HTTP contract
- contract shape review for routes, payloads, and response models
- backend/frontend integration boundary checks
- contract drift detection between backend code and exported schema
- validating that documented current routes are actually present in the generated contract

## Constraints

- Do not treat this directory as an independent source of truth apart from the backend.
- Do not hand-edit `openapi.json` casually when the backend can generate the same change.
- Route or schema changes here are not complete until the backend implementation and contract export match.
- Do not introduce frontend-only assumptions into the contract without corresponding backend support.

## Ownership Rules

- Architect / Planning may define contract direction and semantics.
- Backend API owns implementation and regeneration of the exported contract.
- QA / Testing owns contract verification, drift checks, and regression coverage.

## Working Rule

When a contract change is made:
- update the backend schema or route first when applicable
- regenerate `openapi.json`
- update `docs/api-contracts.md` if semantics or current-route status changed
- verify affected tests or contract checks still pass

## Boundary Rule

This directory defines the shared boundary between:
- `backend/` implementation
- `UserInterface/` consumers
- `docs/` semantic documentation

Changes here should make that boundary clearer, not looser.
