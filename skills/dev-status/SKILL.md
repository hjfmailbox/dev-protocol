# /dev-status

## Purpose

Inspect current protocol state and reconstruct development context without chat history.

Goal:

Allow any fresh session to understand where the project stands and what to do next.

After status, the developer must know:

- Current phase and focus
- Active work and blockers
- Whether protocol state matches repository reality
- Recommended next action

**Boundary rule**: /dev-status is read-only. It inspects and reports; it does NOT modify, create, or fix anything.

---

## When to Use

- At the start of any new session (after `/clear`, new day, different machine)
- After switching branches
- When unsure of current project state
- Before declaring a new scope
- After resuming from an interruption

---

## When NOT to Use

- No state files exist yet (use `/dev-init` instead)
- You want to save progress (use `/dev-save` instead)
- You want to declare a goal (use `/dev-scope` instead)
- State files are known to be corrupted (use `/dev-init` to reconstruct)

---

## What It Does

1. Reads state files from `.agents/dev-protocol/`
2. Inspects git status and recent history
3. Validates state freshness (detects drift)
4. Generates a concise context summary with phase, focus, and next actions

Read-only. Never modifies files.

---

## Typical Workflow

```
# New session or after /clear
/dev-status
→ context reconstructed from state files + git reality
→ review summary
→ /dev-scope <new goal> or continue working
```

---

## Responsibilities

### 1. Read Protocol State

State file resolution (MUST follow this order):

1. **Priority**: `.agents/dev-protocol/`
   - workflow-state.yml
   - handoff.md
   - project-rules.md
   - If found here, use exclusively. Do NOT scan root for the same files.

2. **Missing**: if no state files:
   - Report: "State files not found. Run /dev-init to initialize."
   - STOP

### 2. Inspect Repository Reality

Must inspect:

- `git status` — branch, clean/dirty, modified/untracked files
- `git log --oneline -5` — recent commit context
- Current branch name (use git-derived reality, never assume `main`)

Must NOT:

- Scan repository for work-in-progress indicators
- Perform recursive grep
- Read source code beyond recently changed files

### 3. Validate State Freshness

Check for mismatch between:

- `workflow-state.yml` claims vs git reality
- `handoff.md` claims vs actual files
- Phase/focus in state vs observable repository maturity

If `checkpoint.last_commit` is empty/absent:

- Output: "No previous checkpoint baseline"
- Skip diff-based drift comparison

### Commit-type drift check

When `checkpoint.last_commit` differs from HEAD:

1. Inspect commits between baseline and HEAD
2. A commit is a **protocol commit** if it matches any of:
   - `chore(checkpoint):*` — state sync by `/dev-save`
   - `chore(protocol):*` — protocol initialization or maintenance
   - `chore(state):*` — state update
   - Semantic indicators: contains "sync state" or "protocol" with only `.agents/` or `docs/` changes
3. If ALL intermediate commits are protocol commits:
   - **Drift = none** — report informational note only
4. If ANY intermediate commit is NOT a protocol commit:
   - **Drift = high** — state has not captured actual work

### Semantic drift classification

Beyond commit-type counting, classify commits by semantic intent:

| Pattern | Semantic Type | Drift |
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

**Application**: When reporting drift, include semantic classification:
```
Drift: high — 3 source-impacting commits, 2 stabilization-pattern commits
```

### General drift classification

| Severity | Meaning |
|---|---|
| none | State matches reality (including protocol-only commits) |
| low | Minor inconsistency, context still usable |
| high | Significant mismatch or unrecorded non-protocol commits |

### 4. Checkpoint Freshness Model

Measure how far `checkpoint.last_commit` is from HEAD:

| Level | Source commits since checkpoint | Confidence |
|---|---|---|
| fresh | 0-1 | high |
| stale | 2-5 | medium |
| outdated | >5 | low |

A **source commit** is any commit that is NOT a protocol commit (`chore(checkpoint):`, `chore(protocol):`, `chore(state):`).

If checkpoint is stale or outdated, workflow-state focus is a LOW CONFIDENCE signal. Do NOT let old focus override new reality.

### 5. Phase Inference

When `workflow-state.yml` reports `phase: unknown` or phase is stale:

Infer phase using strict priority order. Stop at first valid result.

```
1. git reality (branch name, recent commit patterns, active work indicators)
2. workflow-state.yml (persisted phase, if not unknown and checkpoint current)
3. current-focus (handoff.md Current Focus section, mapped to phase language)
4. roadmap (docs/v2-redesign-roadmap.md or active roadmap phase label)
5. fallback: unknown
```

