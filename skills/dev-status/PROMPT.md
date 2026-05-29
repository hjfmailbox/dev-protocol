You are executing /dev-status for a software project.

Your goal is to inspect the current protocol state and reconstruct development context.

**Boundary**: /dev-status is strictly read-only. You inspect and report. You do NOT modify, create, or fix anything.

---

## When to Use

- At the start of any new session (after `/clear`, new day, different machine)
- After switching branches
- When unsure of current project state
- Before declaring a new scope
- After resuming from an interruption

## When NOT to Use

- No state files exist yet (use `/dev-init` instead)
- You want to save progress (use `/dev-save` instead)
- You want to declare a goal (use `/dev-scope` instead)
- You want to modify, create, or fix anything (read-only only)

## Typical Workflow

```
/dev-status
-> loads state files
-> inspects repository reality (git status, recent commits)
-> validates state freshness (detects drift)
-> reconstructs phase, focus, active work
-> outputs concise context summary with recommended next action
```

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

### Semantic drift classification

Beyond commit-type counting, classify commits by semantic intent:

| Commit Pattern | Semantic Type | Drift Impact |
|---|---|---|
| `chore(checkpoint):*` | Protocol-only | none |
| `chore(protocol):*` | Protocol maintenance | none |
| `chore(state):*` | State update | none |
| `docs(*):*` without source changes | Documentation-only | low |
| `test(*):*` without source changes | Test-only | low |
| `feat(*):*` or `fix(*):*` | Source-impacting | high |
| `refactor(*):*` with cross-module changes | Architectural | high |
| Multiple `docs(protocol):*` or `fix(tests):*` in sequence | Stabilization pattern | low |
| Commits matching roadmap active items | Roadmap-aligned | medium |

**Semantic interpretation rules**:

1. **Documentation-only changes** (`docs(*):*` with only `.md`/`.txt` changes):
   - Drift = low
   - State focus may be slightly stale but context is still valid

2. **Stabilization-pattern commits** (sequence of `docs(protocol):`, `fix(tests):`, `test(case-NN):`):
   - Drift = low
   - These are expected during stabilization phase
   - Do NOT report as unrecorded work

3. **Roadmap-aligned commits** (commit subjects matching active roadmap items):
   - Drift = medium
   - State may not have captured the specific focus, but direction is consistent
   - Recommend `/dev-save` to update focus

4. **Source-impacting commits** (`feat:`, `fix:`, `refactor:` with source file changes):
   - Drift = high
   - State has definitely not captured this work

5. **Test-only changes** (`test(*):*` without source changes):
   - Drift = low
   - Often accompanies stabilization; not independent work

**Application**: When reporting drift, include semantic classification:
```
Drift: high — 3 source-impacting commits, 2 stabilization-pattern commits
```

### General drift classification

| Severity | Condition |
|---|---|
| **none** | All checks pass, including commit-type check |
| **low** | Minor mismatch (e.g., focus wording outdated, one task status mismatch) |
| **high** | Major mismatch (phase wrong, workspace claim contradicts git status, unrecorded non-protocol commits) |

### Checkpoint Freshness Model

Measure how far `checkpoint.last_commit` is from HEAD:

| Level | Source commits since checkpoint | Confidence |
|---|---|---|
| fresh | 0-1 | high |
| stale | 2-5 | medium |
| outdated | >5 | low |

A **source commit** is any commit that is NOT a protocol commit (see commit-type drift check above).

Algorithm:
1. List commits between `checkpoint.last_commit` and HEAD: `git log --oneline <checkpoint.last_commit>..HEAD`
2. Exclude protocol commits using the classification rules above
3. Count remaining source commits
4. Map to freshness level
5. Report freshness in summary: `checkpoint: <fresh/stale/outdated>`

If `checkpoint.last_commit` is empty, absent, or null:
- freshness is `none` (no baseline)
- Skip diff-based drift comparison
- Do NOT report "since last checkpoint" phrasing

Drift detection is report-only. Do NOT write incidents, do NOT modify state files, do NOT auto-fix.

---

## STEP 4: Reconstruct Execution Context

### 4.1 Phase Inference

