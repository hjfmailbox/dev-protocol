# Case 21 -- Goal Completion Closes Workflow

## Purpose

Verify that `/dev-scope` (and by extension `/goal`) prompt includes explicit workflow completion semantics, preventing ambiguous residual task state.

## Preconditions

- `skills/dev-scope/PROMPT.md` exists
- `skills/dev-scope/SKILL.md` exists

## Steps

1. Read `skills/dev-scope/PROMPT.md`
2. Verify output section contains workflow status declaration
3. Read `skills/dev-scope/SKILL.md`
4. Verify DO section contains completion reporting rule

## Expected Results

- `PROMPT.md` contains "Workflow Status" or equivalent completion block
- `PROMPT.md` explicitly states "No remaining protocol tasks pending"
- `SKILL.md` contains "Scope declaration complete" or equivalent
- `SKILL.md` contains "No remaining protocol tasks pending"

## Failure Criteria

- No workflow completion semantics in scope prompt
- Ambiguous end state (no explicit "complete" or "pending" language)
- SKILL.md and PROMPT.md diverge on completion reporting
