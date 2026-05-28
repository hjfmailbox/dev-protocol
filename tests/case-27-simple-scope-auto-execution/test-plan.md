# Case 27 -- Simple Scope Auto-Execution

## Purpose

Verify that /dev-scope auto-executes for simple, low-risk scopes that meet all criteria.

## Preconditions

- `skills/dev-scope/PROMPT.md` exists
- `skills/dev-scope/SKILL.md` exists

## Steps

1. Read `skills/dev-scope/PROMPT.md`
2. Verify auto-execution criteria are defined
3. Verify auto-execution examples include simple scopes (≤3 files, non-architectural)
4. Read `skills/dev-scope/SKILL.md`
5. Verify auto-execution decision logic is present
6. Verify auto-execution path produces normal commits and goal-output artifact

## Expected Results

- Auto-execution criteria explicitly listed (7 criteria)
- Simple scope examples present (fix typo, add import, update docs)
- Auto-execution path produces "Workflow completed" and prompts for /dev-save
- No requirement for separate /goal when criteria are met

## Failure Criteria

- Missing auto-execution criteria
- No distinction between auto-executable and complex scopes
- PROMPT.md or SKILL.md missing auto-execution section
