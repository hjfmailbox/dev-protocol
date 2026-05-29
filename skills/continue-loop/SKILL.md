---
name: continue-loop
description: Use when a next-phase-plan.md exists and you want to automatically derive and execute the next planned loop without manual scope declaration
---

# continue loop

## Purpose

Reduce manual orchestration for planned execution by automatically deriving and executing the next loop from `next-phase-plan.md`.

Goal:

When a plan exists, continue execution without requiring the user to manually declare each scope.

**Boundary rule**: `continue loop` reads the plan, derives scope, and decides execution path. It does NOT invent new direction or proceed with ambiguous scope.

---

## When to Use

- A `next-phase-plan.md` exists with planned work
- The user wants to proceed to the next planned loop without manual scoping
- After `/dev-save`, when the next loop is already defined in the plan
- During iterative development with a pre-defined plan

---

## When NOT to Use

- No `next-phase-plan.md` exists (use `/dev-scope` instead)
- Workspace has uncommitted non-protocol changes
- The next planned loop is ambiguous or unclear (use `/dev-scope` instead)
- All planned loops are already completed
- You want to inspect state (use `/dev-status` instead)
- You want to save progress (use `/dev-save` instead)

---

## What It Does

1. **Verifies preconditions** — checks plan existence, workspace cleanliness, blockers, drift
2. **Reads plan** — parses `next-phase-plan.md` using tolerant loop detection
3. **Identifies next loop** — finds first incomplete loop (`pending`, `todo`, `[ ]`)
4. **Evaluates clarity** — detects ambiguity before scope derivation
5. **Derives scope** — generates structured scope from plan + handoff + recent commits
6. **Applies semantic validation** — interprets validation criteria using equivalence rules
7. **Decides execution path** — auto-executes if criteria met, else produces scope document
8. **Updates plan status** — marks loop as `completed` or `skipped`

---

## Typical Workflow

### With plan and auto-execution

```
continue loop
→ reads next-phase-plan.md
→ finds Loop 3: "Update command contracts"
→ derives scope: files=docs/command-contracts.md
→ auto-executes (1 file, non-architectural)
→ produces commit
→ updates plan status to completed
→ prompts: "/dev-save to persist state"
```

### With plan but requires /goal

```
continue loop
→ reads next-phase-plan.md
→ finds Loop 4: "Refactor auth across modules"
→ derives scope: files=src/auth/*, tests/*, docs/*
→ criteria NOT met (>3 files, cross-cutting)
→ outputs scope document
→ STOPs
→ user reviews, then runs /goal
```

### No plan

```
continue loop
→ next-phase-plan.md not found
→ STOP
→ "No plan found. Run /dev-scope to declare a goal."
```

---

## Responsibilities

### 1. Verify Preconditions

ALL must be true before proceeding:

| # | Condition | Failure Output |
|---|---|---|
| 1 | `next-phase-plan.md` exists | "No plan found. Run /dev-scope to declare a goal." |
| 2 | `next-phase-plan.md` is not empty | "Plan exists but is empty." |
| 3 | Workspace clean (or only protocol files modified) | "Workspace has uncommitted changes." |
| 4 | No unresolved blockers in `handoff.md` | "Blockers detected: [list]." |
| 5 | `checkpoint.last_commit` matches HEAD or HEAD~1 | "State drift detected. Run /dev-status." |

### 2. Parse Plan (Tolerant)

Support multiple loop formats:

- `## Loop N — [name]`
- `## Loop N: [name]`
- `## N. [name]`
- Status markers: `pending`, `in_progress`, `completed`, `skipped`, `todo`, `done`, `[ ]`, `[x]`

Scan for first incomplete loop. If none found: "All planned loops completed."

### 3. Detect Ambiguity

Ambiguity signals:

- Vague description
- No file references
- No validation criteria
- Dependencies on uncompleted previous loops

If ambiguous: STOP, output the ambiguous item, ask for clarification.

### 4. Derive Scope

Generate structured scope from plan entry:

| Plan Field | Scope Section |
|---|---|
| `Goal:` / `Objective:` | Goal statement |
| `Files:` | In-scope list |
| `Validation:` | Validation criteria |
| Missing `Files:` | Derive from goal or recent commits |
| Missing `Validation:` | `[Manual] Verify behavior` |

