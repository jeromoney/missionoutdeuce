# Team Admin does not consume incident data

The Team Management app is administrative and sits outside the live dispatch interrupt loop (see `AGENTS.md` Product Operating Model and `docs/boundaries.md`). Incidents and response records are owned by the dispatcher app and consumed by the responder app; team admin only manages readiness — memberships, roles, and device health.

We decided that team admin must not call `/incidents` or model `Incident` / `ResponseRecord` data. Any team admin UI that surfaced incidents or responses (for example `TeamIncidentSummary`, `TeamResponseSummary`) should be removed rather than refactored to share the dispatcher/responder *Incident* type.

This is recorded so future architecture reviews do not propose unifying incident decoding across all three Flutter apps. The fact that team admin once held an inline `/incidents` projection is a boundary leak, not a missing abstraction.
