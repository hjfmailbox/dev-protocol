# Case 43 -- Onboarding Documentation Consistency

## Purpose

Verify that onboarding documents (README.md, project-rules.md, command-contracts.md) contain no contradictions, false statements, or obsolete v1 references that would mislead a new agent.

## Preconditions

- README.md exists
- .agents/dev-protocol/project-rules.md exists
- docs/command-contracts.md exists

## Steps

1. Read README.md
2. Verify /goal is listed as a canonical v2 command, not a legacy alias
3. Verify legacy alias table does not include /goal
4. Read .agents/dev-protocol/project-rules.md
5. Verify no false statements about "no git history on master branch"
6. Verify /dev-save description reflects auto-commit behavior
7. Verify command list includes v2 canonical commands (generate plan, continue loop)
8. Read docs/command-contracts.md
9. Verify semantic terminology is consistent with skills
10. Verify no stale v1 path references (e.g., `docs/next-phase-plan.md` as canonical)

## Expected Results

- /goal appears in canonical commands table
- /goal does NOT appear in legacy aliases table
- project-rules.md describes /dev-save auto-commit behavior correctly
- project-rules.md includes generate plan and continue loop in command reference
- No false or obsolete statements remain

## Failure Criteria

- /goal still listed as legacy alias
- project-rules.md contains contradictions with actual v2 behavior
- command-contracts.md uses inconsistent terminology
