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

## When to Use

- First time adopting dev-protocol on a project
- State files are missing or corrupted
- After accidentally deleting `.agents/dev-protocol/`
- Switching to a new branch that needs its own state

---

## When NOT to Use

- State files already exist and are current (use `/dev-resume` instead)
- You just want to save progress (use `/dev-checkpoint` instead)
- You want to recover context after `/clear` (use `/dev-resume` instead)

---

## What It Does

Inspects the project (git history, code, docs) and creates three state files in `.agents/dev-protocol/`:

- `workflow-state.yml` — machine-readable progress
- `handoff.md` — human-readable session handoff
- `project-rules.md` — project constraints

Does NOT auto-commit. Does NOT modify existing code.

**Important**: Bootstrap is detect + recommend, NOT detect + mutate.

---

## Typical Workflow

```
# Fresh or existing project
/dev-bootstrap
→ review generated state files
→ git add .agents/
→ git commit -m "chore(protocol): initialize dev-protocol"
→ /dev-checkpoint
```

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

### 2.5 State File Location Policy

All state files MUST be written to `.agents/dev-protocol/`:

- `.agents/dev-protocol/workflow-state.yml`
- `.agents/dev-protocol/handoff.md`
- `.agents/dev-protocol/project-rules.md`

Root-level copies (`workflow-state.yml`, `handoff.md`, `project-rules.md`) exist for backward compatibility only.
MUST NOT create, update, or reconcile root-level copies during bootstrap.

---

### 3. Initialize Protocol Files

Create or update in `.agents/dev-protocol/`:

- workflow-state.yml
- handoff.md
- project-rules.md

Must preserve useful existing information.

Must set `checkpoint.last_commit` to empty/absent — no checkpoint baseline
exists until the user explicitly runs /dev-checkpoint.

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
