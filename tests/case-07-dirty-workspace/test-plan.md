# Case 07 — Dirty Workspace /dev-save Handling

## Purpose

Verify that `/dev-save` handles dirty workspace correctly — it does NOT stage or commit source changes.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- Workspace has uncommitted source changes (modified tracked files)

## Steps

1. Modify a source file (e.g., `README.md`) without committing
2. Run `/dev-save`
3. Inspect git status after save
4. Inspect /dev-save output

## Expected Results

- `/dev-save` completes successfully
- Protocol commit is created (`chore(checkpoint):`)
- Source changes are NOT staged in the protocol commit
- Source changes remain modified in working tree
- `/dev-save` output notes: "Non-protocol files modified but not staged"
- `git status --short` shows modified source files still present

## Failure Criteria

- `/dev-save` stages source files in checkpoint commit
- `/dev-save` commits source files
- `/dev-save` fails because workspace is dirty
- No warning about uncommitted source changes in output
