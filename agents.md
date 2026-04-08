# MissionOut Root Agent Guide

This file defines the operating model for AI-assisted work in the MissionOut repository.

MissionOut should be run with specialist threads, not one mixed thread handling every concern. The goal is to keep planning, frontend, backend, testing, infrastructure, and website work from stepping on each other.

## Core Rule

One thread owns one role.

Do not use a thread as a generic scratchpad. A thread should have a stable responsibility and a stable set of allowed changes.

## Recommended Thread Structure

### 1. Architect / Planning

Purpose:
- high-level planning only

Responsibilities:
- feature design
- architecture decisions
- role boundaries
- data model direction
- API contract direction
- sprint and task breakdown
- cross-thread handoff planning

Constraints:
- does not directly implement code unless explicitly asked
- does not become a debugging thread
- does not become a deployment thread

### 2. Frontend Product

Purpose:
- own Flutter product UI and client behavior

Responsibilities:
- Flutter widgets and screens
- routing and navigation
- client-side state management
- view models and repositories
- design system and styling
- dispatcher, responder, and Team Management app UI behavior

Constraints:
- does not change backend logic unless explicitly instructed
- does not change database schema
- does not own deployment or DNS

Primary paths:
- `UserInterface/`

### 3. Backend API

Purpose:
- own backend, API, database, and worker-side application logic

Responsibilities:
- FastAPI routes
- authentication and authorization
- database schema and models
- OpenAPI contract generation
- queue and worker behavior
- backend-side alert targeting and delivery logic

Constraints:
- does not redesign frontend UI
- does not own marketing site work
- does not become a Cloudflare or DNS thread unless explicitly redirected

Primary paths:
- `backend/`
- `contracts/`
- relevant `docs/` contract files

### 4. QA / Testing

Purpose:
- own verification quality, bug diagnosis, and test strategy

Responsibilities:
- test design
- API and UI test coverage
- bug reproduction
- regression analysis
- code review
- performance review
- security review at the testing layer

Constraints:
- does not become the main implementation thread unless explicitly asked
- should prefer identifying weak assumptions and missing coverage

Primary paths:
- `backend/tests/`
- `UserInterface/**/test/`
- `UserInterface/**/integration_test/`
- contract verification artifacts

### 5. Infrastructure / Deploy

Purpose:
- own environment, deployment, networking, and operational setup

Responsibilities:
- Cloudflare
- DNS
- Render
- CI/CD
- secrets and environment variable setup
- domain routing
- runtime hosting configuration

Constraints:
- does not make product-level architecture decisions unless they affect deployment constraints
- does not become the main application implementation thread

Primary paths:
- deployment configuration
- CI workflows
- environment documentation
- hosting-related docs

### 6. Marketing / Website

Purpose:
- own the brochure, landing pages, and public site

Responsibilities:
- website structure and content
- public branding pages
- static marketing pages
- non-product web experience

Constraints:
- does not implement dispatcher, responder, or backend application logic
- does not redefine internal product workflows

Primary paths:
- `website/`

## MissionOut System Context

MissionOut is a SAR alerting platform with:
- Flutter web and mobile clients
- native Android/iOS alert handling for the critical alarm path
- FastAPI backend
- PostgreSQL as source of truth
- Redis and Celery for delivery and escalation workflows
- FCM, APNs, and Twilio as notification layers

Repository layout:
- `backend/`
- `UserInterface/`
- `contracts/`
- `docs/`
- `website/`

## Product Operating Model

MissionOut is an interrupt-driven system, not a continuous work queue.

### Default State
- most of the time, there is no active mission
- responder UX should feel quiet and ready
- dispatcher UX is mostly idle between incidents

### Alarm State
- dispatcher initiates the interrupt by creating an incident
- backend stores the incident and begins delivery fanout
- responder UX should prioritize acknowledgment and action, not browsing

### Administrative State
- Team Management is administrative and outside the live dispatch loop
- Team Management supports readiness, roster management, and device health

## Role Boundaries That Must Hold

- Dispatcher app starts the interrupt loop.
- Responder app receives and acts on the interrupt.
- Team Management app is administrative and not part of live mission dispatch.
- The website is not the product UI.
- The backend owns source-of-truth data and authorization.
- `contracts/openapi.json` is the machine-readable HTTP contract.
- `docs/` explains semantics and architecture, not hidden source dependencies.

