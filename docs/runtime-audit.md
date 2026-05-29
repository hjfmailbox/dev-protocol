# Runtime Telemetry Audit

> **Date**: 2026-05-29
> **Scope**: Phase 1.5 reliability hardening
> **Auditor**: dev-protocol self-audit

---

## Coverage Matrix

| Command | command_invoked | command_result | drift_snapshot | workflow_transition | loop_execution | session_context_snapshot |
|---|---|---|---|---|---|---|
| `/dev-status` | yes | yes | yes | — | — | yes |
| `/dev-save` | yes | yes | — | — | — | yes |
| `/dev-scope` | yes | yes | — | — | — | yes |
| `/dev-init` | yes | yes | — | — | — | — |
| `generate plan` | yes | yes | — | — | — | yes |
| `continue loop` | yes | yes | — | yes | yes | yes |
| `/goal` | documented | documented | — | — | — | — |

**Legend**: `yes` = recorded in skill file, `—` = not applicable, `documented` = no dedicated skill file but recorded via stop hook / output contract.

---

## Findings

### F1: /dev-scope had no telemetry instructions

- **File**: `skills/dev-scope/SKILL.md`
- **Impact**: HIGH — primary command, frequently used
- **Fix**: Added Telemetry section with `command_invoked` and `command_result` (success + failure)

### F2: /dev-init had no telemetry instructions

- **File**: `skills/dev-init/SKILL.md`
- **Impact**: MEDIUM — onboarding command, infrequent but critical for adoption tracking
- **Fix**: Added Telemetry section with `command_invoked` and `command_result` (success + failure)

### F3: /goal has no dedicated SKILL.md

- **File**: No dedicated skill file (handled by goal system)
- **Impact**: HIGH — the most frequent command
- **Fix**: Documented expectation. `/goal` telemetry is captured via:
  - `command_invoked` at goal start (by stop hook directive)
  - `command_result` at goal completion (by stop hook condition evaluation)
  - `goal-output.json` as sidecar artifact

### F4: Failure paths were not recorded

- **File**: All skill files
- **Impact**: HIGH — silent failures lose friction data
- **Observed**: All Telemetry sections only documented `-Status 'success'`
- **Fix**: Added failure telemetry instructions to all FAILURE CONDITIONS / Failure Rules sections:
  - `/dev-status` — state missing, repo corrupted, severe inconsistency
  - `/dev-save` — state missing, validation failure, recoverability failure, corruption
  - `/dev-scope` — empty intent, ambiguous scope, missing validation
  - `continue loop` — no plan, dirty workspace, blockers, drift, ambiguity
  - `generate plan` — missing context, ambiguous goal, zero loops
  - `/dev-init` — repo unreadable, low confidence, overwrite demand

### F5: No session context snapshot

- **Impact**: MEDIUM — replay requires re-inferring state from sparse events
- **Fix**: Added `session_context_snapshot` event type to `telemetry.ps1` and recorded after:
  - `/dev-status`
  - `/dev-save`
  - `generate plan`
  - `continue loop`
  - `/dev-scope`

### F6: Stop hook interruption causes missing command_result

- **Impact**: LOW — architecture limitation, unavoidable
- **Assessment**: If a stop hook fires mid-execution, `command_result` is never reached. This is acceptable because `command_invoked` was already recorded, and the absence of `command_result` itself signals an interruption.

---

## Fixes Applied

1. Added Telemetry sections to `/dev-scope` and `/dev-init` skill files.
2. Added failure-path telemetry to all skill files' FAILURE CONDITIONS sections.
3. Added `session_context_snapshot` event type to `telemetry.ps1`.
4. Added context snapshot recording instructions to `/dev-status`, `/dev-save`, `generate plan`, `continue loop`, `/dev-scope`.
5. Documented `/goal` telemetry expectation in this audit doc.
6. Added case-48~51 reliability tests covering multi-command workflow, failure path, persistence, and snapshot completeness.

---

## Remaining Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Stop hook interrupts before `command_result` | LOW | `command_invoked` + missing `command_result` = implicit failure signal |
| `/goal` telemetry depends on agent discipline (no dedicated skill file) | MEDIUM | Documented in audit; monitored via case-48/49 |
| Session file grows unbounded within a single day | LOW | Hourly session rollover limits individual file size |
| Telemetry write failure silently ignored | LOW | `ErrorActionPreference = 'Stop'` in telemetry.ps1; skill instructions say "skip silently if disabled" |
| Long-term storage growth (no retention cap) | LOW | Permanent retention by design during dogfood; archival may be introduced post-v1.x |
