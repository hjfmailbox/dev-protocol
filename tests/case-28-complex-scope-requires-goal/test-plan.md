# Case 28 -- Complex Scope Requires /goal

## Purpose

Verify that /dev-scope does NOT auto-execute for complex, ambiguous, or high-blast-radius scopes.

## Preconditions

- `skills/dev-scope/PROMPT.md` exists
- `skills/dev-scope/SKILL.md` exists

## Steps

1. Read `skills/dev-scope/PROMPT.md`
2. Verify blocked scopes are explicitly listed
3. Verify blocked scope examples include: >3 files, architectural changes, API changes, ambiguous work
4. Verify that when auto-execution criteria are NOT met, /dev-scope STOPs and waits for /goal
5. Read `skills/dev-scope/SKILL.md`
6. Verify blocked examples are present

## Expected Results

- Blocked scope examples present (refactor across modules, architecture redesign, OAuth flow)
- When criteria fail, output is scope document + STOP + "Separate /goal required"
- DO NOT constraints prevent auto-execution of architectural/ambiguous/>3 files work

## Failure Criteria

- No blocked scope examples
- Missing STOP behavior for complex scopes
- Auto-execution allowed for architectural or ambiguous work
