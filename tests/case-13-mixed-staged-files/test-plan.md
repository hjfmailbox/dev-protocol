# Case 13 — Save Blocked by Mixed Staged Files

## Purpose

Verify that `/dev-save` rejects saving when both protocol files and source files are staged.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- Git repository is initialized
- Protocol files and source files are both staged

## Steps

1. Stage a protocol file (`git add .agents/dev-protocol/workflow-state.yml`)
2. Stage a source file (`git add README.md` or any non-protocol file)
3. Run `/dev-save`
4. Inspect output and git status

## Expected Results

- `/dev-save` detects mixed staged files (protocol + source)
- `/dev-save` STOPs and reports failure
- Output explicitly states: "Mixed staged files detected. Unstage source files first."
- No protocol commit is created
- Source files remain staged (not committed)

## Failure Criteria

- `/dev-save` proceeds and creates a mixed commit
- `/dev-save` commits source changes alongside protocol changes
- `/dev-save` silently unstages source files without warning
- No error message about mixed staged files
