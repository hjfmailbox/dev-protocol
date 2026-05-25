# /dev-save

## Purpose

Persist protocol state to durable files.

Goal:

Update `.agents/dev-protocol/` state files so the current development context survives session resets.

After /dev-save, a fresh session can reconstruct context by reading state files.

**Boundary rule**: /dev-save persists state only. It does NOT implement, modify source code, stage files, or commit.

---

## When to Use

- After completing meaningful work within a scoped goal
- Before starting a new session
- When protocol state is stale relative to repository reality
- After /dev-status reveals drift that needs recording

---

## When NOT to Use

- No state files exist yet (use /dev-init first)
- Workspace has uncommitted source code changes that should be committed first
- You want to declare a new goal (use /dev-scope instead)
- You want to inspect state (use /dev-status instead)

---

## What It Does

1. Validates preconditions (state files exist, workspace is saveable)
2. Inspects current repository reality (git status, current commit)
3. Updates `workflow-state.yml` with current checkpoint metadata
4. Updates `handoff.md` with current focus, progress, blockers, next actions
5. Validates state consistency and recoverability
6. Reports what was updated and what remains for the user to do

---

## Typical Workflow

```
/dev-save
-> state files updated and validated
-> user stages and commits state files
-> safe to start new session
```

---

## Responsibilities

### 1. Validate Preconditions

Must verify:

- `.agents/dev-protocol/workflow-state.yml` exists
- `.agents/dev-protocol/handoff.md` exists
- Git repository is initialized

If state files missing:
STOP and report: "State files not found. Run /dev-init to initialize."

### 2. Inspect Repository Reality

Collect:

- `git rev-parse HEAD` — current commit hash
- `git status --short` — dirty/clean state, untracked files
- Current branch name

Use git-derived values. Never assume branch names.

### 3. Update workflow-state.yml

Must update:

- `checkpoint.last_commit` — current HEAD hash
- `checkpoint.last_updated` — current date
- `checkpoint.summary` — brief description of current state
- `current_state.phase` — if changed
- `current_state.focus` — current focus
- `progress.completed` — if new items completed
- `progress.in_progress` — current tasks
- `progress.blocked` — any blockers

Must NOT append history. Must overwrite outdated state.

### 4. Update handoff.md

Must update:

- **Current Focus** — what is being worked on
- **Current Status** — active, blocked, etc.
- **Completed Since Last Save** — recent accomplishments
- **In Progress** — ongoing tasks
- **Blockers** — anything preventing progress
- **Next Recommended Actions** — concrete next steps
- **Notes For Next Session** — critical context

Must reflect current reality, not planned future state.

### 5. Validate State Consistency

Must verify:

- `workflow-state.yml` is valid YAML
- Required fields are present
- `checkpoint.last_commit` is a valid hash
- State content is internally consistent
- No corruption detected

If validation fails:
FAIL. Do NOT write files. Report specific failures.

### 6. Validate Recoverability

Simulate:

"Can a fresh session using /dev-status reconstruct meaningful context from these state files?"

If NOT:
FAIL. Report why recovery is insufficient.

---

## Hard Constraints

- **NEVER mutate source code**
- **NEVER stage files**
- **NEVER auto-commit**
- **NEVER partially succeed**
- **Prefer current truth over historical description**
- **State files only** — only write to `.agents/dev-protocol/`

---

## Failure Rules

/dev-save fails if:

- state files do not exist
- required fields are missing
- state validation fails
- recoverability validation fails
- any corruption detected
