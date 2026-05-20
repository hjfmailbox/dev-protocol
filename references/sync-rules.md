# Sync Rules

## Principle

Code changes must synchronize related durable knowledge.

Prefer updating current truth over appending history.

---

## API Changes

Examples:

- new endpoint
- request/response change
- auth change

Must sync:

- documentation
- integration guide
- workflow state
- handoff

---

## Architecture Changes

Examples:

- module boundaries
- system design
- infrastructure
- database change

Must sync:

- architecture docs
- project-rules.md
- workflow state
- handoff

---

## Workflow Changes

Examples:

- new phase
- changed priorities
- blocker resolved

Must sync:

- workflow-state.yml
- handoff.md

---

## Configuration Changes

Examples:

- env vars
- build config
- deployment config

Must sync:

- documentation
- project-rules.md
- handoff

---

## Dependency Changes

Examples:

- package changes
- framework upgrade

Must sync:

- documentation
- workflow state if impactful

---

## Bug Fixes

Small fixes:

- workflow-state only if relevant

Major fixes:

- handoff
- project-rules if new pitfall discovered

---

## Refactor

Minor refactor:

- no sync required

Behavioral refactor:

- docs
- architecture docs
- handoff

---

## Source of Truth

When conflict exists:

1. Running code
2. Repository reality
3. Workflow state
4. Documentation
5. Historical notes
