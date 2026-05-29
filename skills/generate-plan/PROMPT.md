You are executing `generate plan` for a software project.

Your goal is to convert a high-level objective into a structured `next-phase-plan.md` draft, reducing manual planning friction before `continue loop` execution.

**Boundary**: `generate plan` reads context, infers scope, and produces a plan draft. It does NOT execute loops or modify source code.

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

## Typical Workflow

```
generate plan
→ reads project context
→ infers phase and focus
→ decomposes goal into loops
→ writes next-phase-plan.md
→ validates loops are continue-loop friendly
→ prompts: "continue loop to execute"
```

---

## STEP 1: Read Context

Read the following context files in order of priority:

1. `.agents/dev-protocol/workflow-state.yml`
2. `.agents/dev-protocol/handoff.md`
3. `docs/v2-redesign-roadmap.md`
4. `.agents/dev-protocol/docs/deferred-improvements.md`
5. Recent git history (`git log --oneline -10`)
6. `.agents/dev-protocol/goal-output.md` (if present)

If `current-focus.md` exists, read it as supplementary context (v1 compatibility only).

Rules:

- If `.agents/dev-protocol/` does not exist: STOP. Output: "State files not found. Run /dev-init to initialize."
- If goal is not explicitly provided, infer it from context (focus, roadmap active items, deferred improvements)
- If no goal can be inferred: STOP. Output: "No goal provided and none inferable from context. Run /dev-scope to declare a goal."

---

## STEP 2: Infer Focus

From the context, derive:

| Field | Source |
|---|---|
| Current phase | `workflow-state.yml` → `current_state.phase` or roadmap "Current Status" |
| Active focus | `handoff.md` Current Focus or recent git commit themes |
| Unresolved friction | `deferred-improvements.md` open items |
| Relevant roadmap items | `v2-redesign-roadmap.md` active/near-term items |
| Recent work themes | `git log --oneline -10` conventional commit prefixes |

If multiple sources conflict, prefer handoff.md and git reality over roadmap guesses.

---

## STEP 3: Decompose Goal

Break the inferred or provided goal into **numbered loops**.

### Loop design rules

1. **Independently executable**: each loop can run without waiting for another
2. **Explicit validation**: each loop has checklist criteria
3. **Explicit completion**: each loop defines what "done" means
4. **Bounded scope**: prefer ≤3 files per loop
5. **Auto-execution friendly**: concrete wording, no ambiguity, non-architectural
6. **No repo-wide refactors**: unless explicitly requested in goal

### Loop structure

Each loop must follow this format:

```markdown
## Loop N — [Short Name]

**Status:** pending

**Goal:** [one-sentence objective]

**Files:** [specific files or "derive from goal"]

**Validation:**
- [machine-checkable criterion 1]
- [machine-checkable criterion 2]
```

### Decomposition guidance

| Goal Complexity | Loop Count | Guidance |
|---|---|---|
| Simple (1-3 files) | 1 loop | Direct execution, no plan needed |
| Medium (4-8 files) | 2-3 loops | Decompose by file group or task type |
| Complex (8+ files or cross-cutting) | 3-5 loops | Decompose aggressively; mark complex loops with note |

If a loop would affect >3 files, either:
- Split into smaller loops, OR
- Add note: "Note: This loop affects >3 files and may require `/goal` instead of auto-execution."

---

## STEP 4: Write Plan

Write the generated plan to `docs/next-phase-plan.md`.

### File structure

```markdown
# Next Phase Plan

## Loop 1 — [Name]

**Status:** pending

**Goal:** ...

**Files:** ...

**Validation:** ...

## Loop 2 — [Name]
...
```

### Rules

- MUST use `## Loop N — [Name]` format (compatible with continue-loop tolerant parsing)
- MUST set `**Status:** pending` for all new loops
- MUST include `**Goal:**`, `**Files:**`, and `**Validation:**` for each loop
- MUST NOT include implementation details — only scope and validation
- MUST NOT invent files that do not exist

---

## STEP 5: Validate Plan

Check each loop against continue-loop auto-execution constraints:

| Constraint | Check |
|---|---|
| File count ≤ 3 | Count files in `**Files:**` |
| No ambiguous language | Avoid "improve", "optimize", "clean up", "refactor broadly" |
| Non-architectural | Does not introduce new patterns or restructure modules |
| Concrete validation | Validation criteria are machine-checkable |

If ANY loop fails constraints:
- Add note under that loop: "Note: May require `/goal`. Auto-execution criteria not met."
- Do NOT block plan generation — the note is sufficient warning

---

## STEP 6: Output Summary

After writing the plan, output:

```
## generate plan Complete

**Goal Inferred**: [goal summary]

**Loops Generated**: [N]

**Plan File**: docs/next-phase-plan.md

**Loop Summary**:
- Loop 1: [name] — [files] — [auto-execution status]
- Loop 2: [name] — [files] — [auto-execution status]
...

**Context Used**:
- Phase: [phase]
- Focus: [focus]
- Roadmap items: [list]
- Deferred items: [list]

**Next Steps**:
1. Review `docs/next-phase-plan.md`
2. Edit if needed
3. Run `continue loop` to execute
```

---

## DO

- Prefer small, focused loops
- Use concrete language
- Include explicit validation criteria
- Reference specific files when possible
- Validate against continue-loop constraints
- Allow user to review plan before execution

## DO NOT

- **NEVER execute loops** — only generate the plan
- **NEVER modify source code**
- **NEVER invent requirements not implied by context**
- **NEVER create loops larger than 8 files without decomposition note**
- **NEVER skip context reading**
- **NEVER overwrite existing `next-phase-plan.md` without confirmation**

## PRECONDITIONS

- Git repository is initialized
- `.agents/dev-protocol/` exists
- Goal is provided or inferable from context

## FAILURE CONDITIONS

STOP and report failure if ANY of the following occur:

- `.agents/dev-protocol/` does not exist
- No goal provided and none inferable from context
- Inferred goal is ambiguous
- Generated plan has zero loops
- All generated loops violate continue-loop constraints

## RULES

- **ALWAYS read context before generating loops**
- **ALWAYS use concrete, non-ambiguous language**
- **ALWAYS validate against continue-loop constraints**
- **ALWAYS output plan summary with next steps**
- **NEVER execute or implement**
