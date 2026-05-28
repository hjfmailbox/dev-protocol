# /dev-scope

## Purpose

Declare a focused, bounded goal with validation criteria.

Goal:

Convert user intent into an explicit scoped objective that an agent can execute without ambiguity.

After scoping, the goal must have:

- Clear boundaries (what is in-scope and what is out-of-scope)
- Actionable requirements
- Machine-checkable validation criteria
- Explicit non-goals to prevent scope creep

**Boundary rule**: /dev-scope declares intent. It does NOT implement, modify, commit, or expand scope silently.

---

## When to Use

- Before starting any implementation work
- When a task feels too large or ambiguous
- After /dev-status reveals the project is ready for new work
- When user provides a vague request that needs structure

---

## When NOT to Use

- The goal is already fully specified by the user and auto-execution criteria are met (it will execute directly)
- Exploration or research without concrete deliverables
- You want to save progress (use /dev-save instead)
- You want to inspect state (use /dev-status instead)

---

## What It Does

Generates a structured goal definition with the following sections:

1. **Goal** — one-sentence objective
2. **Scope** — allowed and forbidden files/areas
3. **Requirements** — numbered, concrete, actionable tasks
4. **Non-goals** — explicit boundaries to prevent scope creep
5. **Validation** — machine-checkable success criteria

The output is execution-ready. The agent consuming this scope must implement exactly what is defined, no more and no less.

---

## Typical Workflow

### Standard path (complex scope)

```
/dev-scope
→ goal structure generated
→ review and confirm scope with user if needed
→ /goal <structured scope>
→ implement within scoped boundaries
→ validate against criteria
→ /dev-save
```

### Auto-execution path (simple scope)

```
/dev-scope "fix typo in README"
→ criteria evaluated: ≤3 files, non-architectural, no API changes
→ auto-executes directly
→ normal git commit created
→ goal-output artifact produced
→ /dev-save
```

---

## Responsibilities

### 1. Accept User Intent

Accept a brief description of what the user wants to accomplish.

If no description provided, prompt:

"What would you like to accomplish? Provide a brief description."

### 2. Define Boundaries

Explicitly distinguish:

| Category | Meaning |
|---|---|
| **In-scope** | Files, behaviors, and changes the goal covers |
| **Out-of-scope** | Files, behaviors, and changes the goal explicitly excludes |

Rules:

- Prefer smaller scopes. Large requests must be decomposed.
- Out-of-scope must be specific, not vague.
- If scope is ambiguous, ask clarifying questions before proceeding.

### 3. Enumerate Requirements

List numbered requirements that are:

- Concrete (not abstract)
- Actionable (an agent can execute them)
- Ordered (dependencies first)
- Bounded (each requirement fits within the scope)

Must NOT invent requirements the user didn't imply.

### 4. Declare Non-goals

Explicitly list what this goal does NOT cover. Examples:

- "Does NOT refactor unrelated files"
- "Does NOT change API contracts"
- "Does NOT update documentation outside scope"

### 5. Define Validation Criteria

Every scope must include validation criteria. Prefer:

- Automated tests or scripts
- Deterministic checks (case-05/06, file existence, git diff)
- Machine-verifiable conditions

Minimize manual verification. If a criterion requires human judgment, note it explicitly.

### 6. Detect Ambiguity

If the user's request is ambiguous:

- STOP generating the scope
- Ask clarifying questions
- Do NOT proceed with assumptions

### 7. Evaluate Auto-Execution Eligibility

After scope generation, determine if the scope qualifies for direct execution.

**Auto-execution criteria** (ALL must be true):

1. File count ≤ 3
2. No public API changes
3. No cross-module dependencies
4. Single-step validation
5. No ambiguous language
6. Non-architectural change
7. Low blast radius

**If ALL criteria met**:
- Execute scope immediately
- Create normal git commits during work
- Produce goal-output artifact
- Report "Workflow completed"

**If ANY criterion not met**:
- Output scope document
- STOP
- Wait for user confirmation before `/goal`

---

## DO

- Ask clarifying questions when intent is ambiguous
- Define explicit in-scope and out-of-scope boundaries
- Include machine-checkable validation criteria
- Prefer smaller scopes (1-3 files ideal)
- Suggest decomposition for scopes affecting 8+ files
- Report "Scope declaration complete" and "No remaining protocol tasks pending" on success

## DO NOT

- **NEVER implement code** (unless auto-execution criteria are ALL met)
- **NEVER modify repository files** (unless auto-execution criteria are ALL met)
- **NEVER commit or checkpoint** (unless auto-execution criteria are ALL met)
- **NEVER silently expand scope**
- **NEVER proceed with ambiguous requirements**
- **NEVER auto-execute when scope is ambiguous, architectural, affects > 3 files, or modifies public APIs**
- **NEVER skip `/goal` for multi-step, cross-cutting, or high-blast-radius work**
- **Prefer smaller scopes over large scopes**

## PRECONDITIONS

- Git repository is initialized
- Project state is known (run `/dev-status` first if unsure)

## FAILURE CONDITIONS

STOP and report failure if ANY of the following occur:

- user intent is empty and no input provided
- scope boundaries cannot be determined
- validation criteria are missing
- goal structure violates the output contract
