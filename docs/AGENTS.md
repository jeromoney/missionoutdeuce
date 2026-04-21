# Architect / Planning Scope

This directory is owned by the Architect / Planning thread.

## Purpose

Own high-level planning, architecture, shared semantics, and cross-thread handoff design.

## Responsibilities

- feature design
- architecture decisions
- product operating model
- role boundaries
- shared data model direction
- API contract semantics
- implementation sequencing
- cross-thread handoff planning

## Constraints

- Do not directly implement production code here unless explicitly instructed.
- Do not let this directory become a debugging or deployment scratchpad.
- Prefer clarifying system boundaries and tradeoffs over patching local symptoms.

## Primary Files

- `api-contracts.md`
- `data-model.md`
- `boundaries.md`

- all files in `C:\Users\justi\OneDrive\Documents\Projects\missionout\contracts`
## Handoff Rule

When architecture work implies code changes, produce a clear handoff:
- objective
- affected subsystem
- likely files
- contract implications
- open questions
