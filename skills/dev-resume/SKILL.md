# /dev-resume

## Purpose

Recover development context from durable project state.

Goal:

Allow development to continue without prior chat history.

---

## Responsibilities

### 1. Read Recoverable State

Must read:

- workflow-state.yml
- handoff.md
- project-rules.md

If available, also inspect:

- CLAUDE.md
- AGENTS.md
- project memory files

---

### 2. Inspect Repository State

Must inspect:

- git status
- uncommitted changes
- recent commits

Must warn if repository is dirty.

---

### 3. Validate State Freshness

Check for mismatch between:

- workflow state
- repository reality

Examples:

- task marked completed but unfinished
- docs contradict code
- handoff appears outdated

Must warn on inconsistency.

---

### 4. Generate Recovery Summary

Must summarize:

- current phase
- active focus
- completed progress
- blockers
- recommended next actions

Summary should be concise and action-oriented.

---

## Failure Rules

Resume fails if:

- recoverable state is missing
- repository is corrupted
- state inconsistency is too severe

Must recommend:

/dev-bootstrap
if recoverable state does not exist.
