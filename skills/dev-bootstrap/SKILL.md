# /dev-bootstrap

## Purpose

Initialize dev protocol on an existing or new project.

Goal:

Convert a project into a recoverable development state.

After bootstrap, the project must support:

- /dev-resume
- /dev-checkpoint
- safe context reset

---

## Responsibilities

### 1. Inspect Project

Must inspect:

- git status
- git history (recent)
- project structure
- docs
- existing memory files
- workflow files
- architecture-related files

Must NOT rely on assumptions.

---

### 2. Reconstruct Current State

Infer:

- current phase
- current focus
- active work
- blockers
- likely next steps

Must prefer current code reality over outdated docs.

---

### 3. Initialize Protocol Files

Create or update:

- workflow-state.yml
- handoff.md
- project-rules.md

Must preserve useful existing information.

---

### 4. Detect Drift

Detect mismatch between:

- code
- docs
- memory
- workflow state

Must explicitly report high-confidence drift.

---

### 5. Review Before Commit

Bootstrap MUST NOT auto commit.

Agent must:

- summarize changes
- show generated state
- request review

---

## Failure Rules

Bootstrap fails if:

- repository cannot be inspected
- project structure is unreadable
- state reconstruction confidence is too low
