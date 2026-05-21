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

- If the ONLY changes since `last_commit` are:
  - `workflow-state.yml` metadata fields (last_commit, summary, last_updated)
  - `handoff.md` commit references pointing to prior checkpoint commits
  - No other files modified (no code, docs, config, tests)

Then:

- classify drift as `NONE`
- output "No meaningful changes detected"
- **IMMEDIATELY STOP — do NOT proceed to any subsequent responsibility**

---

### 2. Reconcile Project State

Must update:

- workflow-state.yml
- handoff.md
- relevant memory files
- affected documentation

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

---

### 6. Finalize

Must summarize:

- state changes
- updated files
- next recommended actions

---

## Failure Rules

Checkpoint MUST fail if:

- workflow state is inconsistent
- critical memory is missing
- recovery confidence is low
- required synchronization is incomplete

Never partially succeed.

No commit on failure.
