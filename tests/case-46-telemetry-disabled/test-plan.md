# Case 46 — Telemetry Disabled

## Objective

Verify that telemetry is completely silent when disabled.

## Preconditions

- `.agents/dev-protocol/runtime-telemetry/config.json` exists

## Steps

1. Set `enabled: false` in config.json
2. Run `telemetry.ps1 -EventType command_invoked -Command '/dev-status'`
3. Verify no new session files are created
4. Verify script exits with code 0 and no output
5. Restore `enabled: true` (or leave as-is for test isolation)

## Expected Result

- No JSONL files created
- Script exits silently with code 0
- No stderr output
