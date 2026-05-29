# Case 48 — Multi-Command Workflow Replay Completeness

## Objective

Verify that a realistic multi-command workflow produces a complete, replayable event chain.

## Preconditions

- Telemetry is enabled
- `.agents/dev-protocol/runtime-telemetry/telemetry.ps1` exists

## Steps

1. Simulate a realistic workflow by recording these events in order:
   - `command_invoked` for `/dev-status`
   - `drift_snapshot` with drift=low
   - `command_result` for `/dev-status` (success)
   - `session_context_snapshot`
   - `command_invoked` for `generate plan`
   - `command_result` for `generate plan` (success)
   - `session_context_snapshot`
   - `command_invoked` for `continue loop`
   - `loop_execution` for loop-1
   - `command_result` for `continue loop` (success)
   - `session_context_snapshot`
   - `command_invoked` for `/dev-save`
   - `command_result` for `/dev-save` (success)
   - `session_context_snapshot`
2. Read the generated JSONL file
3. Verify all events are present in chronological order
4. Verify no events are missing from the chain

## Expected Result

- All 14 events recorded in a single session file
- Events appear in chronological order
- No gaps in the workflow chain
- `command_invoked` always followed by `command_result` (or `drift_snapshot` for /dev-status)