When `workflow-state.yml` reports `phase: unknown` or phase is stale:

Infer phase using strict priority order. Stop at first valid result.

```
1. git reality (branch name, recent commit patterns, active work indicators)
2. workflow-state.yml (persisted phase, if not unknown and checkpoint current)
3. current-focus (handoff.md Current Focus section, mapped to phase language)
4. roadmap (docs/v2-redesign-roadmap.md or active roadmap phase label)
5. fallback: unknown
```

**Extraction rules per source:**

| Source | Read | Valid Phase Indicators |
|---|---|---|
| git reality | `git status`, `git log --oneline -5`, `git branch` | Active feature branch with recent `feat:` commits → `development`; stabilization branch with `chore(checkpoint):` dominance → `stabilization`; active refactoring → `refactoring` |
| workflow-state.yml | `.agents/dev-protocol/workflow-state.yml` | `current_state.phase` if not `unknown` and `checkpoint.last_commit` matches HEAD or HEAD~1 |
| current-focus | `.agents/dev-protocol/handoff.md` | "Current Focus" section: stabilization language → `stabilization`; ergonomics language → `ergonomics`; "Next Recommended Actions" content |
| roadmap | `docs/v2-redesign-roadmap.md` or active roadmap | "Current Direction" or "Current Phase" section. Explicit phase labels: `p0`-`p4`, `stabilization`, `ergonomics`, `robustness` |

**Algorithm:**

1. Inspect git reality. If branch name or recent commits indicate active work phase → use inferred phase from git.
2. Read workflow-state.yml phase. If not `unknown` and checkpoint is current (matches HEAD or HEAD~1) → use persisted phase.
3. Read handoff.md Current Focus. If contains phase-indicator language → map to phase.
4. Read roadmap. If contains explicit phase label → use that phase.
5. Output `unknown` with note: "Phase could not be inferred from available context."

**Output format for inferred phase:**

```
**Current Phase**: <phase> (inferred from <source>)
```

If phase was inferred, add note:
"Phase was inferred from <source>. Run /dev-save to persist."

### 4.2 Focus Inference

Determine the current active focus using strict priority order. Stop at first valid result.

```
1. git reality (highest) -- recent commit subjects, branch names, changed files
2. recent scoped work -- recent goal commits, docs/command-contracts changes, roadmap workstream
3. workflow-state.yml -- ONLY if checkpoint is fresh (0-1 source commit since last checkpoint)
4. current-focus (handoff.md Current Focus section)
5. roadmap fallback
6. unknown
```

**Extraction rules per source:**

| Source | Read | Valid Focus Indicators |
|---|---|---|
| git reality | `git log --oneline -5`, `git diff --name-only HEAD~1` | Commit subjects like `docs(protocol): ...`, `fix(tests): ...`, `test(case-13): ...` indicate active workstream; changed files in `skills/`, `docs/`, `tests/` suggest focus area |
| recent scoped work | Same as git reality | Multiple related commits on same topic aggregate into focus theme |
| workflow-state.yml | `.agents/dev-protocol/workflow-state.yml` | `current_state.focus` ONLY if checkpoint is fresh (matches HEAD or HEAD~1, or 0-1 source commit since checkpoint) |
| current-focus | `.agents/dev-protocol/handoff.md` | "Current Focus" section text |
| roadmap | `docs/v2-redesign-roadmap.md` | "Current Direction" or active section headers |

**Downgrade rule:**
If checkpoint is stale or outdated (see Checkpoint Freshness Model in Step 3), `workflow-state.yml` focus is a LOW CONFIDENCE signal. Do NOT let old focus override new reality. Prefer git-derived focus instead.

**Algorithm:**

1. Inspect git reality. If recent commits indicate clear active work -- use inferred focus from git.
2. Check checkpoint freshness. If fresh and workflow-state focus is present -- use persisted focus.
3. If checkpoint is stale or outdated -- downgrade workflow-state focus to suggestion only; prefer git reality.
4. Read handoff.md Current Focus. If present and checkpoint is not outdated -- use as secondary signal.
5. Read roadmap for fallback focus.
6. Output `unknown` with note: "Focus could not be inferred from available context."

**Output format for inferred focus:**

