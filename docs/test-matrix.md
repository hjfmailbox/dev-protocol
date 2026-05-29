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

**Case ID**: case-07-dirty-workspace
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

### G5 — Mixed Staged Files Rejection

**Case ID**: case-13-mixed-staged-files
**Scenario**: Both protocol files and source files are staged. /dev-save is run.
**Preconditions**: Protocol files and source files both in staging area.
**Expected Result**: /dev-save rejects mixed commits. STOPs before creating commit.
**Failure Signal**: /dev-save proceeds with mixed commit or silently drops source files.

---

## Workflow

### W1 — Normal Workflow

**Case ID**: case-06-goal-workflow
**Scenario**: Standard scope → work → save cycle.
**Preconditions**: Clean workspace. Valid state files.
**Expected Result**: case-06 PASS. Checkpoint commit created. State updated.
**Failure Signal**: case-06 FAIL or missing checkpoint.

### W2 — Verification Workflow

**Case ID**: case-08-noop-save (same as R4)
**Scenario**: Verify existing behavior without changes. Save protocol state.
**Preconditions**: Clean workspace. Behavior confirmed correct.
**Expected Result**: /dev-save succeeds. Checkpoint notes no-op.
**Failure Signal**: /dev-save fails or requires dummy changes.

### W3 — Continue Loop Workflow

**Case ID**: case-30-continue-loop-normal
**Scenario**: next-phase-plan.md exists. User runs continue loop.
**Preconditions**: Plan file exists with pending loops. Workspace clean.
**Expected Result**: Next loop derived automatically. Scope generated. Execution ready.
**Failure Signal**: Loop not found, ambiguous scope, or execution fails.

### W4 — All Loops Completed

**Case ID**: case-31-all-loops-completed
**Scenario**: All planned loops are already completed.
**Preconditions**: Plan file exists with all loops marked completed.
**Expected Result**: continue loop reports "All planned loops completed." STOPs gracefully.
**Failure Signal**: Crashes, infinite loop, or incorrect next loop selected.

### W5 — Ambiguous Next Loop

**Case ID**: case-32-ambiguous-next-loop
**Scenario**: Next loop lacks files or validation criteria.
**Preconditions**: Plan file exists with vague next loop.
**Expected Result**: continue loop STOPs on ambiguity. Asks for clarification.
**Failure Signal**: Proceeds with incomplete scope or ignores ambiguity.

### W6 — Large Loop Requires /goal

**Case ID**: case-33-large-loop-requires-goal
**Scenario**: Next loop affects >3 files or is architectural.
**Preconditions**: Plan file exists with complex next loop.
**Expected Result**: continue loop produces scope document. Does NOT auto-execute.
**Failure Signal**: Auto-executes complex loop without user confirmation.

### W7 — Generate Plan Basic Workflow

**Case ID**: case-34-generate-plan-basic
**Scenario**: generate plan creates next-phase-plan.md from context.
**Preconditions**: State files exist. Context available.
**Expected Result**: Structured plan created with numbered loops. Compatible with continue loop.
**Failure Signal**: Missing skill files, wrong loop format, or execution prohibition missing.

### W8 — Generate Plan Defer-Aware

**Case ID**: case-35-generate-plan-defer-aware
**Scenario**: generate plan reads deferred improvements and roadmap.
**Preconditions**: deferred-improvements.md and roadmap exist.
**Expected Result**: Plan incorporates deferred items and roadmap priorities.
**Failure Signal**: Ignores deferred items or creates overly large loops.

### W9 — Generate Plan Continue-Loop Constraints

**Case ID**: case-36-generate-plan-continue-loop-constraints
**Scenario**: Generated loops must satisfy continue-loop auto-execution constraints.
**Preconditions**: generate-plan skill exists. continue-loop skill exists.
**Expected Result**: Loops validated against file count, ambiguity, architectural constraints.
**Failure Signal**: Loops violate constraints without warning notes.

### W10 — Auto-Execution Simple Scope

**Case ID**: case-27-simple-scope-auto-execution
**Scenario**: /dev-scope on simple request auto-executes directly.
**Preconditions**: Request affects ≤3 files, non-architectural, concrete.
**Expected Result**: Scope executed directly. Normal commits created. goal-output produced.
**Failure Signal**: Requires separate /goal for trivial work.

### W11 — Complex Scope Requires /goal

