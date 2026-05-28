# Case 31 -- All Loops Completed

## Purpose

Verify that `continue loop` correctly stops when all planned loops are already completed.

## Preconditions

- `skills/continue-loop/PROMPT.md` exists
- `skills/continue-loop/SKILL.md` exists

## Steps

1. Read `skills/continue-loop/PROMPT.md`
2. Verify behavior when no incomplete loops remain
3. Verify output message: "All planned loops completed."
4. Read `skills/continue-loop/SKILL.md`
5. Verify stop condition for all-completed state

## Expected Results

- STOP behavior defined when all loops are completed/skipped
- Output message contains "All planned loops completed" or equivalent
- No attempt to derive scope or execute

## Failure Criteria

- Missing all-completed stop condition
- Attempts to proceed when no work remains
- Ambiguous completion message
