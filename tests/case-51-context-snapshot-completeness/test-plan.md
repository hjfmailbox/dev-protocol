# Case 51 — Context Snapshot Completeness

## Objective

Verify that `session_context_snapshot` contains all required fields.

## Preconditions

- Telemetry is enabled
- `.agents/dev-protocol/runtime-telemetry/telemetry.ps1` exists

## Steps

1. Record a `session_context_snapshot` with all fields populated:
   - phase, focus, drift, freshness
   - checkpoint_commit, head_commit
   - active_work
2. Read the generated JSONL file
3. Verify all expected fields are present

## Expected Result

- Event type is `session_context_snapshot`
- All of these fields are present and non-empty:
  - `phase`
  - `focus`
  - `freshness`
  - `checkpoint_commit`
  - `head_commit`
  - `active_work`
- Optional fields (`drift`) may be present depending on context
