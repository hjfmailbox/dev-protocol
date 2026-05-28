# Protocol Test Matrix

Machine-testable cases covering the dev-protocol critical path.

Each case uses the format:

```
Case ID
Scenario
Preconditions
Expected Result
Failure Signal
```

---

## Recovery

### R1 — Interrupted /dev-save

**Case ID**: case-07-interrupted-save  
**Scenario**: /dev-save is interrupted mid-execution (e.g., agent stops, session resets)  
**Preconditions**: State files partially updated, no checkpoint commit created  
**Expected Result**: Next /dev-status detects incomplete save. Next /dev-save completes cleanly.  
**Failure Signal**: State corruption, duplicate commits, or missing checkpoint baseline.

### R2 — Compact → Resume

**Case ID**: case-10-compact-resume  
**Scenario**: Session compacted (context cleared). Fresh session starts.  
**Preconditions**: State files exist and are current. Workspace clean.  
**Expected Result**: /dev-status reconstructs full context without chat history. Phase, focus, and next actions are correct.  
**Failure Signal**: Phase = unknown, empty focus, or missing next actions.

### R3 — Drift Recovery

**Case ID**: case-09-history-rewrite  
**Scenario**: Git history rewritten (rebase, reset) after checkpoint.  
**Preconditions**: checkpoint.last_commit no longer exists in history.  
**Expected Result**: /dev-status detects drift, reports high severity, recommends /dev-init.  
**Failure Signal**: /dev-status crashes or reports no drift when checkpoint baseline is invalid.

### R4 — No-op Validation Save

**Case ID**: case-08-noop-save  
**Scenario**: Verification loop concludes with no source changes. /dev-save is run.  
**Preconditions**: Workspace clean. No commits since last checkpoint.  
**Expected Result**: /dev-save creates checkpoint commit with no-op note. State files updated.  
**Failure Signal**: /dev-save fails with "nothing to commit" or refuses to run.

---

## Git Reality

### G1 — Protocol Commit Detection

**Case ID**: case-12-protocol-commit  
**Scenario**: Commits between checkpoint and HEAD include protocol-only commits.  
**Preconditions**: chore(checkpoint), chore(protocol), or chore(state) commits exist.  
**Expected Result**: /dev-status classifies drift = none. Reports informational note only.  
**Failure Signal**: /dev-status reports high drift for protocol-only commits.

### G2 — Source Commit Detection

**Case ID**: case-12-protocol-commit (same as G1, extended)  
**Scenario**: Commits between checkpoint and HEAD include non-protocol commits.  
**Preconditions**: feat/fix/docs/test/refactor commits exist.  
**Expected Result**: /dev-status classifies drift = high. Reports unrecorded commits.  
**Failure Signal**: /dev-status classifies drift = none for source commits.

### G3 — Dirty Workspace Handling

**Case ID**: case-07-dirty-workspace  
**Scenario**: Workspace has uncommitted source changes. /dev-save is run.  
**Preconditions**: Modified tracked files exist. State files exist.  
**Expected Result**: /dev-save commits only protocol files. Source changes remain unstaged. Output notes dirty workspace.  
**Failure Signal**: /dev-save stages source files or fails to note dirty workspace.

### G4 — Staged-only Edge Case

**Case ID**: case-07-dirty-workspace (extended)  
**Scenario**: Only staged changes exist (no modified files). /dev-save is run.  
**Preconditions**: Staged files are non-protocol source files.  
**Expected Result**: /dev-save commits only protocol files. Previously staged source files remain staged.  
**Failure Signal**: /dev-save unstages source files or includes them in checkpoint.

---

## Workflow

### W1 — Normal Workflow

**Case ID**: case-06-goal-workflow (existing)  
**Scenario**: Standard scope → work → save cycle.  
**Preconditions**: Clean workspace. Valid state files.  
**Expected Result**: case-06 PASS. Checkpoint commit created. State updated.  **Failure Signal**: case-06 FAIL or missing checkpoint.

### W2 — Verification Workflow

**Case ID**: case-08-noop-save (same as R4)  
**Scenario**: Verify existing behavior without changes. Save protocol state.  
**Preconditions**: Clean workspace. Behavior confirmed correct.  **Expected Result**: /dev-save succeeds. Checkpoint notes no-op.  
**Failure Signal**: /dev-save fails or requires dummy changes.

### W3 — Continue Loop Workflow (future-compatible)

**Case ID**: case-11-continue-loop  
**Scenario**: next-phase-plan.md exists. User runs continue loop.  
**Preconditions**: Plan file exists with pending loops. Workspace clean.  
**Expected Result**: Next loop derived automatically. Scope generated. Execution ready.  
**Failure Signal**: Loop not found, ambiguous scope, or execution fails.

### W4 — Aborted Goal

**Case ID**: case-11-aborted-goal  
**Scenario**: /goal is aborted mid-implementation. /dev-save is run.  
**Preconditions**: Partial changes exist. Goal status = ABORTED.  
**Expected Result**: /dev-save records aborted state. Partial work documented. Next session knows goal was aborted.  
**Failure Signal**: /dev-save treats aborted goal as completed or fails to record abort.

---

## State Consistency

### S1 — Handoff Mismatch

**Case ID**: case-10-handoff-mismatch  
**Scenario**: handoff.md focus contradicts workflow-state.yml phase.  
**Preconditions**: handoff says "stabilization" but workflow-state says "p2".  
**Expected Result**: /dev-status detects mismatch, reports low drift, recommends /dev-save.  
**Failure Signal**: /dev-status ignores mismatch or reports no drift.

### S2 — Workflow-state Mismatch

**Case ID**: case-10-workflow-state-mismatch  
**Scenario**: workflow-state.yml checkpoint.last_commit does not match HEAD or HEAD~1.  
**Preconditions**: Multiple non-protocol commits since last checkpoint.  
**Expected Result**: /dev-status reports high drift. Recommends /dev-save after committing source.  
**Failure Signal**: /dev-status reports no drift when checkpoint is stale.

### S3 — Checkpoint Mismatch

**Case ID**: case-09-history-rewrite (same as R3)  
**Scenario**: checkpoint.last_commit references a commit that no longer exists.  
**Preconditions**: History rewritten (rebase, reset).  
**Expected Result**: /dev-status detects invalid checkpoint, reports high drift, recommends /dev-init.  
**Failure Signal**: /dev-status crashes or fails to detect invalid baseline.

### S4 — Missing Current-focus

**Case ID**: case-11-phase-inference (same as case-11)  
**Scenario**: current-focus.md does not exist. Focus must be recovered from handoff.md.  
**Preconditions**: current-focus.md absent. handoff.md contains Current Focus section.  
**Expected Result**: /dev-status recovers focus from handoff.md. No error about missing current-focus.md.  
**Failure Signal**: /dev-status reports missing current-focus.md or empty focus.
