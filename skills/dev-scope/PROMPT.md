You are executing /dev-scope for a software project.

Your goal is to convert user intent into a focused, bounded, execution-ready goal structure.

**Boundary**: /dev-scope declares intent. It does NOT implement, modify, commit, or expand scope silently.

---

## STEP 1: Accept User Intent

Read the user's brief description of what they want to accomplish.

If no description is provided:

Output:
"What would you like to accomplish? Provide a brief description."

Then STOP and wait for input.

---

## STEP 2: Detect Ambiguity

Before generating any scope, evaluate whether the request is clear enough to scope.

Ambiguity signals:

- Vague verbs ("improve," "optimize," "clean up")
- No file or module mentioned
- Multiple unrelated changes in one sentence
- Missing validation criteria implied by the user
- Scope that would affect more than 10 files

If ambiguous:

STOP. Ask 1–3 clarifying questions. Do NOT generate a scope from assumptions.

Examples of good clarifying questions:

- "Which specific files or modules should this change affect?"
- "What does 'improve' mean here — performance, readability, or correctness?"
- "Should this include tests, or is the scope limited to implementation?"

---

## STEP 3: Define Scope Boundaries

Explicitly define what is in-scope and out-of-scope.

### In-scope rules

- List specific files, directories, or behaviors the goal covers
- Prefer narrow scope: one module, one feature, one fix
- If the natural scope is large, decompose into smaller scopes

### Out-of-scope rules

- List specific files, directories, or behaviors the goal excludes
- Be concrete: "Does NOT modify tests/" not "Does not change other things"
- Include common creep vectors: unrelated refactors, documentation updates, dependency changes

Scope size guidance:

| Size | Guidance |
|---|---|
| Small (1–3 files) | Ideal. Prefer this. |
| Medium (4–7 files) | Acceptable if tightly related. |
| Large (8+ files) | Must decompose. Suggest splitting into multiple scopes. |

---

## STEP 4: Enumerate Requirements

List numbered requirements. Each must be:

- Concrete: describes an observable change
- Actionable: an agent can execute it
- Bounded: fits within the scope boundaries
- Ordered: dependencies first

Must NOT invent requirements the user didn't imply.

---

## STEP 5: Declare Non-goals

Explicitly state what this goal does NOT cover. This prevents scope creep during implementation.

Typical non-goals:

- Does NOT refactor unrelated files
- Does NOT change public API contracts
- Does NOT update documentation outside scope
- Does NOT add features beyond the stated objective
- Does NOT modify configuration files unless explicitly required

---

## STEP 6: Define Validation Criteria

Every scope must include validation criteria. This is mandatory.

Prefer automated validation:

- Existing tests pass
- case-05/06 validation passes
- Scripts produce expected output
- File changes match expected diff
- Lint/type checks pass

Minimize manual verification. If a criterion requires human judgment, mark it:

"[Manual] Code review for readability"

Validation-first rule: if you cannot define how to validate the goal, the scope is too vague. Refine it.

---

## STEP 7: Output Goal Structure

Output the complete structured scope:

```
## Goal

<one-sentence objective>

## Scope

### In-scope

- <specific file, directory, or behavior>
- ...

### Out-of-scope

- <specific exclusion>
- ...

## Requirements

1. <concrete requirement>
2. <concrete requirement>
...

## Non-goals

- <what this goal does NOT cover>
- ...

## Validation

1. <machine-checkable criterion>
2. <machine-checkable criterion>
...
```

After outputting the scope, proceed to Step 8 to determine execution path.

---

## STEP 8: Auto-Execution Decision

After generating the scope, evaluate whether it qualifies for auto-execution.

**Auto-execution** means the scope is implemented immediately without requiring a separate `/goal`.

### Auto-execution criteria

ALL of the following must be true:

1. **File count ≤ 3** — scope affects 3 or fewer files
2. **No public API changes** — does not modify exported interfaces, signatures, or contracts
3. **No cross-module dependencies** — changes are localized to a single area or module
4. **Single-step validation** — validation criteria can be verified in one step
5. **No ambiguous language** — scope description uses concrete, specific language
6. **Non-architectural** — does not restructure code, introduce new patterns, or change architecture
7. **Low blast radius** — failure of this change would not cascade to other systems

### Examples

**Auto-executable (direct execution)**:
- "Fix typo in README installation section"
- "Add missing import to auth.py"
- "Update command table in docs"
- "Rename variable for clarity in single file"
- "Extract constant in one module"
- "Sync documentation with current state"
- "Single-file test coverage gap"

**Requires separate `/goal`**:
- "Refactor error handling across all endpoints" (> 3 files)
- "Add OAuth flow: register, login, token refresh" (multi-step)
- "Change authentication response format" (API change)
- "Migrate from callbacks to async/await" (architectural, cross-cutting)
- "Improve performance" (ambiguous)
- "Update README and all docs" (> 3 files)
- "Architecture redesign" (architectural)

### Decision path

**If ALL criteria are met**:

1. Execute the scope immediately within defined boundaries
2. Make normal git commits during work (`feat:`, `fix:`, `docs:`, etc.)
3. Produce `goal-output.json` or `goal-output.md` artifact
4. Validate against criteria
5. Report completion

Output:
```
**Auto-execution**: Criteria met. Scope auto-executes directly.

<implementation output>

**Workflow Status**:
- Scope executed directly (auto-execution)
- Workflow completed
- No remaining protocol tasks pending
- Run /dev-save to persist state
```

**If ANY criterion is not met**:

1. Output the scope document (from Step 7)
2. STOP
3. Prompt user to review before proceeding to `/goal`

Output:
```
**Auto-execution**: Criteria NOT met. Separate /goal required.

Review the scope above. Confirm or refine before proceeding to /goal.

**Workflow Status**:
- Scope declaration complete
- Workflow completed
- No remaining protocol tasks pending
- Awaiting user confirmation before /goal
```

---

## DO

- Ask clarifying questions when intent is ambiguous
- Define explicit in-scope and out-of-scope boundaries
- Include machine-checkable validation criteria
- Prefer smaller scopes (1–3 files ideal)
- Suggest decomposition for scopes affecting 8+ files
- Include validation criteria in every scope
- Distinguish in-scope from out-of-scope explicitly

## DO NOT

- **NEVER implement code** (unless auto-execution criteria are ALL met)
- **NEVER modify repository files** (unless auto-execution criteria are ALL met)
- **NEVER commit or checkpoint** (unless auto-execution criteria are ALL met)
- **NEVER silently expand scope**
- **NEVER proceed with ambiguous requirements**
- **NEVER auto-execute when scope is ambiguous, architectural, affects > 3 files, or modifies public APIs**
- **NEVER skip /goal for multi-step, cross-cutting, or high-blast-radius work**

## PRECONDITIONS

- Git repository is initialized
- Project state is known (run `/dev-status` first if unsure)

## FAILURE CONDITIONS

STOP and report failure if ANY of the following occur:

- User intent is empty and no input provided
- Scope boundaries cannot be determined after clarifying questions
- Validation criteria are missing
- Goal structure violates the output contract format

## RULES

- **ALWAYS prefer smaller scopes**
- **ALWAYS include validation criteria**
- **ALWAYS distinguish in-scope from out-of-scope explicitly**
