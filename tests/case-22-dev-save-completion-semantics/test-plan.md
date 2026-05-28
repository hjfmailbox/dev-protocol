# Case 22 -- /dev-save Completion Semantics

## Purpose

Verify that `/dev-save` prompt includes explicit workflow completion reporting for both standard and no-op saves.

## Preconditions

- `skills/dev-save/PROMPT.md` exists
- `skills/dev-save/SKILL.md` exists

## Steps

1. Read `skills/dev-save/PROMPT.md`
2. Verify standard save output contains "Workflow completed"
3. Verify no-op save output contains "Workflow completed (no-op)"
4. Read `skills/dev-save/SKILL.md`
5. Verify DO section contains completion reporting rule

## Expected Results

- `PROMPT.md` standard save output contains "Workflow completed"
- `PROMPT.md` no-op save output contains "Workflow completed (no-op)"
- `PROMPT.md` both outputs contain "No remaining protocol tasks"
- `SKILL.md` contains "Workflow completed" or equivalent completion rule

## Failure Criteria

- Standard save missing completion declaration
- No-op save missing completion declaration
- No "No remaining protocol tasks" language
