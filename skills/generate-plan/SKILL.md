---
name: generate-plan
description: Use when you need to convert a high-level goal into a structured execution plan with numbered loops before using continue loop
---

# generate plan

## Purpose

Convert a high-level goal into a structured `next-phase-plan.md` draft, reducing manual planning friction before `continue loop` execution.

Goal:

Eliminate the manual step of writing `next-phase-plan.md` by deriving loops from project context, roadmap, deferred items, and recent history.

**Boundary rule**: `generate plan` reads context, infers scope, and produces a plan draft. It does NOT execute loops or modify source code.

---

## When to Use

- After `/dev-scope` or `/goal` has produced a high-level objective
- Before `continue loop`, when no `next-phase-plan.md` exists yet
- When a goal is complex enough to benefit from decomposition into loops
- After reviewing roadmap or deferred items that suggest multi-step work

## When NOT to Use

- A `next-phase-plan.md` already exists (use `continue loop` instead)
- The goal is simple enough for single-loop auto-execution (use `/dev-scope` directly)
- You want to inspect state (use `/dev-status` instead)
- You want to save progress (use `/dev-save` instead)

---

## What It Does

1. **Reads context** — state files, roadmap, deferred items, recent commits, goal-output
2. **Infers focus** — current phase, stabilization priorities, unresolved friction
3. **Decomposes goal** — breaks objective into small, independently executable loops
4. **Generates plan** — writes `.agents/dev-protocol/next-phase-plan.md` with numbered loops
5. **Validates plan** — ensures loops satisfy continue-loop constraints

---

## Typical Workflow

```
generate plan
→ reads project context
→ infers phase and focus
→ decomposes goal into loops
→ writes `.agents/dev-protocol/next-phase-plan.md`
→ validates loops are continue-loop friendly
→ prompts: "continue loop to execute"
```

---

## Responsibilities

### 1. Read Context

Must read (in order of priority):

1. `.agents/dev-protocol/workflow-state.yml` — current phase, focus, progress
2. `.agents/dev-protocol/handoff.md` — current focus, blockers, next actions
3. `docs/v2-redesign-roadmap.md` — active roadmap items
4. `.agents/dev-protocol/docs/deferred-improvements.md` — unresolved friction
5. Recent git history (`git log --oneline -10`) — active work themes
6. `.agents/dev-protocol/goal-output.md` (if present) — previous goal context

If `current-focus.md` exists, read it as supplementary context (v1 compatibility only).

### 2. Infer Focus

Derive:

- **Current phase** from workflow-state.yml or roadmap
- **Active stabilization focus** from handoff.md or recent commits
- **Unresolved friction** from deferred-improvements.md
- **Relevant roadmap items** from v2-redesign-roadmap.md

### 3. Decompose Goal

Break the high-level goal into numbered loops:

- Each loop must be independently executable
- Each loop must have explicit validation criteria
- Each loop must have explicit completion signals
- Prefer small loops (≤3 files) when possible
- Avoid repo-wide refactors unless explicitly requested
- Use auto-execution-friendly wording (concrete, bounded, non-ambiguous)

### 4. Generate Plan

Write `.agents/dev-protocol/next-phase-plan.md` using this structure:

```markdown
# Next Phase Plan

## Loop 1 — [Name]

**Status:** pending

**Goal:** [one-sentence objective]

**Files:** [specific files]

**Validation:**
- [criterion 1]
- [criterion 2]

## Loop 2 — [Name]
...
```

### 5. Validate Plan

Ensure generated loops satisfy continue-loop constraints:

- File count ≤ 3 per loop (preferably)
- Non-architectural wording
- Concrete validation criteria
- No cross-module dependencies in single loop
- Clear completion signals

If any loop violates constraints, add a note: "Note: This loop may require /goal instead of auto-execution."

---

## Preconditions

- Git repository is initialized
- `.agents/dev-protocol/` exists (run `/dev-init` first if not)
- Goal is provided or inferable from context

## DO

- Prefer small, focused loops
- Use concrete language (avoid "improve", "optimize", "clean up")
- Include explicit validation criteria for each loop
- Reference specific files when possible
- Validate plan against continue-loop constraints
- Allow user to review and edit plan before execution

## DO NOT

- **NEVER execute loops** — only generate the plan
- **NEVER modify source code**
- **NEVER invent requirements not implied by the goal or context**
- **NEVER create loops larger than 8 files without decomposition note**
- **NEVER skip context reading**
- **NEVER overwrite an existing `next-phase-plan.md` without confirmation**

## Failure Conditions

STOP and report failure if:

- No goal can be inferred from context
- Context files are missing and goal is not provided
- Inferred goal is ambiguous
- Generated plan has zero loops
- All generated loops violate continue-loop constraints

---

## Telemetry

Record the following events using `.agents/dev-protocol/runtime-telemetry/telemetry.ps1`.

Telemetry is optional: if the script is missing or config disables it, skip silently.

### command_invoked

Record at the start of execution:

```powershell
.telemetry.ps1 -EventType command_invoked -Command 'generate plan'
```

### command_result

Record before returning output:

```powershell
.telemetry.ps1 -EventType command_result -Command 'generate plan' -Status 'success'
```

If execution fails (missing context, ambiguous goal, zero loops):

```powershell
.telemetry.ps1 -EventType command_result -Command 'generate plan' -Status 'failure' -Reason '<specific failure>'
```

### session_context_snapshot

Record after plan is generated:

```powershell
.telemetry.ps1 -EventType session_context_snapshot -Phase '<phase>' -Focus '<focus>' -Freshness '<freshness>' -CheckpointCommit '<hash>' -HeadCommit '<hash>' -ActiveWork '<theme>'
```

## Execution Sequence

```text
generate plan
  → 1. read context (workflow-state, handoff, roadmap, deferred, git log, goal-output)
  → 2. infer current phase, focus, unresolved friction
  → 3. decompose goal into numbered loops
  → 4. write `.agents/dev-protocol/next-phase-plan.md`
  → 5. validate loops against continue-loop constraints
  → 6. output plan summary and next steps
```
