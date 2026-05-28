# Case 30 -- Continue Loop (Normal)

## Purpose

Verify that `continue loop` correctly reads `next-phase-plan.md`, identifies the next incomplete loop, derives scope, and follows the auto-execution decision path.

## Preconditions

- `skills/continue-loop/PROMPT.md` exists
- `skills/continue-loop/SKILL.md` exists

## Steps

1. Read `skills/continue-loop/PROMPT.md`
2. Verify preconditions check exists (plan existence, workspace cleanliness, blockers, drift)
3. Verify loop detection uses tolerant parsing
4. Verify scope derivation from plan + handoff + recent commits
5. Verify auto-execution criteria are applied after scope derivation
6. Read `skills/continue-loop/SKILL.md`
7. Verify execution sequence matches design

## Expected Results

- Preconditions defined (5 conditions)
- Tolerant loop parsing documented
- Scope derivation rules present
- Auto-execution decision path present (execute OR produce scope)
- Plan status update after completion documented

## Failure Criteria

- Missing precondition checks
- No tolerant parsing support
- Missing scope derivation logic
- Missing auto-execution decision
