# Case 06 - Goal Workflow Test

## Objective

Validate `/goal`-based development workflow in a target project.

Flow:

Set goal → iterate → validate → complete

---

## Preconditions

- Target project workspace available
- Clean git state before any test operation:

```powershell
git status
git diff
git diff --cached
git log --oneline -3
```

- No uncommitted tracked changes
- No staged changes
- Recent commit history visible

---

## Goal Execution

1. Set `/goal` in the target project
2. Iterate on the goal within the workspace
3. Validate workspace state after iterations
4. Complete or revise goal

---

## Validation Commands

```powershell
git status
git diff
git log --oneline -3
```

---

## PASS Conditions

Automated assertions (all must pass):

- git workspace clean before test start
- no staged changes
- no untracked + non-ignored files
- test-plan.md exists
- recent commit history available (≥1 commit)
- HEAD is not a checkpoint commit
- HEAD commit changed ≤10 files (scope respected)
- HEAD commit has non-zero content changes (not empty or metadata-only)
- HEAD commit follows conventional commit format
- goal-output.json exists in .agent/dev-protocol/
- goal-output.json is valid JSON
- all required top-level fields present (goal_status, goal_summary, changed_files, validation_results, stop_reason, risks_followups, continuation_handoff)
- goal_status is one of: COMPLETED, PARTIALLY_COMPLETED, BLOCKED, FAILED, ABORTED
- continuation_handoff has all 4 non-empty sub-fields (context, boundary, next_candidate_goal, prompt_seed)
- changed_files matches git diff-tree HEAD commit exactly

Manual review (after automated pass):

- `/goal` workflow completed without errors
- workspace consistent after completion
- goal scope matches intended change
- file-level quality of changes (correct content, not just present files)

---

## FAIL Conditions

Automated failures (any triggers FAIL immediately):

- Dirty workspace before test start
- Uncommitted tracked changes
- Staged changes detected
- Untracked + non-ignored files detected
- HEAD is a checkpoint commit (wrong workflow executed)
- HEAD commit exceeds scope threshold (>10 files)
- HEAD commit has zero content lines (empty or metadata-only)
- HEAD commit message breaks conventional commit format
- goal-output.json missing
- goal-output.json malformed JSON
- missing required top-level fields
- goal_status not a valid enum value
- continuation_handoff missing or empty sub-fields
- changed_files does not match HEAD commit

Manual review failures:

- `/goal` workflow aborts
- Workspace inconsistent after completion (file content mismatch)

---

## Goal Stop Conditions

Development must stop when any of the following conditions are met:

1. **Explicit completion**
   - Requested change implemented
   - Goal scope fully addressed

2. **Validation success**
   - Relevant tests pass
   - Validation commands show expected state
   - No new regressions detected

3. **Blocked state**
   - Missing requirements prevent progress
   - Ambiguity requiring user decision
   - Repeated failed attempts with no clear path forward

4. **Safety condition**
   - Dirty git workspace detected
   - Unexpected broad file modifications outside goal scope
   - Validation detects high-confidence inconsistency

---

## Validation Strategy

Automated validation covers:

- Workspace cleanliness (git diff, staged changes, untracked files)
- Commit integrity (conventional format, content changes, scope limit)
- Workflow correctness (not a checkpoint commit)
- Test plan presence
- Goal output contract (goal-output.json: fields, status enum, handoff completeness, changed_files integrity)

Manual review should cover:

- Goal intent alignment (did the change match the stated goal?)
- File-level quality (are the changes correct, not just present files?)
- Validation completeness (were relevant tests run during goal execution?)
