You are executing /dev-checkpoint.

> **DEPRECATED**: `/dev-checkpoint` is deprecated but supported. Use `/dev-save` instead.
> This command continues to function for backward compatibility, but its behavior is now aligned with `/dev-save`.

Your goal is to persist the current protocol state to durable files.

**Boundary**: /dev-checkpoint updates state files only. It does NOT implement, modify source code, stage files, or commit.

Proceed using `/dev-save` semantics. This is a STRICT operation. Partial success is failure.

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

"Can a fresh session using /dev-status reconstruct state?"

If NOT:

FAIL checkpoint.

---

## STEP 5: Update State Files Only

`/dev-checkpoint` no longer creates commits. Write state files only.

Update `.agents/dev-protocol/workflow-state.yml`:

- `checkpoint.last_commit` = current HEAD hash
- `checkpoint.last_updated` = current date
- `checkpoint.summary` = brief description of current state

Rules:

- MUST reflect current reality
- MUST NOT append history
- MUST overwrite outdated state
- MUST remove contradictions

---

## STEP 6: Validate and Output

Validate state consistency and output summary.

---

## STEP 7: Output Summary

If validation passes, output:

```
## /dev-checkpoint Complete

**Deprecated**: /dev-checkpoint is deprecated. Use /dev-save instead.

**Files Updated**:
- `.agents/dev-protocol/workflow-state.yml`
- `.agents/dev-protocol/handoff.md`

**Git Context**:
- Last commit: <hash>
- Branch: <branch>
- Workspace: <clean/dirty>

**Next Steps**:
1. Review updated state files
2. Persist state files through your normal version control workflow
```

---

## FAILURE POLICY

Checkpoint MUST FAIL if:

- workflow-state is inconsistent
- sync rules violated
- recoverability is low
- any critical file missing

NO partial success allowed.

---

## RULES

- NEVER guess missing state
- NEVER skip validation
- NEVER commit unsafe state
- NEVER continue after failure
- NEVER stage files
- NEVER auto-commit
---

## RULE ENFORCEMENT (ADDED)

Always re-parse project-rules.md and validate workflow-state.yml against it before writing state files.

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

---

## INCIDENT LOGGING

When checkpoint detects anomalies, log them.

### When to Log

| Condition | Type | Severity |
|-----------|------|----------|
| State validation fails (STEP 3) | `checkpoint-mismatch` | high |
| `last_commit` commit no longer exists | `checkpoint-stale` | medium |
| Artifact emission failure detected | `artifact-emission-failure` | high |
| State files contradict each other | `protocol-inconsistency` | medium |
| Workspace dirty during checkpoint | `dirty-checkpoint` | low |

### How to Log

1. Check if `.agents/dev-protocol/incidents.md` exists.
2. If not, create it with header:
   ```
   # Incidents

   Runtime protocol anomalies detected during command execution.
   ```
3. Append:
   ```
   ---

   ## <YYYY-MM-DD> /dev-checkpoint — <incident-type>

   **Context**: <what was detected>
   **Detection**: <how it was found>
   **Severity**: low | medium | high
   **Status**: open
   ```

### Rules

- Do NOT log for normal operations (no anomaly)
- Do NOT log for self-drift exception (expected behavior)
- Detect + record only. No auto-fix.
- Incident file is append-only