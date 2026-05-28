# Case 20 -- Checkpoint Freshness Runtime

## Purpose

Verify that the `/dev-status` **runtime skill** (SKILL.md) defines checkpoint freshness levels, not just the detailed prompt (PROMPT.md).

## Preconditions

- `skills/dev-status/SKILL.md` exists
- `skills/dev-status/PROMPT.md` exists

## Steps

1. Read `skills/dev-status/SKILL.md`
2. Verify it contains Checkpoint Freshness Model
3. Verify it defines fresh/stale/outdated levels
4. Verify it defines thresholds (0-1, 2-5, >5)
5. Read `skills/dev-status/PROMPT.md`
6. Cross-check consistency

## Expected Results

- `SKILL.md` contains "Checkpoint Freshness" or "freshness model"
- `SKILL.md` defines all three levels: fresh, stale, outdated
- `SKILL.md` contains source commit thresholds
- `PROMPT.md` also contains the same concepts
- Both files are synchronized

## Failure Criteria

- `SKILL.md` lacks checkpoint freshness entirely
- `SKILL.md` missing one or more freshness levels
- `SKILL.md` and `PROMPT.md` diverge on freshness semantics
- Thresholds are inconsistent between files
