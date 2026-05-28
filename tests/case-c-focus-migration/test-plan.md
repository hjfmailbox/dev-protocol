# Case C — Current Focus Migration

## Purpose

Verify that focus information is recoverable from `handoff.md` without `current-focus.md`.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- `current-focus.md` does NOT exist
- `handoff.md` contains "Current Focus" section

## Steps

1. Verify `current-focus.md` does not exist
2. Run `/dev-status`
3. Inspect output focus field
4. Verify `handoff.md` "Current Focus" is readable

## Expected Results

- `/dev-status` outputs correct focus from `handoff.md`
- Focus is not empty
- Focus is not "unknown"
- No error about missing `current-focus.md`
- `references/workflow-rules.md` contains preventive rule against `current-focus.md`

## Failure Criteria

- `/dev-status` reports missing `current-focus.md`
- `/dev-status` outputs empty focus
- Focus recovery depends on `current-focus.md`
- `references/workflow-rules.md` does not document `current-focus.md` prevention
