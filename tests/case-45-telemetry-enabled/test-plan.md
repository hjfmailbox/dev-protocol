# Case 45 — Telemetry Enabled

## Objective

Verify that telemetry captures events when enabled.

## Preconditions

- `.agents/dev-protocol/runtime-telemetry/config.json` exists with `enabled: true`
- `.agents/dev-protocol/runtime-telemetry/telemetry.ps1` exists

## Steps

1. Verify telemetry directory structure exists
2. Run `telemetry.ps1 -EventType command_invoked -Command '/dev-status'`
3. Verify a JSONL session file was created under `sessions/YYYY-MM-DD/`
4. Verify the JSONL contains the recorded event with correct fields

## Expected Result

- Session JSONL file exists
- File contains valid JSON lines
- Event has `timestamp`, `event_type`, `command`, `project`, `repo_root`
- No errors emitted
