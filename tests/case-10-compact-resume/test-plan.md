# Case 10 — Compact → Resume Continuity

## Purpose

Verify that context survives session compaction (/clear or new session start).

## Preconditions

- `.agents/dev-protocol/` exists with current state files
- Workspace is clean
- State files contain valid phase, focus, and next actions

## Steps

1. Verify state files are current (`checkpoint.last_commit` matches HEAD or HEAD~1)
2. Simulate fresh session (read state files as if chat history was cleared)
3. Run `/dev-status`
4. Inspect reconstructed context

## Expected Results

- `/dev-status` reconstructs full context without chat history
- Phase is correct (inferred if `unknown`)
- Focus matches `handoff.md` Current Focus
- Next actions match `handoff.md` Next Recommended Actions
- Blockers match `handoff.md` Blockers
- Drift = none or low (not high)

## Failure Criteria

- Phase = `unknown` when context is sufficient for inference
- Focus is empty or incorrect
- Missing next actions
- Drift = high when state is actually current
