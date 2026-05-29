# Case-52: Long-Session Accumulation

## Scenario

A single working session spans many commands (20+) without session rollover. Telemetry must accumulate all events in the same JSONL file without loss, corruption, or truncation.

## Preconditions

- Telemetry enabled.
- telemetry.ps1 exists and is functional.
- Session rollover is based on 1-hour LastWriteTime cutoff.

## Steps

1. Generate 25+ telemetry events rapidly (within the same hour window).
2. Verify all events land in a single JSONL file.
3. Verify every line is valid JSON.
4. Verify event count matches recorded count.

## Expected Result

- Single session file contains all 25+ events.
- No JSON parse errors.
- No event loss.
- File size is reasonable (< 50 KB for metadata-only events).

## Failure Signal

- Events split across multiple files within the same session.
- JSON parse errors.
- Missing events.
