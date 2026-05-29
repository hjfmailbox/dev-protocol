# Protocol Iteration Roadmap

> **Living document**. This is the current execution roadmap, not a historical record.
>
> **Rule**: Before starting any work, verify this roadmap matches reality. If it does not, update it first.

---

## Current Status

**Phase**: p3 -- Stabilization (active)

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

**What remains active**:

* Stabilization of edge cases and documentation drift
* Onboarding hardening for real-project validation
* Workflow compression design (not yet implemented)

---

## Immediate Fixes (Now)

Goal: Close remaining stabilization gaps before real-project validation.

### N1. Project background generation

**Problem**: When an agent first opens a repository, reconstructing project reality requires reading many files across the codebase. There is no single document that captures the essential project context for fast agent onboarding.

**Target**: Add a `dev-*` workflow or script that generates a project background document.

**Contents**:

* Project structure and directory layout
* Technology stack and dependencies
* Runtime architecture
* Conventions (naming, organization, patterns)
* Important folders and their roles
* Key workflows (build, test, deploy)

**Explicitly not**:

* Not a requirements document
* Not a design spec
* Not a task list

**Deliverable**: `PROJECT_BACKGROUND.md` generator or template, integrated into `/dev-init` or as a standalone `/dev-background` command.

**Source**: `C` in goal directive.

---

### N2. Test coverage completion

**Problem**: The test matrix has expanded to case-12, but some scenarios remain without automated validation. run-tests.ps1 still validates static files and prompt keywords, not runtime behavior.

**Remaining gaps**:

| Gap | Status | Case |
|---|---|---|
| Slash command edge cases | Partial | case-07 (dirty workspace) validated via prompt keywords only |
| Dirty workspace onboarding | Missing | No automated test for `/dev-init` on dirty workspace |
| History rewrite recovery | Partial | case-09 validated via prompt keywords only |
| Protocol replay | Missing | No test for deterministic state reconstruction |
| `/dev-init` full onboarding | Missing | No validation of YAML generation, phase default, empty last\_commit |
| `/dev-scope` ambiguity detection | Missing | No validation of fuzzy input handling |

**Target**: Close gaps by either:

1. Adding automated static validation where possible (prompt keyword checks, file structure checks)
2. Documenting manual validation steps where automated testing is not feasible
3. Marking gaps as "requires manual verification" in test matrix

**Deliverable**: Updated `docs/test-matrix.md` with explicit PASS/MANUAL/SKIP status per scenario.

**Source**: `D` in goal directive.

---

### N3. Documentation drift cleanup

**Problem**: v1-era references remain in multiple documents, causing confusion for new contributors and agents.

**Known drift items**:

* [ ] `PROJECT_BACKGROUND.md` -- references `/dev-bootstrap`, `/dev-checkpoint`, `/dev-resume`
* [ ] `references/workflow-rules.md` -- example workflow uses v1 commands
* [ ] `skills/dev-checkpoint/PROMPT.md` -- claims "NEVER stage files, NEVER auto-commit" (contradicts v2 `/dev-save`)
* [ ] `skills/dev-resume/PROMPT.md` -- uses old drift terms "none/minor/major"
* [ ] `skills/dev-bootstrap/PROMPT.md` -- references legacy `.agent/` path
* [ ] `skills/dev-help/PROMPT.md` -- displays v1 command table
* [ ] `skills/dev-doctor/PROMPT.md` -- may reference v1 diagnostics

**Target**: Audit and update all v1 alias skills to consistent redirect semantics. Update all example workflows in docs to use v2 commands.

**Deliverable**: Clean v1 references across `skills/*/` and `docs/`.

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
- Writes `docs/next-phase-plan.md` using loop structure compatible with `continue loop`
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

### X3.5. No-op workflow formalization

**Status**: Already implemented in `/dev-save`. Clean workspace produces valid checkpoint commit.

**Remaining work**: Document no-op loop as a first-class workflow outcome in planning conventions.

**Deliverable**: Update `references/workflow-rules.md` or `docs/command-contracts.md` to explicitly list no-op/verification loop as valid workflow pattern.

---

### X4. Save metadata arguments

**Problem**: `/dev-save` infers checkpoint summary and save reason heuristically. User cannot provide explicit context.

**Target**: Support optional arguments such as:

```text
/dev-save "loop 5 undo implementation"
/dev-save --summary="loop 5"
```

**Rules**:

* Fully backward compatible
* No required arguments
* Preserve current auto behavior as default

**Deliverable**: Design doc or prototype. Implementation optional for this phase.

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

**Stabilization phase (p3) is complete when**:

- [ ] All v1 references removed from docs and alias skills
- [ ] Test matrix explicitly marks all gaps (automated vs manual vs missing)
- [ ] Project background generation workflow defined
- [ ] No-op workflow documented as first-class outcome
- [ ] Real-project validation checklist executed on at least one external project
- [ ] `docs/test-matrix.md` and `run-tests.ps1` are in sync (no orphaned cases, no missing mappings)

**Near-term iteration phase begins when**:

- Stabilization exit criteria met
- External validation confirms no critical workflow friction
- Design docs for workflow compression reviewed

**Deferred items enter schedule when**:

- Near-term iteration complete
- State format declared stable (no breaking changes for 3+ iterations)
- External adoption justifies investment in robustness features

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