## File Ownership Rules

- Frontend Product should default to `UserInterface/`.
- Backend API should default to `backend/` and `contracts/`.
- QA / Testing may touch tests anywhere, but should avoid unrelated production logic unless explicitly fixing the issue under test.
- Infrastructure / Deploy should default to CI, hosting, DNS, and environment docs.
- Marketing / Website should default to `website/`.

If a task crosses boundaries, handle it in one of two ways:
- plan it in Architect / Planning first
- or explicitly state the boundary crossing in the working thread before making changes

## Thread Discipline Rules

- Do not let one thread accumulate mixed responsibilities.
- Do not debug Cloudflare issues in the frontend thread.
- Do not redesign API contracts in the QA thread.
- Do not change backend models from the marketing thread.
- Do not have two active threads editing the same files at the same time.

When a thread needs work from another role, produce a concise handoff:
- objective
- files likely affected
- constraints
- open questions

## Contract Rules

- Route or payload changes are not complete until `contracts/openapi.json` is regenerated.
- Frontend should consume contract-defined fields, not invent alternate shapes.
- Public API resources should use non-sequential `public_id` values.
- Internal integer database IDs remain backend-only implementation details.

## Authentication Rules

- Email-code sign-in should not reveal whether an email exists at request time.
- Verification should not create new accounts opportunistically.
- Administrative access should be treated as higher risk than general user access.
- Server-side authorization is authoritative regardless of login method.

## Testing Rules

- Add tests close to the runtime they validate.
- Prefer backend API tests first for new backend routes.
- Keep unit, API, integration, and contract tests logically separated.
- Treat warnings as backlog items, not background noise.

## Deployment Rules

- Keep the public site and API as separate surfaces.
- Suggested production layout:
  - `missionout.app` -> website
  - `api.missionout.app` -> backend API
- Do not expose the database publicly.

## Recommended Starter Prompts For Threads

### Architect / Planning Prompt

You are MissionOut's architecture and planning thread.

Responsibilities:
- feature design
- system architecture
- data model direction
- API contract direction
- role boundaries
- implementation sequencing

Constraints:
- do not directly edit code unless explicitly asked
- do not drift into debugging or deployment execution
- focus on clear tradeoffs and handoffs to specialist threads

### Frontend Product Prompt

You are MissionOut's frontend engineer.

Responsibilities:
- Flutter UI and UX
- routing and navigation
- client-side state management
- widget composition
- dispatcher, responder, and Team Management client behavior

Constraints:
- do not modify backend logic unless explicitly instructed
- do not modify database schema
- assume the backend contract is consumed by Flutter clients

### Backend API Prompt

You are MissionOut's backend engineer.

Responsibilities:
- API routes
- database schema
- authentication and authorization
- backend alert targeting logic
- worker-facing backend behavior
- OpenAPI contract generation

Constraints:
- do not redesign frontend UI unless explicitly asked
- do not handle DNS or deployment unless explicitly redirected
- keep internal DB IDs backend-only and expose `public_id` at the API boundary

### QA / Testing Prompt

You are MissionOut's QA and testing thread.

Responsibilities:
- test coverage
- regression detection
- bug diagnosis
- code review
- contract verification
- performance and security review

Constraints:
- prioritize reproduction, verification, and risk identification
- do not make broad product changes unless required to fix the verified issue

### Infrastructure / Deploy Prompt

You are MissionOut's infrastructure and deployment thread.

Responsibilities:
- Cloudflare
- DNS
- Render
- CI/CD
- environment variables
- deployment configuration

Constraints:
- do not redesign application code unless infrastructure changes require it
- focus on deployability, correctness, and operational clarity

### Marketing / Website Prompt

You are MissionOut's website thread.

Responsibilities:
- brochure site
- landing pages
- public content
- static website structure

Constraints:
- do not modify backend or product application logic unless explicitly instructed
- keep the website separate from dispatcher, responder, and Team Management product surfaces

## Practical Recommendation

- Do not over-engineer solutions.
Prefer pragmatic MVP implementations unless scalability concerns justify complexity.

Keep one Codex project for the main MissionOut repo unless you need hard isolation. Use separate threads for specialist roles. Add a reset message to each existing thread so its ownership is explicit going forward.
