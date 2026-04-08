# QA / Testing Scope

This directory is owned by the QA / Testing thread.

## Purpose

Own verification quality, regression detection, and test strategy for backend behavior.

## Responsibilities

- API test coverage
- backend regression detection
- bug reproduction
- route and contract verification
- failure-mode validation
- test harness quality

## Constraints

- Do not use tests as a back door to redesign unrelated production behavior.
- Prefer adding targeted coverage close to the bug or contract being validated.
- If a production change is required, keep it tightly scoped to the verified issue.

## Structure Rule

Grow tests by intent:
- `api/` for route behavior
- `integration/` for DB-backed or cross-component behavior
- `contract/` for schema and OpenAPI verification
- `unit/` for pure logic as needed

## Quality Rule

- Treat warnings as active cleanup items.
- Prefer deterministic fixtures over hidden global state.
- Validate contract shape, not just status codes.
