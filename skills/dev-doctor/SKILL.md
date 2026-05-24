# /dev-doctor

## Purpose

Lightweight diagnosis of dev-protocol health issues.

Goal:

Detect and explain protocol anomalies without automatic repair.

---

## When to Use

- `/dev-resume` reports unexpected state
- `/dev-checkpoint` fails without clear reason
- Suspect checkpoint drift or missing state files
- Onboarding a project and want to verify protocol health
- After git operations (rebase, merge, reset) that may affect state

---

## When NOT to Use

- Normal workflow (use `/dev-resume` and `/dev-checkpoint` directly)
- You want automatic repair (dev-protocol v1 does not auto-repair)
- Simple questions about usage (use `/dev-help`)

---

## What It Does

Runs a series of diagnostic checks and reports findings:

1. **Dirty workspace** — uncommitted changes that may interfere with checkpoint
2. **Missing state files** — required files absent from `.agents/dev-protocol/`
3. **Checkpoint drift** — `last_commit` points to a commit that no longer exists
4. **Runtime path problems** — state files in unexpected locations
5. **Git issues** — detached HEAD, merge conflicts, no commits yet
6. **Inconsistent protocol state** — state file contradictions

Constraint: **diagnose only**. No automatic repair.

---

## Typical Workflow

```
/dev-doctor
→ review diagnostic report
→ fix issues manually based on recommendations
→ /dev-checkpoint (if fixes applied)
```

---

## Responsibilities

### 1. Check Workspace Cleanliness

Run:

- `git status`

Report:

- modified files
- untracked files
- staged but uncommitted changes

Severity:

- Clean → INFO
- Dirty → WARNING (may interfere with checkpoint)

---

### 2. Check State File Presence

Check for required files in `.agents/dev-protocol/`:

- `workflow-state.yml`
- `handoff.md`
- `project-rules.md`

Report:

- which files exist
- which files are missing
- file sizes (detect empty placeholder files)

Severity:

- All present and non-empty → OK
- Any missing → ERROR
- Any empty → WARNING

---

### 3. Check Checkpoint Drift

If `checkpoint.last_commit` has a value:

Run:

- `git cat-file -t <last_commit>` (check if commit exists)
- `git log --oneline -1 <last_commit>` (show the commit)

Report:

- whether `last_commit` exists in current history
- whether it was rebased away
- distance from `last_commit` to HEAD (commit count)

Severity:

- Commit exists → OK
- Commit missing → ERROR (rebase or force-push may have removed it)
- Large distance (>20 commits) → WARNING (stale checkpoint)

---

### 4. Check Runtime Path

Verify state files are NOT duplicated in:

- repository root (legacy location)
- `.agent/dev-protocol/` (old path)

Report:

- primary location resolved
- any duplicate locations found

Severity:

- Single location → OK
- Duplicates → WARNING (may cause confusion)

---

### 5. Check Git Health

Run:

- `git rev-parse --is-inside-work-tree`
- `git symbolic-ref HEAD` (check for detached HEAD)
- `git status --porcelain` (conflict detection)

Report:

- whether inside a git repository
- current branch or detached state
- merge conflicts

Severity:

- Normal → OK
- Not a git repo → ERROR
- Detached HEAD → WARNING
- Merge conflicts → ERROR

---

### 6. Check State Consistency

Cross-check:

- `workflow-state.yml` phase vs `handoff.md` phase references
- `workflow-state.yml` status vs `handoff.md` status
- `progress.completed` items vs git log reality

Report:

- contradictions found
- stale references

Severity:

- Consistent → OK
- Minor inconsistency → WARNING
- Major contradiction → ERROR

---

### 7. Generate Diagnostic Report

Output format:

```
=== dev-protocol Diagnostic Report ===

[OK/WARNING/ERROR] Check Name
  Detail: <explanation>
  Recommendation: <manual fix suggestion>

...

Summary:
  OK: <count>
  Warnings: <count>
  Errors: <count>

Overall: HEALTHY | DEGRADED | UNHEALTHY
=== End Report ===
```

Classification:

- **HEALTHY**: all checks OK
- **DEGRADED**: warnings present, no errors
- **UNHEALTHY**: one or more errors

---

## Failure Rules

`/dev-doctor` should not fail under normal conditions.

If git is unavailable or repository is corrupted:

- Report the specific failure
- Recommend manual intervention
- Still output partial results for checks that succeeded
