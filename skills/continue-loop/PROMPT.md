You are executing `continue loop` for a software project.

Your goal is to reduce manual orchestration for planned execution by automatically deriving and executing the next loop from `next-phase-plan.md`.

**Boundary**: `continue loop` reads the plan, derives scope, and decides execution path. It does NOT invent new direction or proceed with ambiguous scope.

---

## STEP 1: Verify Preconditions

Before reading the plan, verify ALL of the following:

1. **`next-phase-plan.md` exists** in `.agents/dev-protocol/`
2. **`next-phase-plan.md` is not empty**
3. **Workspace is clean** OR only protocol state files (`.agents/dev-protocol/*`) are modified
4. **No unresolved blockers** in `handoff.md`
5. **`checkpoint.last_commit` matches HEAD or HEAD~1** (minimal drift)

If ANY precondition fails:

STOP. Output the specific failure and recommended recovery action.

| Failure | Output |
|---|---|
| `next-phase-plan.md` missing | "No plan found. Run /dev-scope to declare a goal." |
| `next-phase-plan.md` empty | "Plan exists but is empty. Update next-phase-plan.md or run /dev-scope." |
| Workspace dirty (non-protocol files) | "Workspace has uncommitted changes. Commit or stash before continuing." |
| Unresolved blockers | "Blockers detected: [list]. Resolve before continuing." |
| Checkpoint drift | "State drift detected. Run /dev-status to review." |

---

## STEP 2: Read and Parse Plan

Read `.agents/dev-protocol/next-phase-plan.md`.

### Loop detection (tolerant parsing)

Identify loops using flexible patterns. Support at least:

- `## Loop N — [name]`
- `## Loop N: [name]`
- `## N. [name]`
- Status markers: `pending`, `in_progress`, `completed`, `skipped`, `todo`, `done`, `[ ]`, `[x]`

Scan for the **first loop with status indicating incomplete** (`pending`, `in_progress`, `todo`, `[ ]`, or no explicit status`).

If no incomplete loop is found:

STOP. Output: "All planned loops completed."

---

## STEP 3: Evaluate Loop Clarity

Before deriving scope, evaluate whether the identified loop is clear enough to proceed.

**Ambiguity signals**:

- Vague description ("improve", "optimize", "clean up")
- No file or module mentioned
- No validation criteria
- Dependencies on uncompleted previous loops
- Status is `in_progress` but no handoff context exists

If ambiguous:

STOP. Output:
```
Next loop is ambiguous: [loop description]

Clarify next-phase-plan.md or run /dev-scope manually.
```

Do NOT proceed with assumptions.

---

## STEP 4: Derive Scope

From the identified loop, generate a structured scope with these sections:

```
## Goal

<one-sentence objective from plan>

## Scope

### In-scope
- <files from plan>
- <specific behaviors>

### Out-of-scope
- <implied exclusions based on plan context>

## Requirements
1. <derived from plan goal>

## Non-goals
- <what this loop does NOT cover>

## Validation
1. <validation criteria from plan>
```

Rules for deriving scope:

- Use `Files:` list from plan as in-scope
- Use `Goal:` or `Objective:` as the goal statement
- Use `Validation:` as validation criteria
- Infer out-of-scope and non-goals from context (do NOT invent requirements)
- If plan lacks `Files:`, derive from goal description or recent commit patterns
- If plan lacks `Validation:`, mark as `[Manual] Verify behavior matches expectation`

---

## STEP 5: Evaluate Auto-Execution Eligibility

Apply the same auto-execution criteria as `/dev-scope`:

ALL must be true:

1. **File count ≤ 3** — derived scope affects 3 or fewer files
2. **No public API changes** — does not modify exported interfaces
3. **No cross-module dependencies** — changes localized to single area
4. **Single-step validation** — validation criteria are one-step
5. **No ambiguous language** — plan entry is concrete
6. **Non-architectural** — does not restructure or introduce new patterns
7. **Low blast radius** — failure would not cascade

---

## STEP 6: Execute or Produce Scope

### Path A: Auto-execution (ALL criteria met)

1. Execute the derived scope immediately
2. Make normal git commits during work (`feat:`, `fix:`, `docs:`, etc.)
3. Produce `goal-output.json` or `goal-output.md` artifact
4. Update `next-phase-plan.md` status for this loop to `completed`
5. Report completion

Output:
```
**Continue Loop**: Auto-executing Loop N — [name]

**Derived Scope**:
<scope summary>

**Execution Result**:
<implementation summary>

**Workflow Status**:
- Loop N completed
- Workflow completed
- No remaining protocol tasks pending
- Run /dev-save to persist state
```

### Path B: Scope document required (ANY criterion not met)

1. Output the derived scope document
2. STOP
3. Prompt user to confirm or run `/goal`

Output:
```
**Continue Loop**: Loop N — [name]

**Derived Scope**:
<full scope document>

**Auto-execution**: Criteria NOT met. Separate /goal required.

**Workflow Status**:
- Scope derived from plan
- Workflow completed
- No remaining protocol tasks pending
- Review scope above, then run /goal to implement
```

---

## STEP 7: Handle Edge Cases

### Loop already in_progress

If the next incomplete loop has status `in_progress`:

- Check `handoff.md` for continuation context
- If context exists: resume with derived scope
- If no context: treat as ambiguous; STOP and ask user

### Plan format unrecognized

If `next-phase-plan.md` does not match any recognized loop format:

- Attempt tolerant extraction (headers, bullet lists, numbered items)
- If still unparseable: STOP. "Plan format not recognized. Expected: ## Loop N — [name] with Status: pending/todo"

### Skip current loop

If user rejects the derived scope and wants to skip:

- Update loop status to `skipped` in `next-phase-plan.md`
- Re-run `continue loop` to find next loop

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

## FAILURE CONDITIONS

STOP and report failure if ANY of the following occur:

- `next-phase-plan.md` is missing or empty
- Workspace has uncommitted non-protocol changes
- Unresolved blockers exist
- Checkpoint drift detected
- Next loop is ambiguous
- All loops are already completed
- Plan format is unrecognizable

## RULES

- **ALWAYS verify preconditions first**
- **ALWAYS use tolerant loop parsing**
- **ALWAYS evaluate ambiguity before deriving scope**
- **ALWAYS apply auto-execution criteria before implementing**
- **ALWAYS update plan status after completion**
- **NEVER proceed with ambiguous scope**