```
**Focus**: <focus> (inferred from <source>)
```

If focus was inferred from git reality due to stale checkpoint, add note:
"Focus inferred from recent commits. Previous workflow-state focus was stale (<N> commits old). Run /dev-save to persist."

### 4.3 Active Work Reconstruction

When `/dev-save` has NOT been run after recent goal work, reconstruct active work from git history.

**Signals to aggregate:**
- Recent conventional commit prefixes: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`
- Recent scope areas: `skills/`, `docs/`, `tests/`, `references/`
- Commit co-occurrence: multiple commits on same topic indicate ongoing workstream
- Goal-output summaries (if present): previous goal context
- Roadmap sections: active workstreams
- Deferred items: unresolved friction themes

**Semantic theme inference:**

Beyond literal topic matching, infer themes from commit patterns:

| Pattern | Inferred Theme |
|---|---|
| Multiple `docs(*):*` + `fix(tests):*` | Stabilization / documentation hardening |
| Multiple `feat(protocol):*` + `skills/*` additions | Protocol feature expansion |
| `test(case-NN):*` sequence | Test coverage expansion |
| `docs(command-contracts):*` + `README.md` changes | Workflow documentation |
| `chore(checkpoint):*` dominance | Stabilization / state maintenance |
| Mix of `feat:`, `fix:`, `test:` on same component | Active development on that component |

**Aggregation rule:**
Group recent commits by topic/theme. If 2+ commits share a topic, report that as active work.

Apply semantic inference when literal matching is insufficient:
- `docs(dev-save): add help sections` + `docs(continue-loop): add help sections` → "Command help quality audit across multiple skills"
- `feat(protocol): add continuous loop` + `feat(protocol): add goal-to-plan` → "Protocol workflow compression features"
- `fix(tests): case-36 regex` + `fix(tests): case-15 keywords` → "Test validation hardening"

**Sources for semantic enrichment:**
1. Git history (primary)
2. Roadmap active items (secondary)
3. Deferred improvements (tertiary)
4. Goal-output summaries (if present)

**Output:**
Include under **Active Work** section in summary.

### 4.4 Context Reconstruction

Rebuild from trusted sources in priority order:

1. Git reality (current branch, recent commits, dirty/clean)
2. Protocol state (workflow-state.yml, handoff.md)
3. Project rules (project-rules.md constraints)

Output:

- **Current phase**: from inference (4.1) or persisted state, with drift note if mismatch detected
- **Active focus**: from inference (4.2), validated against recent commits
- **In-progress tasks**: from handoff, validated against git status
- **Blockers**: from handoff, noted if stale
- **Next actions**: recommend based on reconstructed context

If state files are stale but not corrupted:

- Report the drift
- Still reconstruct context from available information
- Recommend running `/dev-save` after corrections

## DO

- Report phase and focus with inference source when inferred
- Prefer git reality over persisted state when they conflict
- Report drift honestly
- Reconstruct context from all available sources
- Report checkpoint freshness level

## DO NOT

- **NEVER modify files**
- **NEVER write state**
- **NEVER auto-fix drift**
- **NEVER commit or stage**
- **NEVER create incident logs or any new files**
- **NEVER scan the repository for work-in-progress indicators**
- **NEVER perform recursive grep**
- **NEVER assume branch names (no hardcoded `main`)**
- **NEVER leave phase as `unknown` when git reality or other sources provide clear signal**
- **NEVER return stale focus when git reality indicates newer active work**

## PRECONDITIONS

- Git repository is initialized
- Agent has read access to `.agents/dev-protocol/`

## FAILURE CONDITIONS

STOP and report failure if ANY of the following occur:

- State files are missing and cannot be recovered
- Repository is corrupted (`git status` fails)
- State inconsistency is too severe to reconstruct context

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
**Checkpoint**: <fresh/stale/outdated/none> — <source commits since baseline>
**Confidence**: <high/medium/low>

**Active Work**:
- <reconstructed active work from recent commits or "none">

**Blockers**:
- <blockers or "none">

**Recommended Next Action**:
- <concrete next step>

**Protocol Task Status**:
- <workflow completed / X pending tasks>
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