### 5. Apply Semantic Validation Equivalence

Before evaluating auto-execution, interpret validation criteria semantically:

- **Same domain + direction**: "tests pass" ≈ "all regression cases pass"
- **Git reality confirms intent**: commit messages and changed files satisfy plan criteria
- **Test outcomes match**: test results validate criteria even with different wording
- **Commit intent matches goal**: conventional commit subjects align with plan objectives

**Non-equivalence signals**: "started" vs "completed", "partial" vs "fully resolved"

### 6. Evaluate Auto-Execution

Apply `/dev-scope` auto-execution criteria:

1. File count ≤ 3
2. No public API changes
3. No cross-module dependencies
4. Single-step validation
5. No ambiguous language
6. Non-architectural
7. Low blast radius

### 7. Execute or Produce Scope

**If ALL criteria met**:
- Execute immediately
- Create normal git commits
- Produce goal-output artifact
- Apply semantic completion check: verify git reality, test results, or commit intent satisfy validation criteria
- Update plan status to `completed`
- Report "Workflow completed"

**If ANY criterion not met**:
- Output derived scope document
- STOP
- Wait for `/goal`

---

## Execution Sequence

```text
continue loop
  → 1. verify preconditions
  → 2. read next-phase-plan.md
  → 3. identify next uncompleted loop (tolerant parsing)
  → 4. evaluate loop clarity (detect ambiguity)
  → 5. derive scope from plan + handoff + recent commits
  → 6. apply semantic validation equivalence to criteria
  → 7. evaluate auto-execution criteria (same as /dev-scope)
  → 8. if auto-execute: execute immediately, apply semantic completion check, update plan status
     else: output scope document, STOP, wait for /goal
```

---

## DO

- Verify ALL preconditions before reading plan
- Use tolerant parsing for loop detection
- Derive scope from plan, handoff, and recent commits
- Apply auto-execution criteria strictly
- Update plan status after loop completion
- STOP on ambiguity, drift, or dirty workspace
- Allow user to skip loops

## DO NOT

- **NEVER proceed without `next-phase-plan.md`**
- **NEVER auto-execute ambiguous or architectural loops**
- **NEVER ignore dirty workspace or checkpoint drift**
- **NEVER invent requirements not implied by the plan**
- **NEVER skip precondition verification**
- **NEVER modify source code if auto-execution criteria are NOT met**

## PRECONDITIONS

- `.agents/dev-protocol/next-phase-plan.md` exists and is not empty
- Workspace is clean or only protocol files modified
- No unresolved blockers in `handoff.md`
- `checkpoint.last_commit` matches HEAD or HEAD~1

## Telemetry

Record the following events using `.agents/dev-protocol/runtime-telemetry/telemetry.ps1`.

Telemetry is optional: if the script is missing or config disables it, skip silently.

### command_invoked

Record at the start of execution:

```powershell
.telemetry.ps1 -EventType command_invoked -Command 'continue loop'
```

### workflow_transition

Record when the workflow step changes (e.g. from planning to execution):

```powershell
.telemetry.ps1 -EventType workflow_transition -From '/goal' -To 'continue loop'
```

### loop_execution

Record after a loop completes:

```powershell
.telemetry.ps1 -EventType loop_execution -LoopId 'loop-N' -AutoExecuted -Scope '<description>'
```

### command_result

Record before returning output:

```powershell
.telemetry.ps1 -EventType command_result -Command 'continue loop' -Status 'success'
```

If execution fails (no plan, dirty workspace, blockers, drift, ambiguity):

```powershell
.telemetry.ps1 -EventType command_result -Command 'continue loop' -Status 'failure' -Reason '<specific failure>'
```

### session_context_snapshot

Record after loop execution completes:

```powershell
.telemetry.ps1 -EventType session_context_snapshot -Phase '<phase>' -Focus '<focus>' -Drift '<drift>' -Freshness '<freshness>' -CheckpointCommit '<hash>' -HeadCommit '<hash>' -ActiveWork '<theme>'
```

## FAILURE CONDITIONS

STOP and report failure if ANY of the following occur:

- `next-phase-plan.md` is missing or empty
- Workspace has uncommitted non-protocol changes
- Unresolved blockers exist
- Checkpoint drift detected
- Next loop is ambiguous
- All complete: all loops are already completed
- Plan format is unrecognizable
