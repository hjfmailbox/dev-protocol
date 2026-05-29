# Case 36 -- Generated Loops Satisfy Continue-Loop Constraints

## Purpose

Verify that `generate plan` produces loops compatible with `continue loop` auto-execution constraints.

## Preconditions

- `skills/generate-plan/PROMPT.md` exists
- `skills/continue-loop/PROMPT.md` exists
- `skills/continue-loop/SKILL.md` exists

## Steps

1. Read `skills/generate-plan/PROMPT.md`
2. Verify STEP 5 validates loops against continue-loop constraints
3. Verify constraints checked: file count ≤ 3, non-ambiguous language, non-architectural, concrete validation
4. Read `skills/generate-plan/SKILL.md`
5. Verify it contains "Validate Plan" section with continue-loop constraint checks
6. Verify loops use `**Status:** pending` format
7. Verify loops use `## Loop N — [Name]` format (tolerant parsing compatible)
8. Verify SKILL.md requires "auto-execution-friendly wording"

## Expected Results

- Generated loops validated against continue-loop constraints
- Status format compatible with tolerant parsing
- Loop header format compatible with tolerant parsing
- Auto-execution-friendly wording required

## Failure Criteria

- No validation against continue-loop constraints
- Status format incompatible
- Loop header format incompatible
- No auto-execution-friendly wording requirement
