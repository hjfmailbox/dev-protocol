# Case 40 -- Semantic Active-Work Reconstruction

## Purpose

Verify that dev-status PROMPT.md infers active work themes semantically from commit patterns.

## Preconditions

- `skills/dev-status/PROMPT.md` exists

## Steps

1. Read `skills/dev-status/PROMPT.md`
2. Verify Active Work Reconstruction section includes semantic theme inference
3. Verify it defines stabilization theme (docs + fix(tests) pattern)
4. Verify it defines protocol feature expansion theme (feat(protocol) + skills additions)
5. Verify it defines test coverage expansion theme (test(case-NN) sequence)
6. Verify it defines active development theme (mix of feat/fix/test on same component)
7. Verify it references roadmap sections and deferred items as enrichment sources

## Expected Results

- Semantic theme inference exists in Active Work Reconstruction
- At least 4 theme patterns defined
- Roadmap sections used as enrichment source
- Deferred items used as enrichment source
- Git history remains primary source

## Failure Criteria

- Missing semantic theme inference
- Only literal topic aggregation
- No roadmap/deferred enrichment
- No stabilization pattern recognition
