# Case 29 -- Ambiguous Scope Clarification

## Purpose

Verify that ambiguous scopes trigger clarifying questions instead of auto-execution or silent assumption.

## Preconditions

- `skills/dev-scope/PROMPT.md` exists
- `skills/dev-scope/SKILL.md` exists

## Steps

1. Read `skills/dev-scope/PROMPT.md`
2. Verify ambiguity detection precedes auto-execution evaluation
3. Verify ambiguous scopes trigger 1-3 clarifying questions
4. Verify auto-execution criteria include "No ambiguous language"
5. Read `skills/dev-scope/SKILL.md`
6. Verify ambiguity detection is a distinct responsibility step

## Expected Results

- Ambiguity detection occurs BEFORE auto-execution decision
- Ambiguous scopes produce clarifying questions, not auto-execution
- "No ambiguous language" is one of the auto-execution criteria
- Vague verbs ("improve", "optimize", "clean up") trigger ambiguity

## Failure Criteria

- Ambiguity detection missing or after auto-execution decision
- Ambiguous scopes allowed to auto-execute
- Missing clarifying question examples