**Case ID**: case-28-complex-scope-requires-goal
**Scenario**: /dev-scope on complex request produces scope document.
**Preconditions**: Request is architectural, cross-cutting, or ambiguous.
**Expected Result**: Scope document produced. STOPs. Waits for /goal.
**Failure Signal**: Auto-executes complex work without confirmation.

### W12 — Ambiguous Scope Clarification

**Case ID**: case-29-ambiguous-scope-clarification
**Scenario**: /dev-scope detects ambiguity before scope generation.
**Preconditions**: Request is vague or missing validation criteria.
**Expected Result**: Ambiguity detection precedes auto-execution. Clarifying questions asked.
**Failure Signal**: Proceeds with ambiguous scope or skips clarification.

### W13 — Canonical Workflow Path Consistency

**Case ID**: case-41-canonical-workflow-path-consistency
**Scenario**: generate plan and continue loop use same next-phase-plan.md path.
**Preconditions**: Both skills exist and are implemented.
**Expected Result**: generate plan writes to `.agents/dev-protocol/next-phase-plan.md`. continue loop reads from same path.
**Failure Signal**: Path mismatch between generate-plan output and continue-loop input.

---

## State Consistency

### S1 — Phase Inference

**Case ID**: case-11-phase-inference
**Scenario**: workflow-state.yml reports phase: unknown. /dev-status infers phase.
**Preconditions**: State files exist. phase is unknown or stale.
**Expected Result**: Phase inferred from git reality, roadmap, or handoff. Not left as unknown.
**Failure Signal**: Phase remains unknown despite available context.

### S2 — Phase Inference Precedence

**Case ID**: case-14-phase-inference-precedence
**Scenario**: Multiple phase sources conflict.
**Preconditions**: git reality, workflow-state, handoff, and roadmap all provide phase signals.
**Expected Result**: Correct precedence applied: git reality > workflow-state > handoff > roadmap > fallback.
**Failure Signal**: Wrong precedence order or stale phase overriding git reality.

### S3 — Stale Focus Contamination

**Case ID**: case-16-stale-focus-contamination
**Scenario**: checkpoint is stale but workflow-state focus is old.
**Preconditions**: Multiple source commits since last checkpoint.
**Expected Result**: /dev-status prefers git-derived focus over stale workflow-state focus.
**Failure Signal**: Returns old focus despite newer active work in git history.

### S4 — Checkpoint Freshness

**Case ID**: case-17-checkpoint-freshness
**Scenario**: checkpoint.last_commit is far behind HEAD.
**Preconditions**: Multiple non-protocol commits since last save.
**Expected Result**: Freshness level reported (fresh/stale/outdated). Confidence adjusted.
**Failure Signal**: Incorrect freshness classification or missing confidence adjustment.

### S5 — Checkpoint Freshness Runtime

**Case ID**: case-20-checkpoint-freshness-runtime
**Scenario**: SKILL.md and PROMPT.md both define freshness model consistently.
**Preconditions**: Both files exist.
**Expected Result**: Freshness levels and thresholds match between SKILL.md and PROMPT.md.
**Failure Signal**: Divergence between SKILL.md and PROMPT.md definitions.

### S6 — Focus Migration

**Case ID**: case-26-focus-migration
**Scenario**: current-focus.md does not exist. Focus recovered from handoff.md.
**Preconditions**: current-focus.md absent. handoff.md contains Current Focus section.
**Expected Result**: /dev-status recovers focus from handoff.md. No error about missing current-focus.md.
**Failure Signal**: /dev-status reports missing current-focus.md or empty focus.

### S7 — Active Work Reconstruction

**Case ID**: case-18-active-work-reconstruction
**Scenario**: Recent commits exist but no save since goal work.
**Preconditions**: Source commits since last checkpoint. State not updated.
**Expected Result**: /dev-status reconstructs active work from git history.
**Failure Signal**: Active work section empty despite recent commits.

---

## Semantic Validation

### V1 — Semantic Validation Equivalence

**Case ID**: case-37-semantic-validation-equivalence
**Scenario**: continue-loop interprets validation criteria semantically.
**Preconditions**: continue-loop PROMPT.md exists with semantic equivalence section.
**Expected Result**: Equivalence rules defined. Examples present. Non-equivalence signals documented.
**Failure Signal**: Literal string matching only. No semantic interpretation.

### V2 — Semantic Loop Completion

**Case ID**: case-38-semantic-loop-completion
**Scenario**: continue-loop detects loop completion via semantic equivalence.
**Preconditions**: continue-loop auto-execution path includes semantic completion check.
**Expected Result**: Git reality and test outcomes confirm completion. Ambiguity handled.
**Failure Signal**: Completion requires literal wording match only.

