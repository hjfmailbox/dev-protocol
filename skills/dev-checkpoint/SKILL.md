# /dev-checkpoint

## Purpose

Persist development state into durable project memory.

Goal:

After checkpoint, development can safely continue in a fresh context.

The next session must NOT depend on prior conversation history.

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

All state writes MUST target `.agent/dev-protocol/`:

- `.agent/dev-protocol/workflow-state.yml`
- `.agent/dev-protocol/handoff.md`
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

/dev-resume

Checkpoint fails if recovery confidence is low.

---

### 5. Prepare Commit

Must:

- stage required files
- generate commit message
- follow commit convention

### 6. Finalize (Single-Commit Guarantee)

Must produce exactly ONE checkpoint commit:

- Record `PRE_HEAD = git rev-parse HEAD` before committing.
- Write `checkpoint.last_commit = PRE_HEAD` (parent of the checkpoint commit).
- git add . + git commit → exactly one commit.
- Do NOT amend. Do NOT create a drift correction commit.

Note: `last_commit` is the parent hash, not the checkpoint hash itself.
A commit cannot contain its own hash — this is a fundamental constraint.
Early exit uses `git diff last_commit..HEAD` to detect self-drift.

Must summarize:

- state changes
- updated files
- next recommended actions

---

---

## Failure Rules

Checkpoint MUST fail if:

- workflow state is inconsistent
- critical memory is missing
- recovery confidence is low
- required synchronization is incomplete

Never partially succeed.

No commit on failure.
