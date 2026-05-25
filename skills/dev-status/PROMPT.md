You are executing /dev-status for a software project.

Your goal is to inspect the current protocol state and reconstruct development context.

**Boundary**: /dev-status is strictly read-only. You inspect and report. You do NOT modify, create, or fix anything.

---

## STEP 0: Reality Priority

When sources conflict, this hierarchy wins:

```
Git reality (git status, git log) > Explicit docs (README, CLAUDE.md) > Protocol state (workflow-state.yml) > Assumptions
```

Never trust assumptions over observable reality.

---

## STEP 1: Load State

Read state files from `.agents/dev-protocol/`:

- `workflow-state.yml`
- `handoff.md`
- `project-rules.md`

Rules:

- If `.agents/dev-protocol/` has state files, use them exclusively
- Do NOT scan root directory for the same files
- Do NOT merge results from different locations
- If no state files found, STOP and report: "State files not found. Run /dev-init to initialize."

---

## STEP 2: Inspect Repository Reality

Run lightweight inspection only:

- `git status` — branch, clean/dirty, modified/untracked files
- `git log --oneline -5` — recent commits
- `git branch` — current branch

Use git-derived branch names. Never assume `main` or any specific branch name. Refer to the current branch as "current branch" or "primary/default branch" only when describing general behavior.

Allowed active work detection:

- `git status --short`
- Recently changed files (from git status or recent commits)
- Current branch name

Forbidden:

- repo-wide work-in-progress indicator scans
- recursive grep across the repository
- deep source code analysis
- reading files beyond state files and git output

---

## STEP 3: Validate State Freshness

Compare protocol state against repository reality:

| Check | What to compare |
|---|---|
| Phase sanity | Does `workflow-state.yml` phase match observable repo maturity? |
| Focus relevance | Does `handoff.md` focus align with current branch and recent commits? |
| Task completion | Are tasks marked "completed" reflected in git history? |
| Dirty state | Does `workflow-state.yml` workspace claim match `git status`? |
| Baseline presence | Is `checkpoint.last_commit` present and valid? |

If `checkpoint.last_commit` is empty, absent, or null:

- Output: "No previous checkpoint baseline"
- Do NOT reference "since last checkpoint" phrasing
- Skip diff-based drift comparison

Classify drift:

| Severity | Condition |
|---|---|
| **none** | All checks pass |
| **low** | Minor mismatch (e.g., focus wording outdated, one task status mismatch) |
| **high** | Major mismatch (e.g., phase wrong, workspace claim contradicts git status, missing commits) |

Drift detection is report-only. Do NOT write incidents, do NOT modify state files, do NOT auto-fix.

---

## STEP 4: Reconstruct Execution Context

Rebuild from trusted sources in priority order:

1. Git reality (current branch, recent commits, dirty/clean)
2. Protocol state (workflow-state.yml, handoff.md)
3. Project rules (project-rules.md constraints)

Output:

- **Current phase**: from state, with drift note if mismatch detected
- **Active focus**: from state, validated against recent commits
- **In-progress tasks**: from handoff, validated against git status
- **Blockers**: from handoff, noted if stale
- **Next actions**: recommend based on reconstructed context

If state files are stale but not corrupted:

- Report the drift
- Still reconstruct context from available information
- Recommend running `/dev-save` after corrections

---

## STEP 5: Output Summary

Provide:

```
## /dev-status Summary

**Current Phase**: <phase> <drift note if any>
**Focus**: <focus>
**Branch**: <current branch>
**Workspace**: <clean/dirty + details>
**Drift**: <none/low/high> — <specifics>
**Confidence**: <high/medium/low>

**Active Work**:
- <in-progress tasks or "none">

**Blockers**:
- <blockers or "none">

**Recommended Next Action**:
- <concrete next step>
```

For drift severity **high**:

- Warn: "Significant drift detected. Consider running /dev-init to refresh state."
- Still provide reconstructed context

For missing state files:

- STOP after Step 1
- Output: "State files not found. Run /dev-init to initialize."

---

## RULES

- **NEVER modify files**
- **NEVER write state**
- **NEVER auto-fix drift**
- **NEVER commit or stage**
- **NEVER create incident logs or any new files**
- **NEVER scan the repository for work-in-progress indicators**
- **NEVER perform recursive grep**
- **NEVER assume branch names (no hardcoded `main`)**
- **ALWAYS prefer git reality over persisted state**
- **ALWAYS report drift honestly**
