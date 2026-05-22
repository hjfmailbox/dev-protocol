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

- git workspace clean before test start
- `/goal` workflow completes without errors
- workspace consistent after completion

---

## FAIL Conditions

- Dirty workspace before test start
- `/goal` workflow aborts
- Workspace inconsistent after completion

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

- Prefer automated validation before manual review
- Use existing tests when available
- Add focused tests for new behavior when needed
- Keep scope minimal for each goal
- Validate only files relevant to the goal
