# Case 32 -- Ambiguous Next Loop

## Purpose

Verify that `continue loop` stops and asks for clarification when the next planned loop is ambiguous.

## Preconditions

- `skills/continue-loop/PROMPT.md` exists
- `skills/continue-loop/SKILL.md` exists

## Steps

1. Read `skills/continue-loop/PROMPT.md`
2. Verify ambiguity detection occurs BEFORE scope derivation
3. Verify ambiguity signals: vague description, no files, no validation, dependencies
4. Verify STOP output contains loop description and clarification request
5. Read `skills/continue-loop/SKILL.md`
6. Verify ambiguity handling in execution sequence

## Expected Results

- Ambiguity detection precedes scope derivation
- Ambiguity signals explicitly listed
- STOP output: "Next loop is ambiguous: [description]"
- Recommendation to clarify plan or run /dev-scope

## Failure Criteria

- Ambiguity detection missing or after scope derivation
- Ambiguous loops allowed to proceed
- Missing clarification recommendation
