# Case 38 -- Semantic Loop Completion Detection

## Purpose

Verify that continue-loop PROMPT.md uses semantic equivalence to determine loop completion.

## Preconditions

- `skills/continue-loop/PROMPT.md` exists
- `skills/continue-loop/SKILL.md` exists

## Steps

1. Read `skills/continue-loop/PROMPT.md`
2. Verify auto-execution path includes semantic completion check
3. Verify completion check uses semantic equivalence rules
4. Verify git reality is used as confirming evidence
5. Verify test outcomes are used as confirming evidence
6. Read `skills/continue-loop/SKILL.md`
7. Verify it contains semantic completion concepts

## Expected Results

- Auto-execution path references semantic completion check
- Git reality confirms intent
- Test outcomes validate criteria
- Semantic ambiguity has explicit handling (STOP and ask)

## Failure Criteria

- No semantic completion check in auto-execution path
- Completion detection requires literal wording match only
- No git reality confirmation
- No test outcome validation