### V3 — Semantic Drift Classification

**Case ID**: case-39-semantic-drift-classification
**Scenario**: /dev-status classifies drift by semantic intent, not just count.
**Preconditions**: dev-status PROMPT.md contains semantic drift classification.
**Expected Result**: Documentation-only = low, stabilization-pattern = low, source-impacting = high.
**Failure Signal**: All non-protocol commits treated as high drift.

### V4 — Semantic Active-Work Reconstruction

**Case ID**: case-40-semantic-active-work
**Scenario**: /dev-status infers active work themes from commit patterns.
**Preconditions**: dev-status PROMPT.md contains semantic theme inference.
**Expected Result**: Stabilization, protocol expansion, test coverage, and active development themes defined.
**Failure Signal**: Only literal topic aggregation. No semantic inference.

---

## Completion Semantics

### C1 — Goal Completion Closes Workflow

**Case ID**: case-21-goal-completion-closes-workflow
**Scenario**: /dev-scope reports workflow completion after scope declaration.
**Preconditions**: /dev-scope executed successfully.
**Expected Result**: "Workflow completed" and "No remaining protocol tasks" in output.
**Failure Signal**: Workflow status missing or incorrect.

### C2 — /dev-save Completion Semantics

**Case ID**: case-22-dev-save-completion-semantics
**Scenario**: /dev-save reports workflow completion after save.
**Preconditions**: /dev-save executed successfully.
**Expected Result**: "Workflow completed" and "No remaining protocol tasks" in output.
**Failure Signal**: Missing completion declaration.

### C3 — No-op Validation Completion

**Case ID**: case-23-no-op-validation-completion
**Scenario**: No-op save produces valid completion status.
**Preconditions**: Clean workspace. No source changes.
**Expected Result**: /dev-save reports no-op completion. /dev-status reports protocol task status.
**Failure Signal**: /dev-save fails or /dev-status missing protocol task status.

---

## Scope Behavior

### SC1 — Scope Misuse Detection

**Case ID**: case-15-scope-misuse
**Scenario**: /dev-scope prevents auto-execution of ambiguous or architectural work.
**Preconditions**: /dev-scope prompt contains DO NOT and FAILURE CONDITIONS.
**Expected Result**: Ambiguous scopes trigger clarification. Architectural scopes require /goal.
**Failure Signal**: Auto-executes complex work without validation.

### SC2 — Real Status Stale Focus

**Case ID**: case-19-real-status-stale-focus
**Scenario**: SKILL.md and PROMPT.md both prevent stale focus return.
**Preconditions**: Both dev-status files exist.
**Expected Result**: Both files contain Focus Inference and downgrade rule.
**Failure Signal**: Divergence between SKILL.md and PROMPT.md.

---

## Telemetry

### TM1 — Telemetry Enabled

**Case ID**: case-45-telemetry-enabled
**Scenario**: Telemetry records events when enabled in config.
**Preconditions**: config.json has enabled=true. telemetry.ps1 exists.
**Expected Result**: JSONL session file created with valid events.
**Failure Signal**: No session file created or invalid JSON.

### TM2 — Telemetry Disabled

**Case ID**: case-46-telemetry-disabled
**Scenario**: Telemetry is completely silent when disabled.
**Preconditions**: config.json has enabled=false.
**Expected Result**: No files created. Exit code 0. No output.
**Failure Signal**: Files created while disabled or non-zero exit.

### TM3 — Replay Completeness

**Case ID**: case-47-replay-completeness
**Scenario**: Single session log contains all 5 event types.
**Preconditions**: Telemetry enabled.
**Expected Result**: command_invoked, command_result, workflow_transition, drift_snapshot, loop_execution all present.
**Failure Signal**: Missing event types or incorrect order.

### TM4 — Multi-Command Workflow Replay

**Case ID**: case-48-multi-command-workflow
**Scenario**: Realistic /dev-status → generate plan → continue loop → /dev-save workflow produces complete event chain.
**Preconditions**: Telemetry enabled.
**Expected Result**: All 14 events in chronological order. Every command_invoked has matching command_result.
**Failure Signal**: Missing events, wrong order, unmatched invocations.

### TM5 — Failure Path Telemetry

