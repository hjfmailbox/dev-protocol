# Case 05 - First Checkpoint Baseline Test

## Objective

Validate first checkpoint lifecycle without an existing baseline.

Flow:

/dev-bootstrap
→ /dev-checkpoint
→ /dev-checkpoint (idempotent)

---

## Step 1: Bootstrap

Run:

/dev-bootstrap

Expected:

- state files created
- no auto commit
- checkpoint.last_commit absent or empty
- no checkpoint baseline exists yet

Validation:

```powershell
Select-String "last_commit" .agent/dev-protocol/workflow-state.yml
git log --oneline -2
git status
```

PASS if:

- no bootstrap commit generated
- no business HEAD written into baseline

---

## Step 2: First Checkpoint

Run:

/dev-checkpoint

Expected:

- checkpoint baseline established
- one checkpoint commit created
- last_commit becomes previous HEAD hash
- no early exit triggered

Validation:

```powershell
Select-String "last_commit" .agent/dev-protocol/workflow-state.yml
git log --oneline -3
git status
git diff
```

PASS if:

- exactly one checkpoint commit created
- last_commit is a pure hash
- working tree clean

FAIL if:

- self-drift exception triggered
- baseline remains empty
- business commit message written into baseline

---

## Step 3: Idempotent Checkpoint

Run:

/dev-checkpoint

Expected:

- no meaningful changes detected
- no new commit created
- no state updates
- last_commit unchanged

Validation:

```powershell
git log --oneline -3
git status
git diff
Select-String "last_commit" .agent/dev-protocol/workflow-state.yml
```

PASS if:

- HEAD unchanged
- no new commit
- last_commit unchanged

FAIL if:

- new checkpoint commit created
- workflow-state.yml modified
- checkpoint baseline changes unexpectedly

