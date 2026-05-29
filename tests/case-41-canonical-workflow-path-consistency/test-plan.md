# Case 41 -- Canonical Workflow Path Consistency

## Purpose

Verify that `generate plan` and `continue loop` use the same canonical path for `next-phase-plan.md`, eliminating the workflow breakage identified in protocol-hard-review.md F1.

## Preconditions

- `skills/generate-plan/PROMPT.md` exists
- `skills/generate-plan/SKILL.md` exists
- `skills/continue-loop/PROMPT.md` exists
- `skills/continue-loop/SKILL.md` exists

## Steps

1. Read `skills/generate-plan/PROMPT.md`
2. Verify it specifies output path as `.agents/dev-protocol/next-phase-plan.md`
3. Read `skills/generate-plan/SKILL.md`
4. Verify it specifies output path as `.agents/dev-protocol/next-phase-plan.md`
5. Read `skills/continue-loop/PROMPT.md`
6. Verify it reads plan from `.agents/dev-protocol/next-phase-plan.md`
7. Read `skills/continue-loop/SKILL.md`
8. Verify it reads plan from `.agents/dev-protocol/next-phase-plan.md`
9. Read `docs/command-contracts.md`
10. Verify generate-plan side effects reference `.agents/dev-protocol/next-phase-plan.md`
11. Verify continue-loop preconditions reference `.agents/dev-protocol/next-phase-plan.md`

## Expected Results

- generate-plan writes to `.agents/dev-protocol/next-phase-plan.md`
- continue-loop reads from `.agents/dev-protocol/next-phase-plan.md`
- command-contracts.md reflects unified path
- No reference to `docs/next-phase-plan.md` in generate-plan or command-contracts

## Failure Criteria

- Path mismatch between generate-plan output and continue-loop input
- `docs/next-phase-plan.md` still referenced as canonical path
- command-contracts.md documents divergent paths
