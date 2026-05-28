# Case 09 — History Rewrite Resilience

## Purpose

Verify that `/dev-status` handles history rewrites (rebase, reset) gracefully.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- `checkpoint.last_commit` references a valid commit

## Steps

1. Note current `checkpoint.last_commit` value
2. Perform soft reset to move HEAD back (e.g., `git reset --soft HEAD~1`)
3. Run `/dev-status`
4. Inspect drift classification

## Expected Results

- `/dev-status` completes without crashing
- Drift is detected (checkpoint baseline no longer matches HEAD or HEAD~1)
- Drift severity = high (history diverged from checkpoint)
- Output recommends: "Run /dev-init to refresh state"
- Phase and focus are still recoverable from state files

## Failure Criteria

- `/dev-status` crashes when checkpoint baseline is invalid
- `/dev-status` reports no drift when history was rewritten
- `/dev-status` fails to reconstruct context
