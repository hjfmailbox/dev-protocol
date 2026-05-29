# Case 50 — Telemetry Persistence After Workflow Interruption

## Objective

Verify that telemetry survives partial workflow and can be replayed after restart.

## Preconditions

- Telemetry is enabled
- `.agents/dev-protocol/runtime-telemetry/telemetry.ps1` exists

## Steps

1. Record a partial workflow (simulate interruption before completion):
   - `command_invoked` for `/dev-status`
   - `command_result` for `/dev-status` (success)
   - `command_invoked` for `generate plan`
   - (no command_result — simulate interruption)
2. Read the session file
3. Verify the partial workflow is replayable
4. Verify missing `command_result` is detectable (implicit interruption signal)

## Expected Result

- Session file contains the partial workflow
- `command_invoked` for `generate plan` exists without matching `command_result`
- Replay logic can detect the interruption gap
