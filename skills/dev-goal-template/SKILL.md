# /dev-goal-template

## Purpose

Generate a standardized goal template to reduce manual prompt authoring friction.

Goal:

Produce a reusable, well-structured goal definition optimized for `/goal` usage in real projects.

---

## When to Use

- Starting a new development goal that needs clear scope and validation
- Onboarding a new project to dev-protocol and need goal structure guidance
- Reducing friction when writing complex multi-step goals
- Ensuring goal definitions include all necessary sections

---

## When NOT to Use

- Simple, single-step tasks that don't need formal scoping
- Goals already fully specified by the user
- Exploration or research tasks without concrete deliverables

---

## What It Does

Generates a goal template with the following sections:

1. **Goal** — one-sentence objective
2. **Scope** — allowed and forbidden files/areas
3. **Requirements** — numbered implementation tasks
4. **Validation** — machine-checkable success criteria
5. **Expected Commit Style** — commit convention for the goal

The output is ready to paste into `/goal` with minimal editing.

---

## Typical Workflow

```
/dev-goal-template <brief description>
→ template generated
→ user reviews and fills in specifics
→ /goal <filled template>
→ implement
→ /dev-checkpoint
```

---

## Responsibilities

### 1. Accept Brief Description

Accept a short natural language description of the intended goal.

If no description provided, prompt:

"What would you like to accomplish?"

---

### 2. Infer Goal Structure

From the description, infer:

- likely scope (files/directories affected)
- probable requirements (implementation steps)
- reasonable validation criteria
- appropriate commit style

Must NOT invent requirements the user didn't imply.

---

### 3. Generate Template

Output a goal template in the following format:

```
## Goal

<one-sentence objective>

## Scope

### Allowed Files

- <file or directory patterns>

### Forbidden

- <constraints>

## Requirements

1. <requirement one>
2. <requirement two>
...

## Validation

1. <machine-checkable criterion>
2. <machine-checkable criterion>
...

## Expected Commit Style

<type>(<scope>): <summary>

<additional commit guidance>
```

---

### 4. Review Prompt

After generating, output:

"Review the template above. Fill in specifics, then pass to `/goal`."

---

## Output Rules

- Template must be self-contained
- No placeholder text like blanks or "fill in here"
- Inferred content should be reasonable defaults, not blanks
- User can override any section before passing to `/goal`

---

## Failure Rules

Template generation fails if:

- description is empty and user provides no input
- inferred scope contradicts known project structure
- generated template violates goal output contract format
