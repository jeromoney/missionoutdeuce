---
name: api-integration
description: Guided workflow for wiring a new OpenAPI endpoint into the MissionOut Flutter app — model generation, service layer, state management, error handling, and loading states. Use when adding or updating an API-backed feature.
---

When integrating a new API endpoint into MissionOut:

**1. Contract first**
- Read `../contracts/openapi.json` to confirm the exact request/response shape before writing any code
- Never invent or patch the API shape — if the contract looks wrong, flag it for the backend engineer
- Identify: HTTP method, path, path/query params, request body, success response, error responses

**2. Models (`shared_models/`)**
- Add or update Dart model classes in `shared_models/`
- Use `fromJson`/`toJson` — check if the project uses `json_serializable` or manual parsing and follow the existing pattern
- Keep models free of UI or business logic

**3. Service / API client layer**
- Add the endpoint call to the appropriate service class (check existing services before creating new ones)
- Return typed results — prefer a `Result<T, Error>` or similar pattern if already established in the codebase
- Handle HTTP error codes explicitly (401, 403, 404, 422, 5xx)

**4. State management**
- Follow the existing pattern in the target sub-app (dispatcher/, responder/, or team_admin/)
- Expose: loading state, data state, error state — never leave error handling implicit
- Avoid duplicating state that already lives in another provider/bloc

**5. UI wiring**
- Show a loading indicator during the request
- Show a user-facing error message on failure (not just a console log)
- Handle empty/null responses gracefully
- Confirm the happy path and at least one error path work before marking done

**6. Auth**
- All authenticated endpoints must pass the token from `shared_auth/`
- Do not hardcode tokens or bypass auth for convenience

Always walk through these steps in order. If a step reveals a contract ambiguity or missing backend capability, stop and surface it rather than working around it.
