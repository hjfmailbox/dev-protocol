# /dev-save

## Purpose

Persist protocol state to durable files.

Goal:

Update `.agents/dev-protocol/` state files so the current development context survives session resets.

After /dev-save, a fresh session can reconstruct context by reading state files.

**Boundary rule**: /dev-save persists state and commits it automatically. It does NOT implement, modify source code, stage non-protocol files, or ask for confirmation.

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
3. Updates `workflow-state.yml` save-tracking fields
4. Updates `handoff.md` with current focus, progress, blockers, next actions
5. Validates state consistency and recoverability
6. Reports what was updated

---

## Typical Workflow

```
/dev-save
-> state files updated and validated
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

Must update save-tracking fields:

- `checkpoint.last_commit` — current HEAD hash (persistence tracking)
- `checkpoint.last_updated` — current date (persistence tracking)
- `checkpoint.summary` — brief description of current state (persistence tracking)
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

## Preconditions

- `.agents/dev-protocol/workflow-state.yml` exists
- `.agents/dev-protocol/handoff.md` exists
- Git repository is initialized
- `git rev-parse HEAD` succeeds

## DO

- Stage ONLY `.agents/dev-protocol/*` files
- Create protocol commit with `chore(checkpoint):` prefix
- Update `checkpoint.last_commit` to current HEAD
- Validate state consistency before committing
- Allow no-op saves on clean workspace
- Report "Workflow completed" and "No remaining protocol tasks" on success

## DO NOT

- **NEVER stage or commit source code files**
- **NEVER stage or commit non-protocol files**
- **NEVER create mixed commits** (protocol + source changes together)
- **NEVER proceed if both protocol files AND source files are staged**
- **NEVER ask for confirmation** -- commit automatically
- **NEVER mutate source code**
- **NEVER partially succeed**
- **Prefer current truth over historical description**
- **State files only** -- only write to `.agents/dev-protocol/`

## Hard Constraints

- **NEVER mutate source code**
- **NEVER stage non-protocol files**
- **NEVER create mixed commits**
- **NEVER ask for confirmation** — commit automatically
- **NEVER partially succeed**
- **Prefer current truth over historical description**
- **State files only** — only write to `.agents/dev-protocol/`
- **ALWAYS create a protocol commit** after updating state files

---

## Telemetry

Record the following events using `.agents/dev-protocol/runtime-telemetry/telemetry.ps1`.

Telemetry is optional: if the script is missing or config disables it, skip silently.

### command_invoked

Record at the start of execution:

```powershell
.telemetry.ps1 -EventType command_invoked -Command '/dev-save'
```

### command_result

Record before returning output:

```powershell
.telemetry.ps1 -EventType command_result -Command '/dev-save' -Status 'success'
```

If execution fails (state files missing, validation failure, recoverability failure, corruption):

```powershell
.telemetry.ps1 -EventType command_result -Command '/dev-save' -Status 'failure' -Reason '<specific failure>'
```

### session_context_snapshot

Record after validating state consistency:

```powershell
.telemetry.ps1 -EventType session_context_snapshot -Phase '<phase>' -Focus '<focus>' -Freshness '<freshness>' -CheckpointCommit '<hash>' -HeadCommit '<hash>' -ActiveWork '<theme>'
```

## Failure Rules

/dev-save fails if:

- state files do not exist
- required fields are missing
- state validation fails
- recoverability validation fails
- any corruption detected
- mixed staged files detected (both protocol and source files staged)