**Case ID**: case-49-failure-path-telemetry
**Scenario**: Failure scenarios record status=failure with reason.
**Preconditions**: Telemetry enabled.
**Expected Result**: 3 failure results present, each with status="failure" and non-empty reason.
**Failure Signal**: Silent failures or missing reason fields.

### TM6 — Persistence After Interruption

**Case ID**: case-50-persistence-after-interruption
**Scenario**: Partial workflow (interruption before completion) is replayable.
**Preconditions**: Telemetry enabled.
**Expected Result**: Session file contains partial workflow. Missing command_result detectable as interruption signal.
**Failure Signal**: Session file missing or interruption not detectable.

### TM7 — Context Snapshot Completeness

**Case ID**: case-51-context-snapshot-completeness
**Scenario**: session_context_snapshot contains all required fields.
**Preconditions**: Telemetry enabled.
**Expected Result**: phase, focus, freshness, checkpoint_commit, head_commit, active_work all present and non-empty.
**Failure Signal**: Missing or empty required fields.

---

## Test Infrastructure

### T1 — Test Matrix Synchronization Audit

**Case ID**: case-42-test-matrix-synchronization-audit
**Scenario**: docs/test-matrix.md case IDs match actual test directories.
**Preconditions**: test-matrix.md exists. tests/ directory exists.
**Expected Result**: Every test-matrix case ID maps to an existing tests/case-NN-* directory. No orphaned case IDs.
**Failure Signal**: Case IDs in test-matrix that do not match actual directories.

---

## Test Inventory

| Case | Directory | Status |
|---|---|---|
| case-01 | case-01-basic | PASS |
| case-05 | case-05-first-checkpoint | PASS |
| case-06 | case-06-goal-workflow | PASS |
| case-07 | case-07-dirty-workspace | PASS |
| case-08 | case-08-noop-save | PASS |
| case-09 | case-09-history-rewrite | PASS |
| case-10 | case-10-compact-resume | PASS |
| case-11 | case-11-phase-inference | PASS |
| case-12 | case-12-protocol-commit | PASS |
| case-13 | case-13-mixed-staged-files | PASS |
| case-14 | case-14-phase-inference-precedence | PASS |
| case-15 | case-15-scope-misuse | PASS |
| case-16 | case-16-stale-focus-contamination | PASS |
| case-17 | case-17-checkpoint-freshness | PASS |
| case-18 | case-18-active-work-reconstruction | PASS |
| case-19 | case-19-real-status-stale-focus | PASS |
| case-20 | case-20-checkpoint-freshness-runtime | PASS |
| case-21 | case-21-goal-completion-closes-workflow | PASS |
| case-22 | case-22-dev-save-completion-semantics | PASS |
| case-23 | case-23-no-op-validation-completion | PASS |
| case-24 | case-24-phase-inference-extended | PASS |
| case-25 | case-25-noop-save-extended | PASS |
| case-26 | case-26-focus-migration | PASS |
| case-27 | case-27-simple-scope-auto-execution | PASS |
| case-28 | case-28-complex-scope-requires-goal | PASS |
| case-29 | case-29-ambiguous-scope-clarification | PASS |
| case-30 | case-30-continue-loop-normal | PASS |
| case-31 | case-31-all-loops-completed | PASS |
| case-32 | case-32-ambiguous-next-loop | PASS |
| case-33 | case-33-large-loop-requires-goal | PASS |
| case-34 | case-34-generate-plan-basic | PASS |
| case-35 | case-35-generate-plan-defer-aware | PASS |
| case-36 | case-36-generate-plan-continue-loop-constraints | PASS |
| case-37 | case-37-semantic-validation-equivalence | PASS |
| case-38 | case-38-semantic-loop-completion | PASS |
| case-39 | case-39-semantic-drift-classification | PASS |
| case-40 | case-40-semantic-active-work | PASS |
| case-41 | case-41-canonical-workflow-path-consistency | PASS |
| case-42 | case-42-test-matrix-synchronization-audit | PASS |
| case-43 | case-43-onboarding-documentation-consistency | PASS |
| case-44 | case-44-alias-skill-runtime-consistency | PASS |
| case-45 | case-45-telemetry-enabled | PASS |
| case-46 | case-46-telemetry-disabled | PASS |
| case-47 | case-47-replay-completeness | PASS |
| case-48 | case-48-multi-command-workflow | PASS |
| case-49 | case-49-failure-path-telemetry | PASS |
| case-50 | case-50-persistence-after-interruption | PASS |
| case-51 | case-51-context-snapshot-completeness | PASS |
