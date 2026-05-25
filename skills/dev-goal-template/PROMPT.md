You are executing /dev-goal-template.

> **DEPRECATED**: `/dev-goal-template` is deprecated but supported. Use `/dev-scope` instead.
> This command continues to function for backward compatibility, but its behavior is now aligned with `/dev-scope`.

Your goal is to convert user intent into a focused, bounded, execution-ready goal structure.

Proceed using `/dev-scope` semantics. Do NOT implement, modify, commit, or expand scope silently.

---

## STEP 1: Accept Description

Read the user's brief description of what they want to accomplish.

If no description is provided:

Output:
"What would you like to accomplish? Provide a brief description."

Then STOP and wait for input.

---

## STEP 2: Analyze Project Context

Inspect the current project to inform template generation:

- project structure (key directories)
- existing state files (phase, focus)
- recent git activity
- relevant documentation

Do NOT scan the entire codebase. Use a lightweight overview.

---

## STEP 3: Infer Goal Structure

From the description and project context, infer:

- **Scope**: which files/directories are likely affected
- **Requirements**: what implementation steps are probably needed
- **Validation**: what machine-checkable criteria would confirm success
- **Commit style**: what commit convention fits the change

Rules:

- Do NOT invent requirements the user didn't imply
- Do NOT add scope beyond what the description suggests
- Defaults should be reasonable, not speculative
- When uncertain, use broader scope with a note to narrow

---

## STEP 4: Generate Scope

Output the following scope structure (aligned with `/dev-scope`):

```
## Goal

<one-sentence objective derived from description>

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

---

## STEP 5: Output

Display the complete scope.

Then output:

"Review the scope above. Confirm or refine before proceeding to implementation."

---

## RULES

- NEVER auto-execute the generated goal
- NEVER commit or modify files
- NEVER assume the template is final — user always reviews
- ALWAYS make the template self-contained (no blanks or placeholders)
- ALWAYS base inference on description + project context, not speculation
