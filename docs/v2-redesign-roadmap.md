# Stabilization Roadmap

Post-v2 roadmap after feature freeze.

Direction switched from **feature delivery** to **stability + ergonomics + protocol robustness**.

---

## Phase A — Stabilization

Goal: Harden onboarding, fix state reconciliation, document command contracts.

### A1. Command contract documentation

Document the exact contract for each v2 command:

- `/dev-init` — what it does, what it does not do, what it outputs
- `/dev-scope` — scope format, validation criteria, ambiguity rules
- `/dev-save` — staging rules, commit format, auto-commit behavior
- `/dev-status` — read-only guarantee, drift classification, reconstruction rules

Source of truth: `skills/*/SKILL.md` and `skills/*/PROMPT.md`.

Deliverable: `docs/command-contracts.md`

### A2. Project onboarding hardening

From deferred D08 (protocol documentation split):

- Clarify ownership boundaries between `docs/` and `.agents/dev-protocol/docs/`
- Define authoritative runtime docs vs public documentation
- Document synchronization rules

From deferred D04 (/dev-status phase recovery):

- `/dev-status` should infer reasonable working phase automatically
- Weighted inference from: protocol state, recent commits, checkpoint summary
- Reduce `phase: unknown` frequency

From real-project validation friction:

- `/dev-init` warns if `.agents/` matches `.gitignore`
- `/dev-init` on dirty workspace requires explicit confirmation
- `/dev-init` does not overwrite existing state without reason

### A3. State simplification

From deferred D08:

- Two documentation locations exist: `docs/` and `.agents/dev-protocol/docs/`
- Ambiguity about source of truth

Action:

- Define `docs/` = public, user-facing documentation
- Define `.agents/dev-protocol/docs/` = runtime protocol and agent-facing documentation
- Document this separation in README and onboarding

See `docs/state-file-review.md` for full analysis.

### A4. Save/status guard fixes

From deferred D04:

- `/dev-status` phase recovery remains weak
- Infer active phase using weighted signals instead of defaulting to `unknown`

From deferred D09:

- Checkpoint commits rely on naming conventions (`chore(protocol):`, `chore(checkpoint):`)
- Make protocol commits structurally identifiable
- Consider explicit metadata marker (`[protocol-checkpoint]`)

From deferred D05:

- `/dev-save` should fully close workflow task state
- Successful save implies task closure semantics
- No stale pending protocol task remains

---

## Phase B — Ergonomics

Goal: Reduce workflow friction, support planned execution, handle edge cases.

### B1. Reduce `/dev-scope` → `/goal` duplication

From deferred D01:

- Simple scoped work requires both `/dev-scope` and `/goal`
- Introduce lightweight execution mode: `/dev-scope --execute` or implicit auto-execution
- Keep explicit `/goal` for: multi-step planning, repo-wide changes, ambiguous work

### B2. Continue loop

From deferred D02:

- Planned execution requires repeated manual orchestration
- Add plan-aware continuation mode
- Sources: `next-phase-plan.md`, `current-focus.md`, recent completed loops
- Automatically detect next planned loop, derive scope, execute workflow

### B3. No-op validation support

From deferred D07:

- Some loops conclude with `behavior already correct` (no implementation required)
- Current workflow assumes every loop produces code/docs changes
- Planning workflow should explicitly recognize: validation loop, verification loop, no-op success

From deferred D03:

- `/dev-save` optional arguments for explicit context
- Support: `/dev-save "loop 5 undo implementation"`, `/dev-save --summary="loop 5"`
- Fully backward compatible, no required arguments

---

## Phase C — Long-running robustness

Goal: Support deterministic replay, eliminate stale state, prevent drift.

### C1. Deterministic replay

From deferred D06 (constants coverage audit):

- Duplicated literals may gradually reappear after implementation loops
- Examples: thresholds, retry intervals, timeout values, status literals
- Add periodic audit command or validation: `/dev-audit-constants`
- Ensure no duplicated thresholds, no repeated timeout literals, no status string drift

### C2. Stale task residue

From deferred D05:

- After successful `/dev-save`, Claude Code may retain stale internal tasks
- Successful save should imply: checkpoint complete, protocol task resolved
- Improve completion behavior so protocol save cleanly terminates workflow context

### C3. Save guard improvements

From deferred D03:

- `/dev-save` optional arguments for explicit metadata control
- User can provide checkpoint summary, save reason, commit context explicitly
- Preserve current auto behavior as default

---

## Exit Criteria

Phase A is complete when:

- All command contracts documented
- Onboarding hardened with dirty-workspace and gitignore detection
- State file boundaries clarified
- `/dev-status` phase recovery improved

Phase B is complete when:

- `/dev-scope --execute` or equivalent reduces scope-to-goal friction
- Plan-aware continuation mode implemented
- No-op goals handled without false failures
- Optional `/dev-save` arguments supported

Phase C is complete when:

- Constants audit command exists
- Stale task residue eliminated
- Protocol commits structurally identifiable

---

## Deferred Items Not in Scope

These remain in `.agents/dev-protocol/docs/deferred-improvements.md` and are not assigned to any phase:

- D06: Constants coverage audit (assigned to Phase C)
- D08: Protocol documentation split (assigned to Phase A)
- D09: Workflow checkpoint semantics (assigned to Phase A)
