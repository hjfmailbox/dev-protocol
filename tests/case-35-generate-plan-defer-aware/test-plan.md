# Case 35 -- Generate-Plan Defer-Aware Planning

## Purpose

Verify that `generate plan` reads deferred-improvements.md and roadmap, incorporating unresolved items into generated loops.

## Preconditions

- `skills/generate-plan/PROMPT.md` exists
- `.agents/dev-protocol/docs/deferred-improvements.md` exists
- `docs/v2-redesign-roadmap.md` exists

## Steps

1. Read `skills/generate-plan/PROMPT.md`
2. Verify STEP 1 reads `docs/v2-redesign-roadmap.md` and `.agents/dev-protocol/docs/deferred-improvements.md`
3. Verify STEP 2 infers focus from deferred items and roadmap
4. Verify generated plans prefer small loops over large refactors
5. Verify SKILL.md requires reading deferred-improvements.md
6. Verify PROMPT.md includes deferred items in "Context Used" output

## Expected Results

- Deferred items influence loop generation
- Roadmap items influence loop generation
- Plans avoid repo-wide refactors unless requested
- Context output includes deferred and roadmap references

## Failure Criteria

- Deferred items not read
- Roadmap not read
- Plans ignore documented friction
- No context output for deferred/roadmap
