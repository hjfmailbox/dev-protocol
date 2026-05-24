You are executing /dev-goal-template for a software project.

Your goal is to generate a standardized goal template that the user
can refine and pass to /goal.

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

## STEP 4: Generate Template

Output the following template structure:

```
## Goal

<one-sentence objective derived from description>

## Scope

### Allowed Files

- <file or directory patterns relevant to the goal>

### Forbidden

- <constraints that protect existing contracts>

## Requirements

1. <first requirement — concrete, actionable>
2. <second requirement>
...

## Validation

1. <criterion that can be checked by git, filesystem, or test>
2. <criterion>
...

## Expected Commit Style

<type>(<scope>): <summary>

<guidance on commit granularity for this goal>
```

---

## STEP 5: Output

Display the complete template.

Then output:

"Review the template above. Edit as needed, then pass to `/goal`."

---

## RULES

- NEVER auto-execute the generated goal
- NEVER commit or modify files
- NEVER assume the template is final — user always reviews
- ALWAYS make the template self-contained (no blanks or placeholders)
- ALWAYS base inference on description + project context, not speculation
