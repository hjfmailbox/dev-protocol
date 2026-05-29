# Case 47 — Command Replay Completeness

## Objective

Verify that a single session log contains enough information to reconstruct the session.

## Preconditions

- Telemetry is enabled
- `.agents/dev-protocol/runtime-telemetry/telemetry.ps1` exists

## Steps

1. Record a sequence of events representing a full workflow:
   - `command_invoked` for `/goal`
   - `workflow_transition` from `/goal` to `generate plan`
   - `command_invoked` for `generate plan`
   - `command_result` for `generate plan`
   - `workflow_transition` from `generate plan` to `continue loop`
   - `command_invoked` for `continue loop`
   - `loop_execution` for loop-1
   - `command_result` for `continue loop`
   - `command_invoked` for `/dev-save`
   - `command_result` for `/dev-save`
   - `drift_snapshot` with drift=none
2. Read the generated JSONL file
3. Verify all event types are present
4. Verify commands appear in chronological order
5. Verify workflow transitions form a connected chain

## Expected Result

- All 5 event types appear in the session log
- Command order is reconstructible
- Workflow transitions show a clear path
- Drift state is captured
- Loop execution is recorded
