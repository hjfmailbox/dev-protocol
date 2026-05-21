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
- exactly ONE checkpoint commit created (no drift correction commit)
- last_commit = pre-commit HEAD (parent of the checkpoint commit)
- no early exit triggered
- `git diff last_commit..HEAD` shows only workflow-state.yml and handoff.md changes

Validation:

```powershell
Select-String "last_commit" .agent/dev-protocol/workflow-state.yml
git rev-parse HEAD
git rev-parse HEAD~1
git log --oneline -3
git status
git diff --stat last_commit..HEAD
```

PASS if:

- exactly one checkpoint commit created
- last_commit is a pure hash
- last_commit == HEAD~1 (pre-commit HEAD, parent of checkpoint commit)
- working tree clean
- `git diff last_commit..HEAD` shows only state file changes

FAIL if:

- self-drift exception triggered
- baseline remains empty
- more than one new commit created
- `git diff last_commit..HEAD` shows non-state files changed

---

## Step 3: Idempotent Checkpoint

Run:

/dev-checkpoint

Expected:

- self-drift early exit triggered (`git diff last_commit..HEAD` shows only prior checkpoint metadata)
- output: "No meaningful changes detected"
- no new commit created
- no state file modifications
- last_commit unchanged

Validation:

```powershell
git log --oneline -3
git status
git diff
Select-String "last_commit" .agent/dev-protocol/workflow-state.yml
git diff --stat last_commit..HEAD
```

PASS if:

- HEAD unchanged
- no new commit
- last_commit unchanged
- `git diff last_commit..HEAD` shows only prior checkpoint metadata

FAIL if:

- new checkpoint commit created
- workflow-state.yml modified
- checkpoint baseline changes unexpectedly

