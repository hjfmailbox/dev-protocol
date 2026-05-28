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

Also read optional context files (if they exist):

- `.agents/dev-protocol/next-phase-plan.md` — for phase inference
- `docs/v2-redesign-roadmap.md` or active roadmap file — for phase inference

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

### Commit-type drift check (critical)

When `checkpoint.last_commit` != HEAD:

1. List commits between `checkpoint.last_commit` and HEAD:
   ```bash
   git log --oneline <checkpoint.last_commit>..HEAD
   ```

2. For each commit, determine if it is a **protocol commit** (state persistence only, no source code changes).

   A commit is a protocol commit if **any** of the following hold:

   | Pattern | Example |
   |---|---|
   | `chore(checkpoint):*` | `chore(checkpoint): sync state after auth goal` |
   | `chore(protocol):*` | `chore(protocol): initialize dev-protocol` |
   | `chore(state):*` | `chore(state): update focus and progress` |
   | Contains "sync state" AND only `.agents/` files changed | Semantic protocol persistence |
   | Contains "protocol" AND only `.agents/` or `docs/` files changed | Semantic protocol maintenance |

3. Classify drift based on intermediate commits:

   - If **ALL** intermediate commits are protocol commits → **drift = none**
     - These are expected commits created by `/dev-save` or protocol maintenance
     - Report informational note only: "N protocol commit(s) since last baseline"
   - If **ANY** intermediate commit is NOT a protocol commit → **drift = high**
     - These are unrecorded source commits; state is stale
     - Report: "Unrecorded commits detected since last checkpoint"

**Why this matters**: `/dev-save` may create commits with various `chore(checkpoint)`, `chore(protocol)`, or `chore(state)` prefixes. All of these are protocol-only commits that persist `.agents/` state. They are NOT drift. Only commits that modify source code, tests, or build artifacts represent actual work that the protocol state has not captured.

### General drift classification

| Severity | Condition |
|---|---|
| **none** | All checks pass, including commit-type check |
| **low** | Minor mismatch (e.g., focus wording outdated, one task status mismatch) |
| **high** | Major mismatch (phase wrong, workspace claim contradicts git status, unrecorded non-protocol commits) |

Drift detection is report-only. Do NOT write incidents, do NOT modify state files, do NOT auto-fix.

---

## STEP 4: Reconstruct Execution Context

### 4.1 Phase Inference

When `workflow-state.yml` reports `phase: unknown` or phase is stale:

Infer phase using strict priority order. Stop at first valid result.

```
1. next-phase-plan.md
2. roadmap (docs/v2-redesign-roadmap.md or active roadmap)
3. handoff.md
4. workflow-state.yml (persisted phase, if not unknown)
5. fallback: unknown
```

**Extraction rules per source:**

| Source | Read | Valid Phase Indicators |
|---|---|---|
| next-phase-plan.md | `.agents/dev-protocol/next-phase-plan.md` | Pending loop content: "stabilization"/"hardening"/"fix" → `stabilization`; "ergonomics"/"compression"/"friction" → `ergonomics`; "robustness"/"replay"/"audit" → `robustness` |
| roadmap | `docs/v2-redesign-roadmap.md` or active roadmap | "Current Direction" or "Current Phase" section. Explicit phase labels: `p0`-`p4`, `stabilization`, `ergonomics`, `robustness` |
| handoff.md | `.agents/dev-protocol/handoff.md` | "Current Focus" section: stabilization language → `stabilization`; ergonomics language → `ergonomics`; "Next Recommended Actions" content |
| workflow-state.yml | `.agents/dev-protocol/workflow-state.yml` | `current_state.phase` if not `unknown` and `checkpoint.last_commit` matches HEAD or HEAD~1 |

**Algorithm:**

1. Read next-phase-plan.md. If exists and contains pending loops with phase indicators → use inferred phase.
2. Read roadmap. If contains explicit phase label → use that phase.
3. Read handoff.md Current Focus. If contains phase-indicator language → map to phase.
4. Read workflow-state.yml phase. If not `unknown` and checkpoint is current → use persisted phase.
5. Output `unknown` with note: "Phase could not be inferred from available context."

**Output format for inferred phase:**

```
**Current Phase**: <phase> (inferred from <source>)
```

If phase was inferred, add note:
"Phase was inferred from <source>. Run /dev-save to persist."

### 4.2 Context Reconstruction

Rebuild from trusted sources in priority order:

1. Git reality (current branch, recent commits, dirty/clean)
2. Protocol state (workflow-state.yml, handoff.md)
3. Project rules (project-rules.md constraints)

Output:

- **Current phase**: from inference (4.1) or persisted state, with drift note if mismatch detected
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
