# /dev-checkpoint

> **DEPRECATED**: `/dev-checkpoint` is deprecated but supported. Use `/dev-save` instead.
>
> Behavior is now aligned with `/dev-save`. This skill remains callable for backward compatibility.

## Purpose

Persist development state into durable project memory.

Goal:

After checkpoint, development can safely continue in a fresh context.

The next session must NOT depend on prior conversation history.

---

## When to Use

- After completing meaningful development work
- Before running `/clear` to reset conversation
- At natural stopping points (end of task, end of session)
- After implementing a `/goal`

---

## When NOT to Use

- No changes since last state update (self-drift will skip anyway)
- Workspace is in an inconsistent state (fix first)
- You haven't run `/dev-init` yet (init first)
- Mid-implementation with incomplete work (commit or stash first)

---

## What It Does

1. Inspects changes since last state update
2. Updates state files to reflect current reality
3. Validates consistency between state, code, and docs
4. Records save metadata for future drift detection
5. Does NOT create commits or stage files

If no meaningful changes exist, exits early (self-drift exception).

---

## Typical Workflow

```
# After implementation
/dev-checkpoint
→ state reconciled and validated
→ safe to /clear
```

---

## Responsibilities

### 1. Inspect Changes

Must inspect:

- git diff
- git status
- newly added files
- modified docs
- workflow-related files

Must infer:

- what changed
- why it changed
- impact on project state

Must NOT rely only on memory.

---

### 1.5 Checkpoint Baseline Check (EARLY EXIT)

Must run BEFORE state reconciliation.

If `checkpoint.last_commit` is empty, absent, or null:

- Project has never been checkpointed.
- No baseline to compare against.
- Proceed to STEP 2 (normal checkpoint flow).

If `checkpoint.last_commit` has a value:

- Run `git diff --stat last_commit..HEAD`.
- If the diff shows ONLY changes to:
  - `workflow-state.yml` (checkpoint metadata)
  - `handoff.md` (prior checkpoint commit references)
  - No other files modified (no code, docs, config, tests)

Then:

- classify drift as `NONE`
- output "No meaningful changes detected"
- **IMMEDIATELY STOP — do NOT proceed to any subsequent responsibility**

---

### 2. Reconcile Project State

All state writes MUST target `.agents/dev-protocol/`:

- `.agents/dev-protocol/workflow-state.yml`
- `.agents/dev-protocol/handoff.md`
- relevant memory files
- affected documentation

MUST NOT create or update root-level copies of state files.
Root-level `workflow-state.yml`, `handoff.md`, `project-rules.md` exist for backward compatibility only.

Must prefer:

current truth over historical description.

Must update state, NOT append logs.

---

### 3. Validate Consistency

Must validate:

- workflow state matches repository reality
- handoff is current
- documentation is not obviously outdated
- required files are updated

Must detect high-confidence drift.

---

### 4. Validate Recoverability

Must verify a new agent can recover by using:

/dev-status

Checkpoint fails if recovery confidence is low.

### 5. Write State Files

Must:

- update state files only
- never stage files
- never commit
- follow commit convention in output recommendations only

---

---

## Failure Rules

Checkpoint MUST fail if:

- workflow state is inconsistent
- critical memory is missing
- recovery confidence is low
- required synchronization is incomplete

Never partially succeed.

No state write on failure.
