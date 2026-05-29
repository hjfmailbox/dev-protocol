# Case 39 -- Semantic Drift Classification

## Purpose

Verify that dev-status PROMPT.md classifies drift semantically beyond commit counting.

## Preconditions

- `skills/dev-status/PROMPT.md` exists
- `skills/dev-status/SKILL.md` exists

## Steps

1. Read `skills/dev-status/PROMPT.md`
2. Verify it contains "Semantic drift classification" section
3. Verify it defines documentation-only changes as low drift
4. Verify it defines stabilization-pattern commits as low drift
5. Verify it defines source-impacting commits as high drift
6. Verify it defines roadmap-aligned commits as medium drift
7. Verify it defines test-only changes as low drift
8. Verify SKILL.md or PROMPT.md includes semantic classification in drift output

## Expected Results

- Semantic drift classification section exists
- At least 5 semantic types defined
- Documentation-only changes are low drift
- Stabilization patterns are low drift
- Source-impacting commits are high drift

## Failure Criteria

- Missing semantic drift classification
- All non-protocol commits treated as high drift
- No distinction between documentation and source changes
- No stabilization-pattern recognition
