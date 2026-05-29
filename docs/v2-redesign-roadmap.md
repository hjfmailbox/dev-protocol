# Protocol Iteration Roadmap

> **Living document**. This is the current execution roadmap, not a historical record.
>
> **Rule**: Before starting any work, verify this roadmap matches reality. If it does not, update it first.

---

## Current Status

**Phase**: v1.0 freeze preparation (active)

**What is frozen**:

* v2 command surface (`/dev-init`, `/dev-scope`, `/dev-save`, `/dev-status`)
* State file format (`workflow-state.yml`, `handoff.md`, `project-rules.md`)
* Protocol commit conventions (`chore(checkpoint):`, `chore(protocol):`, `chore(state):`)
* Drift detection and classification rules
* Runtime-agnostic core architecture

**What is complete**:

* [x] v2 command surface defined and implemented
* [x] v1 commands deprecated with redirect aliases
* [x] State file templates and validation rules
* [x] Runtime directory at `.agents/dev-protocol/`
* [x] Commit convention and failure policy
* [x] Unified onboarding guide with happy path and recovery paths
* [x] External benchmark of 7 workflow systems -- assessment: READY\_TO\_FREEZE\_V2
* [x] Command contracts documented (`docs/command-contracts.md`)
* [x] Phase inference implemented (5-step priority: next-phase-plan \> roadmap \> handoff \> workflow-state \> unknown)
* [x] No-op save support (clean workspace checkpoint commits)
* [x] Protocol commit detection stable (case-12)
* [x] Test matrix expanded to case-12 + case-24/25/26
* [x] All active tests passing: case-05~26 PASS
* [x] Focus inference implemented with git-reality precedence
* [x] Checkpoint freshness model (fresh/stale/outdated)
* [x] Active work reconstruction from recent commits
* [x] Stale focus contamination fix (case-16)
* [x] Test matrix expanded to case-15 + case-16/17/18

**What is complete (Patch Set 2 — Onboarding Hardening)**:

* [x] project-rules.md contradictions resolved (F7)
* [x] Alias skill stale PROMPT.md files cleaned (F6)
* [x] Semantic terminology normalized across SKILL.md and PROMPT.md (D2 residual)
* [x] Test matrix expanded to case-43/44 (onboarding + alias consistency)
* [x] README.md corrected: /goal restored to canonical commands

**What is complete (Freeze Preparation)**:

* [x] v1-freeze-preparation.md created with scope, guarantees, deferred boundary, breaking change policy, release checklist
* [x] All stabilization exit criteria met
* [x] Workflow compression design implemented (auto-execution, continue loop, generate plan)

**What remains active**:

* Real-project validation on external projects
* Post-v1.0 deferred item scheduling

---

## Current Phase: v1.0 Freeze Preparation

Goal: Lock protocol surface for long-term stability.

**Entry criteria** (all met):
- [x] All P0 findings from v1-readiness-recheck.md resolved
- [x] All active tests pass (case-05 through case-44)
- [x] No HIGH severity friction findings remain open
- [x] External validation checklist ready (defined in `docs/v1-freeze-preparation.md`)

**Freeze rules**:
- No new commands
- No state model changes
- No breaking changes to existing skills
- Only bug fixes and documentation updates

---

## Immediate Fixes (Completed in Patch Set 2)

Goal: Close remaining stabilization gaps before real-project validation.

### ~~N1. Project background generation~~

**Status**: Deferred to post-v1.0. Not blocking freeze. See `docs/v1-freeze-preparation.md` §2 (Explicit Non-Goals).

---

### ~~N2. Test coverage completion~~

**Status**: Completed to extent feasible with static validation.
- case-43/44 added and PASS
- Remaining gaps (runtime behavior validation) documented as known limitations in `docs/v1-freeze-preparation.md`

---

### ~~N3. Documentation drift cleanup~~

**Status**: Completed.
- All alias skill PROMPT.md files rewritten as redirect stubs
- project-rules.md false statements removed
- README.md `/goal` classification corrected
- No v1 contradictions remain (case-44 PASS)

