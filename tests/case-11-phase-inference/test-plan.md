# Case 11 — Phase Inference

## Purpose

Verify that `/dev-status` infers phase from available context instead of defaulting to `unknown`.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- `workflow-state.yml` contains `phase: unknown`
- `docs/v2-redesign-roadmap.md` exists with explicit phase (e.g., "Phase A — Stabilization")

## Steps

1. Set `workflow-state.yml` phase to `unknown`
2. Ensure `docs/v2-redesign-roadmap.md` contains phase indicator
3. Run `/dev-status`
4. Inspect output

## Expected Results

- `/dev-status` output contains inferred phase (e.g., `stabilization`)
- Source of inference is noted (e.g., "inferred from roadmap")
- Not `unknown`
- Not blank

## Failure Criteria

- Output shows `phase: unknown` when roadmap contains explicit phase
- Output shows `phase: unknown` when handoff contains phase-indicator language
- No inference note present
