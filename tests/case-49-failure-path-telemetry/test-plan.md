# Case 49 — Failure Path Telemetry

## Objective

Verify that failure scenarios are recorded with `status=failure`.

## Preconditions

- Telemetry is enabled
- `.agents/dev-protocol/runtime-telemetry/telemetry.ps1` exists

## Steps

1. Record a sequence of events including failures:
   - `command_invoked` for `continue loop`
   - `command_result` for `continue loop` with status=failure, reason="no_plan"
   - `command_invoked` for `/dev-save`
   - `command_result` for `/dev-save` with status=failure, reason="missing_state"
   - `command_invoked` for `generate plan`
   - `command_result` for `generate plan` with status=failure, reason="ambiguous_goal"
2. Read the generated JSONL file
3. Verify all 3 failure events are present
4. Verify each failure has `status="failure"` and a `reason` field

## Expected Result

- 3 `command_result` events with `status="failure"`
- Each failure has a non-empty `reason`
- No silent failures (all recorded)