---

## Near-term Iteration (Next)

Goal: Reduce friction for iterative development. Design-only unless explicitly scoped.

### ~~X1. `/dev-scope` to `/goal` friction reduction~~

**Status**: IMPLEMENTED

**Deliverable**: `skills/dev-scope/PROMPT.md` and `SKILL.md` updated with auto-execution rules.

**Auto-execution criteria** (ALL must be true):
- File count ≤ 3
- No public API changes
- No cross-module dependencies
- Single-step validation
- No ambiguous language
- Non-architectural change
- Low blast radius

**Behavior**: When criteria are met, `/dev-scope` executes directly. When not met, produces scope document and waits for `/goal`.

**Tests**: case-27 (allowed auto-execution), case-28 (blocked requires /goal), case-29 (ambiguous clarification).

---

### ~~X2. Continue loop execution~~

**Status**: IMPLEMENTED

**Deliverable**: `skills/continue-loop/PROMPT.md` and `SKILL.md` created. Command contract documented in `docs/command-contracts.md`.

**Behavior**:
- Reads `next-phase-plan.md` from `.agents/dev-protocol/`
- Uses tolerant parsing to detect loops (`Loop N`, status markers `[x]`, `pending`, `todo`, etc.)
- Finds first incomplete loop
- Derives scope from plan + handoff + recent commits
- Applies auto-execution criteria (same as `/dev-scope`)
- If criteria met: executes immediately, updates plan status
- If criteria not met: produces scope document, waits for `/goal`

**Stop conditions**: no plan, empty plan, dirty workspace, blockers, drift, ambiguity, all completed, unrecognizable format

**Tests**: case-30 (normal continue), case-31 (all completed), case-32 (ambiguous), case-33 (large requires goal)

---

### ~~X2.5. Goal-to-Plan bootstrap generation~~

**Status**: IMPLEMENTED

**Deliverable**: `skills/generate-plan/PROMPT.md` and `SKILL.md` created. Command contract documented in `docs/command-contracts.md`.

**Behavior**:
- Reads context: workflow-state.yml, handoff.md, roadmap, deferred-improvements, recent git history, goal-output
- Infers current phase, focus, unresolved friction, relevant roadmap/defer items
- Decomposes high-level goal into numbered loops with explicit validation criteria
- Writes `.agents/dev-protocol/next-phase-plan.md` using loop structure compatible with `continue loop`
- Validates generated loops against continue-loop constraints

**Plan requirements**:
- Numbered loops
- Each loop independently executable
- Explicit validation criteria
- Explicit completion signals
- Bounded scope
- Auto-execution-friendly wording

**Canonical workflow**:
```
goal → generate plan → continue loop → /dev-save
```

**Tests**: case-34 (basic workflow), case-35 (defer-aware planning), case-36 (continue-loop constraint satisfaction)

---

### ~~X3. Semantic Validation & Loop Completion~~

**Status**: IMPLEMENTED

**Deliverable**: Semantic validation rules added to `skills/continue-loop/PROMPT.md` and `skills/dev-status/PROMPT.md`.

**Behavior**:
- Semantic equivalence rules for validation criteria interpretation
- Git reality, test outcomes, and commit intent used as confirming evidence
- Semantic drift classification beyond commit counting (documentation-only, stabilization-pattern, roadmap-aligned, source-impacting)
- Active work semantic inference from commit patterns (stabilization themes, audit themes, execution themes)

**Validation equivalence examples**:
- "tests pass" ≈ "all regression cases pass" ≈ "case-34 PASS"
- "README updated" ≈ "documentation synchronized"
- "contracts hardened" ≈ "command contracts documented"

**Drift classification**:
- Protocol-only commits → drift = none
- Documentation-only / test-only → drift = low
- Stabilization-pattern sequence → drift = low
- Source-impacting commits → drift = high
- Roadmap-aligned commits → drift = medium

**Tests**: case-37 (validation equivalence), case-38 (loop completion detection), case-39 (drift classification), case-40 (active-work reconstruction)

