# Case B — No-op Validation Save

## Purpose

Verify that `/dev-save` succeeds on a clean workspace with no source changes.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- Workspace is clean (no uncommitted changes)
- No source code changes since last checkpoint

## Steps

1. Ensure workspace is clean (`git status --short` returns empty)
2. Run `/dev-save`
3. Inspect output
4. Verify git log

## Expected Results

- `/dev-save` completes successfully
- Protocol commit is created (`chore(checkpoint):`)
- Commit message notes no-op: "sync state after validation — no changes required"
- `checkpoint.last_updated` is updated
- `handoff.md` contains no-op summary
- Workspace remains clean after commit

## Failure Criteria

- `/dev-save` fails because "nothing to commit"
- `/dev-save` refuses to run on clean workspace
- No checkpoint commit is created
- State files are not updated
