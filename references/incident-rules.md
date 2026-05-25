# Incident Logging Rules

Lightweight runtime incident tracking for dev-protocol.

---

## Purpose

Record protocol anomalies as they are detected during normal command execution.

No telemetry. No daemon. No background monitoring.

**Detect and record only. No auto-fix.**

---

## Incident File

Location: `.agents/dev-protocol/incidents.md`

Created on first incident. Does not exist by default.

Format:

```markdown
# Incidents

Runtime protocol anomalies detected during command execution.

---

## <YYYY-MM-DD> <command> — <incident-type>

**Context**: <brief description of what was happening>
**Detection**: <how the anomaly was detected>
**Severity**: low | medium | high
**Status**: open | resolved | acknowledged
```

---

## Incident Types

| Type | Trigger | Typical Severity |
|------|---------|-----------------|
| `resume-drift` | `/dev-status` detects state-reality mismatch | medium |
| `checkpoint-mismatch` | `/dev-save` finds state inconsistency | high |
| `artifact-emission-failure` | Goal output artifact not written to disk | high |
| `missing-state-file` | Required state file absent | high |
| `empty-state-file` | State file exists but is empty | medium |
| `checkpoint-stale` | `last_commit` points to rebased/missing commit | medium |
| `phase-drift` | Resumed phase does not match actual progress | medium |
| `protocol-inconsistency` | State files contradict each other | medium |
| `duplicate-state` | State files found in multiple locations | low |
| `dirty-checkpoint` | Checkpoint attempted on dirty workspace | low |

---

## When to Log

Incidents are logged by commands that detect anomalies:

- `/dev-status` — logs drift, missing files, phase mismatch
- `/dev-save` — logs state inconsistency, validation failures
- `/dev-doctor` — logs all detected issues during diagnosis

Incidents are NOT logged for:

- Normal operations (no anomaly)
- User-initiated actions that are expected to fail
- First-time bootstrap (no prior state to drift from)

---

## Logging Rules

1. **Append-only**: never modify or delete existing incidents
2. **Timestamped**: every incident includes date and triggering command
3. **Contextual**: include enough detail to understand without re-running
4. **No auto-fix**: log the finding, recommend manual resolution
5. **Bounded**: if incidents.md exceeds 200 lines, summarize older entries

---

## Integration Points

### /dev-status

When drift detection finds mismatch:

- If drift severity is WARNING or ERROR → log incident
- Type: `resume-drift` or `phase-drift`

When loading state finds missing files:

- If state files missing → log incident
- Type: `missing-state-file`

### /dev-save

When validation finds mismatch:

- If validation fails → log incident
- Type: `checkpoint-mismatch`

When checking `last_commit` detects stale baseline:

- If commit no longer exists → log incident
- Type: `checkpoint-stale`

### /dev-doctor

When any check returns WARNING or ERROR:

- Log incident with the check name as type

---

## Resolution

Incidents are resolved manually:

- `open` → issue detected, not yet addressed
- `acknowledged` → user aware, deferred
- `resolved` → fix applied (describe in a follow-up entry, not by editing)

To resolve: append a new entry referencing the original incident.

---

## Example

```markdown
# Incidents

Runtime protocol anomalies detected during command execution.

---

## 2026-05-24 /dev-status — resume-drift

**Context**: Resume detected checkpoint.last_commit pointing to 078f305 but HEAD at 47e3d7e
**Detection**: git diff between last_commit and HEAD showed 1 intermediate commit
**Severity**: low
**Status**: acknowledged

---

## 2026-05-24 /dev-save — checkpoint-stale

**Context**: After rebase, last_commit pointed to commit no longer in history
**Detection**: git cat-file -t <last_commit> returned fatal error
**Severity**: high
**Status**: open
```
