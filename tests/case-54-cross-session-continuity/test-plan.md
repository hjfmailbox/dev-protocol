# Case-54: Cross-Session Continuity

## Scenario

Multiple sessions occur within the same day (e.g., morning session, afternoon session after lunch break). Each session gets its own JSONL file. A replay tool must be able to order these sessions chronologically and reconstruct the full day's activity.

## Preconditions

- Telemetry enabled.
- Session rollover creates new files after 1 hour of inactivity.

## Steps

1. Record telemetry events in "Session A".
2. Wait for the 1-hour rollover window to pass (simulate by using explicit SessionFile paths with different timestamps).
3. Record telemetry events in "Session B".
4. Verify both session files exist.
5. Verify chronological ordering by filename or internal timestamp.
6. Verify that a multi-session replay can concatenate events in order.

## Expected Result

- Two distinct session files exist.
- File naming includes timestamp, allowing lexicographic sorting.
- Concatenated replay produces chronologically ordered event stream.
- No events are lost between sessions.

## Failure Signal

- Sessions overwrite each other.
- Filenames are not sortable.
- Timestamps within files are not monotonic.
