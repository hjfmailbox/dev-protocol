# Case-53: Interrupted Workflow Reconstruction

## Scenario

A workflow is interrupted mid-command (e.g., agent crash, session reset). The telemetry session contains `command_invoked` but no matching `command_result`. A replay tool must be able to detect the interruption and reconstruct what was in progress.

## Preconditions

- Telemetry enabled.
- telemetry.ps1 exists.

## Steps

1. Record a partial workflow:
   - `/dev-status` invoked + result (complete)
   - `generate plan` invoked (interruption — no result)
2. Parse the session log.
3. Identify the interruption gap.
4. Verify the last known context snapshot still provides usable state.

## Expected Result

- Interruption is detectable: `generate plan` has `command_invoked` but no `command_result`.
- Last `session_context_snapshot` before the interruption contains phase, focus, and active_work.
- Reconstruction can determine: which command was interrupted, what the context was.

## Failure Signal

- Interruption not detectable (orphan `command_invoked` not identifiable).
- Missing context snapshot before interruption point.
- Corrupted or unreadable session file.
