You are executing /dev-doctor for a software project.

Your goal is to diagnose dev-protocol health issues.
You MUST NOT modify any files or commit anything.

---

## STEP 1: Check Workspace

Run:

```
git status --short
git status
```

Classify:

- Clean working tree → OK
- Modified/staged/untracked files → WARNING

Record findings.

---

## STEP 2: Check State Files

For each required file:

- `.agents/dev-protocol/workflow-state.yml`
- `.agents/dev-protocol/handoff.md`
- `.agents/dev-protocol/project-rules.md`

Check:

- exists?
- non-empty?
- readable?

Also check for duplicates in:

- repository root
- `.agent/dev-protocol/` (legacy path)

Classify:

- All present, non-empty, no duplicates → OK
- Duplicates found → WARNING
- Any missing → ERROR
- Any empty → WARNING

---

## STEP 3: Check Checkpoint Drift

Read `checkpoint.last_commit` from `.agents/dev-protocol/workflow-state.yml`.

### If empty or absent:

- Output: "No checkpoint baseline — first checkpoint not yet run"
- Classification: OK (informational)
- Skip to STEP 4

### If has a value:

Run:

```
git cat-file -t <last_commit>
git log --oneline -1 <last_commit>
git rev-list --count <last_commit>..HEAD
```

Classify:

- Commit exists, distance ≤ 20 → OK
- Commit exists, distance > 20 → WARNING (stale checkpoint)
- Commit does not exist → ERROR (rebased or force-pushed away)

---

## STEP 4: Check Git Health

Run:

```
git rev-parse --is-inside-work-tree
git symbolic-ref HEAD 2>/dev/null || echo "DETACHED"
git status --porcelain | grep "^UU\|^AA\|^DD"
```

Classify:

- Inside work tree, on branch, no conflicts → OK
- Detached HEAD → WARNING
- Merge conflicts present → ERROR
- Not a git repository → ERROR

---

## STEP 5: Check State Consistency

Read state files and cross-check:

1. `workflow-state.yml` `current_state.phase` — does it mention a phase?
2. `handoff.md` — does it reference the same phase?
3. `workflow-state.yml` `current_state.status` — does it match `handoff.md` status?
4. `progress.completed` — do listed items correspond to actual git history?

Classify:

- All consistent → OK
- Minor mismatch (e.g., handoff slightly behind) → WARNING
- Major contradiction (state says complete, git shows otherwise) → ERROR

---

## STEP 6: Generate Report

Output:

```
=== dev-protocol Diagnostic Report ===

[OK/WARNING/ERROR] Workspace
  Detail: <clean or list of dirty files>
  Recommendation: <if dirty: commit or stash before checkpoint>

[OK/WARNING/ERROR] State Files
  Detail: <which files present/missing/empty>
  Recommendation: <if missing: run /dev-bootstrap>

[OK/WARNING/ERROR] Checkpoint Drift
  Detail: <last_commit status and distance>
  Recommendation: <if stale: run /dev-checkpoint to refresh>

[OK/WARNING/ERROR] Git Health
  Detail: <branch state, conflicts>
  Recommendation: <if issues: resolve manually>

[OK/WARNING/ERROR] State Consistency
  Detail: <contradictions found>
  Recommendation: <if inconsistent: run /dev-bootstrap to reconstruct>

Summary:
  OK: N
  Warnings: N
  Errors: N

Overall: HEALTHY | DEGRADED | UNHEALTHY
=== End Report ===
```

---

## RULES

- NEVER modify files
- NEVER commit
- NEVER auto-repair
- ALWAYS output the full report even if errors found
- ALWAYS provide actionable recommendations for each finding
- If a check cannot run (e.g., git unavailable), report partial results
