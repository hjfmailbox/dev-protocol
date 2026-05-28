# Case 14 — Status Phase Inference Precedence

## Purpose

Verify that `/dev-status` follows the correct priority order when multiple phase sources conflict.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- `workflow-state.yml` contains `phase: unknown`
- `handoff.md` contains a Current Focus that implies a phase
- `docs/v2-redesign-roadmap.md` contains an explicit phase label
- Git reality (branch, recent commits) suggests a different phase

## Steps

1. Set `workflow-state.yml` phase to `unknown`
2. Ensure `handoff.md` Current Focus contains phase-indicator language (e.g., "stabilization")
3. Ensure roadmap contains a different explicit phase label (e.g., "ergonomics")
4. Ensure git reality (branch name or recent commits) suggests yet another phase
5. Run `/dev-status`
6. Inspect output for inferred phase and source

## Expected Results

- `/dev-status` resolves conflict using precedence:
  1. git reality wins first
  2. workflow-state (if not unknown and checkpoint current)
  3. current-focus (handoff.md)
  4. roadmap
  5. fallback unknown
- Output explicitly states: `phase: <X> (inferred from <source>)`
- Source of inference is transparent and correct per precedence rules

## Failure Criteria

- Lower-priority source overrides higher-priority source (e.g., roadmap beats git reality)
- Phase remains `unknown` when git reality or workflow-state provides clear signal
- No inference source is stated
- Precedence order does not match contract
