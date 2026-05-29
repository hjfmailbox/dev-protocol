# Runtime Telemetry

Passive runtime telemetry capture for dev-protocol.

## Purpose

Record what happens during dev-protocol usage so sessions can be replayed, debugged, and analyzed later.

**Current phase: capture only. No analysis.**

## What Is Recorded

Each session produces a JSONL file with timestamped events:

| Event Type | Trigger | Content |
|---|---|---|
| `command_invoked` | `/dev-status`, `/dev-save`, `/dev-scope`, `/goal`, `continue loop`, `generate plan` | Command name, args, project, branch, workspace state |
| `command_result` | After command completes | Success/failure, duration, reason |
| `workflow_transition` | Moving between workflow steps | From step, to step |
| `drift_snapshot` | After `/dev-status` | Drift level, phase, focus, checkpoint age |
| `loop_execution` | `continue loop` completes | Loop ID, auto-executed flag, scope |

## Storage Layout

```text
runtime-telemetry/
├── sessions/
│   └── YYYY-MM-DD/
│       └── <session-id>.jsonl
├── config.json
└── README.md
```

Session ID format: `YYYY-MM-DDTHH-MM-SS_<random-4>`

## Privacy Boundary

- No source code content is recorded
- No file diffs are recorded
- No user messages or chat history is recorded
- Only command names, project metadata, and workflow state

## How to Disable

Edit `config.json`:

```json
{
  "enabled": false
}
```

When disabled, telemetry is completely silent. No files are written. No errors are emitted.

## Retention

**Telemetry currently uses permanent retention during dogfood phase.**

All session files are kept indefinitely. No automatic deletion occurs.

Later observability or storage optimization may introduce an archival strategy, but v1.x does not allow automatic deletion of telemetry data.

## Replay Usage

```bash
# View all commands in a session
cat runtime-telemetry/sessions/2026-05-29/2026-05-29T18-21-33_ab12.jsonl | jq 'select(.event_type == "command_invoked")'

# View workflow transitions
cat session.jsonl | jq 'select(.event_type == "workflow_transition")'

# View drift snapshots
cat session.jsonl | jq 'select(.event_type == "drift_snapshot")'
```

## Future Use

This data supports:

- **Debug**: Reconstruct what happened in a failed session
- **Replay**: Understand command sequences that led to specific outcomes
- **Friction analysis** (Phase 2): Identify where users get stuck or retry
