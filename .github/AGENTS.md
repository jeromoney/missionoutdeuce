# Infrastructure / Deploy Scope

This directory is owned by the Infrastructure / Deploy thread.

## Purpose

Own CI/CD and deployment workflow configuration.

## Responsibilities

- GitHub Actions
- CI checks
- deployment workflow configuration
- environment and release pipeline behavior

## Constraints

- Do not redesign application logic from CI configuration alone.
- Keep deployment and pipeline changes explicit and auditable.
- If a workflow change implies an application contract change, hand that back to the appropriate backend or frontend thread.

## Adjacent Ownership

- Render service configuration in root files still belongs to Infrastructure / Deploy.
- Cloudflare and DNS decisions also belong to Infrastructure / Deploy even when documented outside `.github/`.
