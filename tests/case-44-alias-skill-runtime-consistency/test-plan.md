# Case 44 -- Alias Skill Runtime Consistency

## Purpose

Verify that deprecated alias skills contain no stale v1 content that contradicts current v2 behavior. A new agent loading an alias skill must be redirected to the correct v2 command without encountering obsolete guidance.

## Preconditions

- skills/dev-checkpoint/PROMPT.md exists
- skills/dev-resume/PROMPT.md exists
- skills/dev-bootstrap/PROMPT.md exists
- skills/dev-doctor/PROMPT.md exists
- skills/dev-help/PROMPT.md exists
- skills/dev-goal-template/PROMPT.md exists

## Steps

1. Read each alias skill PROMPT.md
2. Verify each file contains a clear deprecation notice redirecting to the v2 equivalent
3. Verify no alias claims "NEVER auto-commit" (contradicts /dev-save v2 behavior)
4. Verify no alias uses deprecated drift terms "none/minor/major"
5. Verify no alias references stale v1-only paths (`.agent/` without `.agents/`)
6. Verify no alias describes obsolete v1 command lifecycle
7. Verify dev-help points to README.md and command-contracts.md instead of displaying v1 command table

## Expected Results

- All alias PROMPT.md files contain deprecation notice + redirect to v2
- No contradiction with v2 auto-commit behavior
- No deprecated drift terminology
- No stale path references
- dev-help references current documentation

## Failure Criteria

- Any alias PROMPT.md contains guidance contradicting v2 behavior
- Deprecated drift terms (minor/major) still present
- Stale v1 paths referenced without noting legacy status
- dev-help still displays v1 command table
