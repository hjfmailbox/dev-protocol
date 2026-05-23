You are executing /dev-checkpoint for a software project.

Your goal is to safely persist the current development state
so that the project can be fully recovered later via /dev-resume.

This is a STRICT operation. Partial success is failure.

---

## STEP 1: Inspect Changes

Collect:

- git diff (staged + unstaged)
- git status
- new/modified/deleted files
- documentation changes

Infer:

- what changed
- why it changed
- impact scope

---

## STEP 1.5: Checkpoint Baseline Check (EARLY EXIT)

Check `workflow-state.yml.checkpoint.last_commit`.

### Case A — No Baseline Exists

If `last_commit` is empty, absent, or null:

- This project has never been checkpointed.
- Do NOT compare diff against a non-existent baseline.
- Self-drift detection does NOT apply.
- Proceed directly to STEP 2 (normal checkpoint flow).

### Case B — Baseline Exists

If `last_commit` has a value:

Run:

```
git diff --stat last_commit..HEAD
```

If the diff output shows ONLY changes to:

- `workflow-state.yml` (checkpoint metadata fields: last_commit, summary, last_updated)
- `handoff.md` (commit references pointing to prior checkpoint commits)

And NO other files changed (no code, no docs, no config, no tests):

- The only commit between `last_commit` and HEAD is a prior checkpoint commit.
- This is the self-drift exception.
- Output:
  ```
  === Self-Drift Exception Triggered ===
  Drift: NONE
  Cause: Only previous checkpoint metadata changed (baseline = last_commit)
  No meaningful changes detected
  === Checkpoint Skipped (STOP) ===
  ```
- **IMMEDIATELY STOP. Do NOT execute any subsequent STEP.**
- Do NOT update any state files.
- Do NOT create any commit.
- Do NOT proceed to STEP 2.

This is a HARD STOP. The checkpoint flow terminates here.

Otherwise:

- There are meaningful changes since `last_commit`.
- Continue to STEP 2.

---

## STEP 2: Reconcile State

All state writes MUST target `.agents/dev-protocol/`:

- `.agents/dev-protocol/workflow-state.yml`
- `.agents/dev-protocol/handoff.md`
- `.agents/dev-protocol/project-rules.md` (if impacted)

MUST NOT create or update root-level copies of state files.
Root-level files exist for backward compatibility only.

Rules:

- MUST reflect current reality
- MUST NOT append history
- MUST overwrite outdated state
- MUST remove contradictions

---

## STEP 3: Synchronization Check

Using sync-rules:

Validate required updates for:

- API changes
- architecture changes
- workflow changes
- config changes
- dependency changes

If required sync is missing:

FAIL checkpoint.

---

## STEP 4: Recoverability Validation

Simulate:

"Can a fresh session using /dev-resume reconstruct state?"

If NOT:

FAIL checkpoint.

---

## STEP 5: Generate Commit

Create commit message following commit-rules:

Format:
<type>(<scope>): <summary>

Must reflect:

- dominant change
- correct scope
- concise reasoning

---

## STEP 6: Commit

Execute exactly ONE checkpoint commit.

Record current HEAD before committing:

```
PRE_HEAD = git rev-parse HEAD
```

Write into `workflow-state.yml.checkpoint`:

- `last_commit` = `PRE_HEAD` (the parent of the checkpoint commit)
- `summary` = the commit summary

Then:

- git add .
- git commit (using message from STEP 5)

CRITICAL:

- Do NOT create a separate drift correction commit.
- Do NOT amend after the initial commit.
- If commit fails, FAIL checkpoint.

Note: `last_commit` is the PARENT of the checkpoint commit.
This is by design — a commit cannot contain its own hash.
Early exit (STEP 1.5) must compare diff since `last_commit`, not HEAD.

---

## STEP 7: Output Summary

Return:

- changes detected
- files updated
- sync performed
- commit message
- recovery confidence

---

## FAILURE POLICY

Checkpoint MUST FAIL if:

- workflow-state is inconsistent
- sync rules violated
- recoverability is low
- any critical file missing
- commit is not possible

NO partial success allowed.

---

## RULES

- NEVER guess missing state
- NEVER skip validation
- NEVER commit unsafe state
- NEVER continue after failure
---

## RULE ENFORCEMENT (ADDED)

Always re-parse project-rules.md and validate workflow-state.yml against it before committing.

---

## STRICT VALIDATION MODE (A-LINE)

### 1. State Strict Validation

Before writing any updates to workflow-state.yml:

- progress.completed MUST only include actions that are:
  - actually executed
  - reflected in git history OR filesystem changes
- DO NOT include:
  - planned tasks
  - design tasks
  - bootstrap intentions

If violation detected:
→ mark state validity = FAIL
→ stop checkpoint update

---

### 2. Explicit Validation Output (MANDATORY)

At end of checkpoint, output:

- state validity: PASS | FAIL
- rule compliance: PASS | FAIL
- drift severity: NONE | LOW | HIGH

---

### 3. Drift Classification Rules

### 3.1 Checkpoint Self-Drift Exception

SPECIAL RULE:

If the ONLY detected drift is caused by a previous `/dev-checkpoint` commit, including:

- `workflow-state.yml.checkpoint.last_commit`
- `workflow-state.yml.checkpoint.summary`
- `workflow-state.yml.checkpoint.last_updated`
- commit references inside `handoff.md`
- state metadata generated by checkpoint itself

Then:

- classify drift as `NONE`
- output self-drift summary with "No meaningful changes detected"
- **IMMEDIATELY STOP the checkpoint flow**
- do NOT update any state files
- do NOT create a commit
- do NOT proceed to any subsequent validation or sync step

This is a HARD STOP, not a classification note.
The checkpoint flow MUST terminate at this point.

- NONE: no code/state mismatch
- LOW: minor doc-state inconsistency
- HIGH: state contradicts git or filesystem reality

---

### 4. Hard Rule

Checkpoint MUST NOT silently correct invalid state.

It must:
- detect
- report
- then decide to proceed or fail