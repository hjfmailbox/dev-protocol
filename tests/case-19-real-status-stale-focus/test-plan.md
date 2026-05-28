# Case 19 -- Real Status Stale Focus Validation

## Purpose

Verify that the `/dev-status` **runtime skill** (SKILL.md) prevents stale focus contamination, not just the detailed prompt (PROMPT.md).

## Preconditions

- `skills/dev-status/SKILL.md` exists
- `skills/dev-status/PROMPT.md` exists

## Steps

1. Read `skills/dev-status/SKILL.md`
2. Verify it contains Focus Inference logic
3. Verify it contains the downgrade rule for stale checkpoints
4. Verify it contains the stale focus prevention constraint
5. Read `skills/dev-status/PROMPT.md`
6. Cross-check that both files define consistent focus inference precedence

## Expected Results

- `SKILL.md` contains "Focus Inference" section or equivalent logic
- `SKILL.md` contains "downgrade" or "low confidence" rule for stale checkpoints
- `SKILL.md` contains "NEVER return stale focus" or equivalent constraint
- `PROMPT.md` also contains the same concepts
- Both files are synchronized (no divergence between runtime entry point and detailed prompt)

## Failure Criteria

- `SKILL.md` lacks Focus Inference entirely
- `SKILL.md` allows workflow-state focus to override git reality without downgrade
- `SKILL.md` does not prevent stale focus return
- `SKILL.md` and `PROMPT.md` diverge on focus inference semantics