---

### ~~X3.5. No-op workflow formalization~~

**Status**: Implemented in `/dev-save`. No-op saves are tested and stable (case-08, case-23, case-25 PASS).

**Remaining work**: Document no-op loop as first-class workflow outcome in planning conventions. Deferred to post-v1.0 documentation update.

---

### ~~X4. Save metadata arguments~~

**Status**: Deferred to post-v1.0. See `deferred-improvements.md` D03.

**Rationale**: Current auto-behavior works. Optional arguments are a UX enhancement, not a correctness requirement.

---

## Deferred / Later

Goal: Long-running robustness. Not scheduled until stabilization and near-term iteration are complete.

### L1. Deterministic replay

Support replaying protocol state transitions deterministically from a clean state. Enables:

* Regression testing of protocol behavior
* Recovery from total state loss
* Verification that state transitions are reproducible

**Blocked by**: Stabilization of state file format and save semantics.

---

### L2. Stale task residue

After successful `/dev-save`, the agent runtime may retain stale internal task context. Target:

* Successful save implies clean task termination
* No stale pending protocol task remains

**Blocked by**: Requires integration with agent runtime task lifecycle (Claude Code-specific).

---

### L3. Constants audit

Periodic validation ensuring no duplicated literals drift into the codebase:

* Thresholds
* Retry intervals
* Timeout values
* Status literals

**Blocked by**: Requires AST parsing or structured grep across skills/ and scripts/.

---

### L4. Protocol checkpoint metadata

Make protocol commits structurally identifiable beyond naming conventions.

**Options**:

* Explicit metadata marker in commit body (`[protocol-checkpoint]`)
* Structured commit annotation (trailers)
* Commit message footer with protocol version

**Blocked by**: Requires consensus on format and backward compatibility with existing commits.

---

## Exit Criteria

**Stabilization phase (p3) — COMPLETE**:

- [x] All v1 references removed from docs and alias skills
- [x] Test matrix explicitly marks all gaps (automated vs manual vs missing)
- [x] No-op workflow tested and stable (case-08, case-23, case-25 PASS)
- [x] `docs/test-matrix.md` and `run-tests.ps1` are in sync (case-42 PASS)

**Near-term iteration phase — COMPLETE**:

- [x] Workflow compression design reviewed and implemented (auto-execution, continue loop, generate plan)
- [x] Semantic validation layer implemented and tested (case-37 through case-40 PASS)
- [x] All near-term items either implemented or explicitly deferred

**v1.0 freeze exit criteria**:

- [ ] `docs/v1-freeze-preparation.md` created and reviewed (this document)
- [ ] Breaking change policy defined
- [ ] Deferred boundary classified (post-v1.0 / reconsider later / remove)
- [ ] External project validation executed on at least one external project
- [ ] No regressions in case-05 through case-44
- [ ] Tag `v1.0-rc1` created

**Post-v1.0 deferred scheduling**:

- State format is stable (no breaking changes for 3+ iterations)
- Deferred items may be scheduled based on external adoption and workflow friction feedback
- Breaking changes require new major version per policy in `docs/v1-freeze-preparation.md`

---

## How to Update This Roadmap

1. **After `/dev-save`**: Review this document. Move completed items to "What is complete".
2. **When reality changes**: Update "Current Status" immediately. Do not let the roadmap drift from reality.
3. **When adding work**: Add to appropriate section. If unsure, add to "Deferred / Later" and discuss.
4. **When removing work**: Do not delete. Move to "What is complete" with `[x]` or mark as `[wontfix]` with reason.

**Source of truth**: This file (`docs/v2-redesign-roadmap.md`).

**Related documents**:

* `.agents/dev-protocol/docs/deferred-improvements.md` -- unresolved improvements with demonstrated workflow value
* `docs/test-matrix.md` -- protocol critical path test scenarios
* `docs/command-contracts.md` -- command contracts and failure modes
* `docs/workflow-compression.md` -- workflow compression design (frozen)
