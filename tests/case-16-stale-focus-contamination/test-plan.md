# Case 16 -- Stale Focus Contamination

## Purpose

Verify that `/dev-status` does NOT return stale focus when checkpoint is old and recent commits have changed.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- `workflow-state.yml` contains an OLD focus (e.g., "dev-status-protocol-commit-detection")
- Recent git commits indicate DIFFERENT active work (e.g., "command contract hardening")
- Git repository is initialized

## Steps

1. Ensure `workflow-state.yml` has `focus: "old-focus-string"` and `checkpoint.last_commit` is several commits behind HEAD
2. Ensure recent commits reflect new work (e.g., `docs(protocol): ...`, `fix(tests): ...`)
3. Run `/dev-status`
4. Inspect output for focus field

## Expected Results

- `/dev-status` detects stale checkpoint (checkpoint: stale or outdated)
- `/dev-status` does NOT return the old focus from `workflow-state.yml`
- `/dev-status` infers focus from git reality or recent scoped work
- Focus line includes: `(inferred from <source>)` where source is git-derived
- Output explicitly notes: "Previous workflow-state focus was stale (<N> commits old). Run /dev-save to persist."

## Failure Criteria

- `/dev-status` returns old focus despite stale checkpoint
- `/dev-status` reports `focus: old-focus-string` without stale warning
- No inference source is stated
- Stale checkpoint is not detected