### 6. Focus Inference

Determine the current active focus using strict priority order. Stop at first valid result.

```
1. git reality (highest) -- recent commit subjects, branch names, changed files
2. recent scoped work -- recent goal commits, docs changes, roadmap workstream
3. workflow-state.yml -- ONLY if checkpoint is fresh (0-1 source commit since last checkpoint)
4. current-focus (handoff.md Current Focus section)
5. roadmap fallback
6. unknown
```

**Downgrade rule:**
If checkpoint is stale or outdated, `workflow-state.yml` focus is LOW CONFIDENCE. Do NOT let old focus override new reality. Prefer git-derived focus instead.

### 7. Active Work Reconstruction

When `/dev-save` has NOT been run after recent goal work, reconstruct active work from git history.

**Semantic theme inference:**

Beyond literal topic matching, infer themes from commit patterns:

| Pattern | Inferred Theme |
|---|---|
| Multiple `docs(*):*` + `fix(tests):*` | Stabilization / documentation hardening |
| Multiple `feat(protocol):*` + `skills/*` additions | Protocol feature expansion |
| `test(case-NN):*` sequence | Test coverage expansion |
| Mix of `feat:`, `fix:`, `test:` on same component | Active development on that component |

**Aggregation rule:**
Group recent commits by topic/theme. If 2+ commits share a topic, report that as active work.

Apply semantic inference when literal matching is insufficient. Use git history as primary source, roadmap as secondary, deferred improvements as tertiary.

### 8. Reconstruct Context

Rebuild:

- current phase (from inference, with drift note if mismatch)
- active focus (from inference, validated against recent commits)
- active work (from reconstruction, if no recent save)
- in-progress tasks
- blockers
- next actions

Source priority when sources conflict:

```
git reality > explicit docs > protocol state > assumptions
```

### 9. Output Summary

Must provide:

- current state summary
- detected drift (severity + specifics)
- confidence level
- recommended next action
- protocol task status (workflow completed or pending tasks)

---

## DO

- Report phase and focus with inference source when inferred
- Prefer git reality over persisted state when they conflict
- Report drift honestly
- Reconstruct context from all available sources
- Report checkpoint freshness level
- Recommend /dev-save when state is stale

## DO NOT

- **NEVER modify files**
- **NEVER write state**
- **NEVER auto-fix drift**
- **NEVER commit or stage**
- **NEVER return stale focus when git reality indicates newer active work**
- **NEVER leave phase as `unknown` when git reality or other sources provide clear signal**
- **Read-only only**

## Failure Rules

/dev-status fails if:

- state files are missing
- repository is corrupted
- state inconsistency is too severe to reconstruct context

Must recommend `/dev-init` if recoverable state does not exist.

---

## Hard Constraints

- **NEVER modify files**
- **NEVER write state**
- **NEVER auto-fix drift**
- **NEVER commit or stage**
- **NEVER return stale focus when git reality indicates newer active work**
- **NEVER leave phase as `unknown` when git reality or other sources provide clear signal**
- **Read-only only**

---

## Telemetry

Record the following events using `.agents/dev-protocol/runtime-telemetry/telemetry.ps1`.

Telemetry is optional: if the script is missing or config disables it, skip silently.

### command_invoked

Record at the start of execution:

```powershell
.telemetry.ps1 -EventType command_invoked -Command '/dev-status'
```

### drift_snapshot

Record after drift classification (section 3):

```powershell
.telemetry.ps1 -EventType drift_snapshot -Drift '<level>' -Phase '<phase>' -Focus '<focus>' -CheckpointOutdatedCommits <n>
```

### command_result

Record before returning output:

```powershell
.telemetry.ps1 -EventType command_result -Command '/dev-status' -Status 'success'
```

If execution fails (state files missing, repository corrupted, severe inconsistency):

```powershell
.telemetry.ps1 -EventType command_result -Command '/dev-status' -Status 'failure' -Reason '<specific failure>'
```

### session_context_snapshot

Record after generating the output summary:

```powershell
.telemetry.ps1 -EventType session_context_snapshot -Phase '<phase>' -Focus '<focus>' -Drift '<drift>' -Freshness '<freshness>' -CheckpointCommit '<hash>' -HeadCommit '<hash>' -ActiveWork '<theme>'
```
