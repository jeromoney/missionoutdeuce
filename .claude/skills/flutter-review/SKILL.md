---
name: flutter-review
description: Checklist-driven code review for MissionOut Flutter widgets, state management, and tests. Use when reviewing a widget, screen, or PR for correctness, performance, and maintainability.
---

When reviewing Flutter code in MissionOut, evaluate each of the following:

**Widget correctness**
- [ ] `const` constructors used wherever possible
- [ ] No logic or side effects in `build()` — build should be a pure function of state
- [ ] `StatefulWidget` only used when local ephemeral state is genuinely needed; prefer stateless + external state
- [ ] `Key` usage is intentional — list items with dynamic order should use keys
- [ ] No `setState` called after `dispose` (guard with `mounted` check)

**Performance**
- [ ] No unnecessary widget rebuilds — large subtrees that don't change are wrapped in `const` or extracted
- [ ] `ListView.builder` (not `ListView`) for long/dynamic lists
- [ ] Images use `cacheWidth`/`cacheHeight` or appropriate asset resolution
- [ ] No expensive computation inside `build()` — move to `initState`, a provider, or a cached getter

**State management**
- [ ] State lives at the right level — not hoisted higher than needed, not duplicated
- [ ] Follows the existing pattern for the sub-app (dispatcher/, responder/, team_admin/)
- [ ] Loading, data, and error states are all handled — no implicit "it'll always succeed" assumption
- [ ] No raw `Future` awaited in `build()` — use `FutureBuilder` or state notifier

**Shared packages**
- [ ] Theme values come from `shared_theme/` — no hardcoded colors, text styles, or spacing magic numbers
- [ ] Models come from `shared_models/` — no duplicate or local-only model definitions
- [ ] Auth tokens sourced from `shared_auth/` — not passed ad hoc or hardcoded

**Accessibility**
- [ ] Interactive elements have `Semantics` labels or use widgets that provide them (e.g., `Tooltip`, `IconButton` with `tooltip`)
- [ ] Touch targets are at least 48x48dp
- [ ] Text contrast meets WCAG AA

**Tests**
- [ ] New widgets have at least one widget test covering the happy path
- [ ] Edge cases (empty list, error state, loading state) have test coverage
- [ ] Tests do not rely on implementation details — test behavior, not internals

Flag anything that fails a check with a specific line reference and suggested fix. If a pattern looks intentional but unusual, ask before flagging it as a bug.
