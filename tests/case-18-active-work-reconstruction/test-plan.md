# Case 18 -- Active Work Reconstruction

## Purpose

Verify that `/dev-status` reconstructs active work from recent commits when `/dev-save` has not been run after goal work.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- Recent commits exist that reflect goal work
- No protocol commit (`chore(checkpoint):`) since the goal work
- Git repository is initialized

## Steps

1. Verify recent commits contain related work (e.g., `docs(protocol): ...`, `fix(tests): ...`, `test(case-13): ...`)
2. Verify no `chore(checkpoint):` commit exists after the most recent source commit
3. Run `/dev-status`
4. Inspect **Active Work** section

## Expected Results

- `/dev-status` aggregates recent commits by topic/theme
- If 2+ commits share a topic, **Active Work** reports the inferred workstream
- Example: "slash command contract hardening and test expansion"
- Active work is derived from git history, not from stale workflow-state

## Failure Criteria

- **Active Work** is empty or "none" when recent commits clearly indicate ongoing work
- **Active Work** comes from stale workflow-state instead of git reality
- No commit aggregation or theme detection
