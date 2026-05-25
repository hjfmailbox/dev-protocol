# v2 Redesign Roadmap

Post-v1 redesign after real-project validation (DesignDocMCP) and self-dogfooding.

---

## 1. Problem Statement

### 1.1 v1 Friction Discovered During DesignDocMCP Onboarding

The following problems were observed during the first real-project adoption. Each maps to a deferred improvement item where applicable.

**State Reconciliation Failures**

- **Phase drift on resume** (deferred #14): After checkpoint/resume cycles, `/dev-resume` restored phase `p1 — protocol-definition-and-bootstrap` despite the project having already completed bootstrap, checkpoint, resume, real-project validation, runtime migration, README onboarding, and protocol hardening. The persisted `workflow-state.yml` phase was not updated during checkpoint, or resume over-relied on stale persisted metadata instead of recomputing project maturity from git history and state file content.
- **Repository status freshness drift** (deferred #15): `/dev-resume` reported `workspace clean (1 modified file: deferred-improvements.md)` after a successful `/dev-checkpoint` where the workspace was already clean. Resume used stale handoff metadata instead of fully recomputing current repository state from `git status`.
- **Checkpoint baseline confusion** (deferred #13): During real-project validation, `/dev-checkpoint` occasionally reused the previous goal commit message instead of creating a distinct checkpoint-style commit. This caused case-05 to fail with `HEAD commit does not indicate a checkpoint baseline`. The distinction between "a commit that records checkpoint state" and "the baseline commit that checkpoint points to" was not consistently enforced in the skill implementation.

**Validation and Contract Ambiguity**

- **case-05 / case-06 execution order unclear** (deferred #12): The expected validation sequence was ambiguous. `case-06` validates a completed `/goal` commit and its associated goal-output artifact, but after `/dev-checkpoint` HEAD changes to a checkpoint commit, causing `case-06` to fail due to changed_files mismatch. `case-05` validates `/dev-checkpoint` behavior and must run after checkpoint. The correct order (`/goal → case-06 → /dev-checkpoint → case-05`) was not explicitly documented in skill prompts or workflow rules.
- **Continuation handoff prompt weakness** (deferred #6): Cold-start recovery worked only after explicitly forbidding repository scanning and prior assumptions. The original continuation prompt in goal-output was too weak and allowed the agent to expand scope, recovering global repo context instead of the current development phase.
- **NO_OP goal false FAILs** (deferred #7): A goal that completes without changing any files (e.g., "add documentation that already exists") does not produce `goal-output.json` or `goal-output.md`. Case-06 fails on artifact absence even though the goal completed legitimately.

**Onboarding and Documentation Gaps**

- **No formal real-project validation checklist** (deferred #11): The validation sequence exists only in chat history. A reusable checklist for onboarding new projects is missing.
- **`.agents` directory convention undocumented** (deferred #10): The rationale for `.agents/` vs `.agent/` and the relationship with `.claude/skills/` is not explicitly documented, causing confusion during first-time setup.
- **Windows artifact emission unreliable** (deferred #8): Bash heredoc syntax (`cat > file << 'EOF'`) silently failed to create files on Windows agent shell. PowerShell-native file creation succeeded. This caused goal-output artifacts to be reported as created but not actually written.

**Structural Debt**

- **10-file scope threshold has no empirical basis** (deferred #3): The case-06 threshold (`HEAD changed <= 50 files`, down from an earlier 10-file limit) was chosen without data on typical goal commit sizes in real usage.
- **Redundant git diff checks in case-06** (deferred #5): Section E of `run-tests.ps1` re-asserts `git diff --quiet` and `git diff --cached --quiet` already checked in section A.
- **Test numbering gaps** (deferred #9): Only `case-05` and `case-06` exist; `case-01` through `case-04` are missing or were removed, creating numbering ambiguity.

### 1.2 Protocol Problems vs Runtime/Tooling Problems

| Problem | Category | Justification |
|---|---|---|
| Phase drift on resume | **Protocol** | State reconciliation logic in checkpoint/resume skills must compute phase from git + file reality, not persist stale values |
| Repository status freshness drift | **Protocol** | Resume must run `git status` at invocation time, not rely on cached metadata |
| Checkpoint baseline confusion | **Protocol** | Checkpoint skill must distinguish goal commits from checkpoint commits and enforce message contracts |
| case-05 / case-06 order ambiguity | **Protocol** | Validation sequence must be documented in workflow rules and skill prompts |
| Continuation handoff weakness | **Protocol** | Goal-output contract must harden prompt seed to prevent scope expansion |
| NO_OP goal false FAILs | **Protocol** | Case-06 must distinguish "no artifact because no changes" from "missing artifact" |
| Real-project checklist missing | **Protocol** | Reusable onboarding artifact belongs in protocol core |
| `.agents` convention undocumented | **Protocol** | Directory rationale is core architecture documentation |
| Windows bash heredoc failure | **Runtime/Tooling** | Agent shell behavior varies by OS; protocol should prefer cross-platform file creation |
| 10-file / 50-file threshold | **Protocol** | Heuristic needs empirical calibration from real project data |
| Redundant git diff checks | **Protocol** | Test script maintainability issue |
| Test numbering gaps | **Protocol** | Test suite organization issue |

---

## 2. User Journey Model

### 2.1 First-Time Project Onboarding

**User intent**: A developer has an existing repository and wants to start using dev-protocol for AI-assisted development.

**Expected behavior**:

1. Developer reads `docs/onboarding.md` (5 minutes)
2. Developer runs `/dev-init` (or manual equivalent) in the project root
3. Protocol inspects git history, directory structure, existing docs
4. Protocol creates `.agents/dev-protocol/` with `workflow-state.yml`, `handoff.md`, `project-rules.md`
5. Developer reviews generated state files for accuracy
6. Developer commits `.agents/` with `chore(protocol): initialize dev-protocol`
7. Developer runs `/dev-save` to establish first checkpoint baseline
8. Developer runs `/dev-status` to verify recoverability

**Failure risks**:

- **State files describe wrong phase**: If bootstrap scans repo incompletely, phase may be underestimated (e.g., `p1` for a mature project). Mitigation: bootstrap must inspect `git log --oneline` depth, existing documentation, and file maturity heuristics.
- **`.agents/` accidentally gitignored**: Onboarding guide must include a verification step. Mitigation: `/dev-init` should warn if `.agents/` matches `.gitignore` patterns.
- **Bootstrap on dirty workspace**: Uncommitted changes confuse phase detection. Mitigation: `/dev-init` must warn and recommend committing or stashing first.
- **Windows file creation silent failure**: Goal-output artifacts may not be written. Mitigation: protocol scripts must use PowerShell-native file creation on Windows, Bash on Unix.

### 2.2 Resume Interrupted Work

**User intent**: Developer starts a new session (cleared chat, new day, different machine) and wants to continue where they left off.

**Expected behavior**:

1. Developer runs `/dev-status` (or reads `handoff.md` manually)
2. Protocol reads `.agents/dev-protocol/workflow-state.yml` and `handoff.md`
3. Protocol runs `git status`, `git log --oneline -5`, inspects uncommitted changes
4. Protocol validates state freshness: compares `checkpoint.last_commit` against `git rev-parse HEAD`
5. Protocol reports: current phase, active focus, last completed work, any drift warnings
6. Developer reviews recovery summary and decides next action

**Failure risks**:

- **Stale phase reported**: If `workflow-state.yml` was not updated during last checkpoint, resume reports outdated phase. Mitigation: resume must cross-check phase against git history depth and file maturity.
- **Stale workspace status**: If handoff says "1 modified file" but workspace is clean, developer distrusts protocol. Mitigation: resume must always run `git status` at invocation time; never rely solely on persisted metadata.
- **Missing state files**: If `.agents/` was not committed or was on another branch. Mitigation: resume must detect missing state and recommend re-bootstrap.

### 2.3 Save Development State

**User intent**: Developer has completed a goal or reached a natural stopping point and wants to persist progress.

**Expected behavior**:

1. Developer ensures workspace is in consistent state (no unfinished work)
2. Developer runs `/dev-save`
3. Protocol inspects changes since `checkpoint.last_commit`
4. If no meaningful changes (only state files themselves modified): early exit with "No meaningful changes detected"
5. If meaningful changes: Protocol updates `workflow-state.yml` and `handoff.md`
6. Protocol validates consistency: state matches repository reality, recoverability is high
7. Protocol creates exactly one commit with checkpoint-style message (`chore(checkpoint): ...`)
8. Protocol records `checkpoint.last_commit = PRE_HEAD` (parent of checkpoint commit)

**Failure risks**:

- **Checkpoint reuses goal message**: Skill fails to distinguish goal commit from checkpoint commit. Mitigation: `/dev-save` skill must explicitly check HEAD commit message format and generate a checkpoint-style message if needed.
- **Self-drift false positive**: If only state files changed since last checkpoint, but those changes were from manual edits. Mitigation: self-drift detection must compare `last_commit..HEAD` diff; if diff includes only state files, classify as NONE and early exit.
- **Partial commit on failure**: Validation fails but some files are already staged. Mitigation: `/dev-save` must fail before any `git add` or commit; use atomic staging.

### 2.4 Diagnose Broken State

**User intent**: Developer suspects something is wrong with the protocol state or wants to verify health.

**Expected behavior**:

1. Developer runs `/dev-status --diagnose` (or just `/dev-status` which includes diagnosis)
2. Protocol checks:
   - State files exist and are readable
   - `workflow-state.yml` schema is valid (required fields present)
   - `checkpoint.last_commit` is a valid git hash
   - `checkpoint.last_commit` matches `HEAD` or `HEAD~1` (tolerate one-commit drift)
   - `handoff.md` has required sections (Current Focus, Completed Since Last Checkpoint)
   - Git repository is initialized
   - `.agents/` is not gitignored
3. Protocol reports PASS/FAIL per check with specific remediation

**Failure risks**:

- **False positive on minor drift**: A one-commit drift (e.g., developer manually committed) should not be reported as broken. Mitigation: diagnosis tolerates `HEAD` being exactly one commit ahead of `last_commit`.
- **Schema validation too strict**: Adding optional fields to `workflow-state.yml` should not break diagnosis. Mitigation: schema validation checks only required fields, ignores unknown fields.

### 2.5 Switch Model/Session

**User intent**: Developer wants to use a different AI model (e.g., switch from Claude to GPT-4, or from Claude 3.5 to Claude 4) or start a completely fresh session.

**Expected behavior**:

1. Developer ends current session (or clears context)
2. Developer starts new session with new model
3. Developer runs `/dev-status`
4. Protocol reconstructs context from state files alone
5. Protocol reports current phase, focus, and next actions
6. Developer continues work without model-specific context leakage

**Failure risks**:

- **Model-specific artifacts in state**: If state files contain model-specific references (e.g., "Claude Code hook"), new model may be confused. Mitigation: state files must use runtime-agnostic language; model-specific behavior belongs in runtime adapter docs only.
- **Continuation prompt too weak**: New model expands scope beyond documented boundaries. Mitigation: continuation handoff in goal-output must explicitly forbid repository scanning and mandate adherence to documented context.

---

## 3. Command Surface Redesign

### 3.1 Design Goal

Reduce user-facing commands from 7 to 5. Eliminate overlapping concerns. Establish a single mental model: **setup → work → save → check**.

### 3.2 v2 User-Facing Commands

| Command | v1 Equivalent | Purpose | Writes Files? |
|---|---|---|---|
| `/dev-init` | `/dev-bootstrap` | Initialize protocol on a project, reconstruct state | Yes |
| `/dev-scope` | `/goal` + `/dev-goal-template` | Declare a focused objective with validation criteria | No (generates artifact) |
| `/dev-save` | `/dev-checkpoint` | Persist state, validate, commit | Yes |
| `/dev-status` | `/dev-resume` + `/dev-doctor` + `/dev-help` | Inspect current state, diagnose issues, show usage | No |

**Why 4 commands instead of 7:**

- `init` replaces `bootstrap` — "init" is universally understood (npm init, git init); "bootstrap" is jargon.
- `scope` replaces `goal` + `goal-template` — goal declaration and template generation are the same operation. A scope command always generates a standardized template.
- `save` replaces `checkpoint` — "save" maps to the universal mental model of persisting progress. "Checkpoint" requires learning a new term.
- `status` replaces `resume` + `doctor` + `help` — all three operations are read-only state inspection. A single `status` command with optional flags (`--resume`, `--diagnose`, `--help`) reduces surface area while preserving functionality.

### 3.3 Hidden/Internal Modules

These are not user-facing commands but are part of the protocol infrastructure:

| Module | Purpose | Triggered By |
|---|---|---|
| `scripts/fix-goal-output.ps1` / `.sh` | Normalize goal-output changed_files from git | `/dev-scope` completion (manual or hook) |
| `scripts/run-tests.ps1` / `.sh` | Validate protocol compliance | `/dev-save` validation, manual testing |
| `templates/workflow-state.yml` | Template for new `workflow-state.yml` | `/dev-init` |
| `templates/handoff.md` | Template for new `handoff.md` | `/dev-init` |
| `templates/project-rules.md` | Template for new `project-rules.md` | `/dev-init` |
| `templates/scope-prompt.md` | Template for scope declaration | `/dev-scope` |

### 3.4 Deprecated Commands

| Deprecated Command | Replacement | Migration Strategy |
|---|---|---|
| `/dev-bootstrap` | `/dev-init` | Skills retain `/dev-bootstrap` as alias printing "Use `/dev-init`" for one v2 minor version, then remove |
| `/dev-checkpoint` | `/dev-save` | Same alias strategy |
| `/dev-resume` | `/dev-status` | Same alias strategy |
| `/dev-doctor` | `/dev-status --diagnose` | Same alias strategy |
| `/dev-help` | `/dev-status --help` | Same alias strategy |
| `/dev-goal-template` | `/dev-scope` (template is built-in) | Remove immediately; no standalone template command needed |
| `/goal` | `/dev-scope` | Alias for one v2 minor version |

**Alias implementation**: Each deprecated skill checks if it was invoked directly. If so, it prints the replacement command and exits with code 0. It does not execute the old behavior to prevent confusion.

### 3.5 Backward Compatibility Strategy

1. **Phase 1 (v2.0.0)**: New commands active. Deprecated commands exist as aliases with deprecation warnings.
2. **Phase 2 (v2.1.0)**: Deprecated aliases removed. Documentation updated to reference only new commands.
3. **State file compatibility**: `workflow-state.yml`, `handoff.md`, `project-rules.md` formats remain unchanged. No migration needed.
4. **Script compatibility**: `scripts/fix-goal-output.ps1` and `tests/run-tests.ps1` remain unchanged.

---

## 4. Architecture Boundary

### 4.1 Protocol Core

The protocol core is everything required for correct behavior. It must be runtime-agnostic, OS-agnostic, and project-agnostic.

**Includes**:

- `.agents/dev-protocol/workflow-state.yml` — machine-readable state
- `.agents/dev-protocol/handoff.md` — human-readable handoff
- `.agents/dev-protocol/project-rules.md` — project constraints
- `scripts/fix-goal-output.ps1` / `.sh` — deterministic artifact normalization
- `tests/run-tests.ps1` / `.sh` — validation suite
- `docs/` — protocol design documents and guides
- `references/` — protocol reference rules (commit, workflow, memory, incidents)
- `templates/` — state file templates for new projects
- `skills/` — canonical skill definitions (PROMPT.md, SKILL.md)

**Guarantees**:

- Protocol core contains no runtime-specific logic (no Claude Code API calls, no Cursor extensions)
- Protocol core contains no project-specific logic (no assumptions about tech stack, build system, or dependencies)
- Protocol core works on Windows, macOS, Linux without modification

### 4.2 Runtime Integration

Runtime integration is optional convenience automation that maps protocol semantics to a specific AI runtime's interaction model.

**Includes**:

- `.claude/` — Claude Code adapter (settings.json, hooks, skill symlinks)
- `.cursor/` — (future) Cursor adapter
- `.vscode/` — (future) VS Code extension adapter
- `integrations/copilot/` — (future) GitHub Copilot adapter

**Rules**:

- Runtime adapters must be removable without breaking protocol core
- Runtime adapters must not contain protocol logic (only wiring and mapping)
- Runtime adapters must not modify protocol core files
- Runtime adapters may provide automation hooks (e.g., Claude Code Stop hook) but must document manual equivalents

### 4.3 Claude-Specific Behavior

Claude Code is the reference runtime. Claude-specific behavior is confined to `.claude/`.

**Includes**:

- `.claude/settings.json` — Claude Code harness configuration
- `.claude/hooks/stop-hook.ps1` — Normalization + validation hook
- `.claude/skills/*` — Symlinks to `skills/` (Claude Code auto-discovery convention)

**Rules**:

- Claude-specific files are tracked in git for convenience but are not part of the protocol contract
- `.claude/skills/` must contain only symlinks; canonical source is `skills/`
- Hooks are convenience automation, not protocol requirements

### 4.4 Reusable Modules

Reusable modules are protocol components that can be extracted and used independently.

**Includes**:

- `scripts/fix-goal-output.ps1` — Git-derived file list extraction (reusable for any project needing deterministic changed_files)
- `tests/run-tests.ps1` — Case-based test runner framework (reusable for any project needing structured validation)
- `templates/*.md` / `*.yml` — State file templates (reusable for any project adopting dev-protocol)

### 4.5 What Belongs Outside Protocol

The following must NOT be included in the dev-protocol repository or treated as protocol concerns:

- **Project-specific code**: The protocol is a workflow layer, not a code generator
- **CI/CD configuration**: `.github/workflows/`, `.gitlab-ci.yml`, etc. are project concerns
- **Dependency management**: `package.json`, `requirements.txt`, `Cargo.toml` are project concerns
- **IDE settings** (except runtime adapter config): `.idea/`, `.vscode/settings.json` are developer preference
- **Build artifacts**: `dist/`, `build/`, `target/` are project outputs
- **Deployment configuration**: Dockerfiles, Kubernetes manifests, terraform are project concerns
- **Multi-agent orchestration**: v2 remains single-agent. Multi-agent scheduling belongs in a separate orchestration layer.

---

## 5. Deferred Backlog Reclassification

### 5.1 Category A: Implement Before Real-Project Testing

These items block reliable real-project adoption and must be resolved before v2 is considered ready for external validation.

| Item | Title | Justification |
|---|---|---|
| #14 | Phase drift on resume | Core state reconciliation bug. If resume restores p1 for a p3 project, the agent wastes time redoing completed work or makes incorrect assumptions about project maturity. |
| #15 | Repository status freshness drift | Core state reconciliation bug. Stale workspace status undermines trust in the protocol. Developers will stop using `/dev-status` if it lies about git state. |
| #13 | Checkpoint commit message contract | Breaks case-05 validation. If checkpoint commits are indistinguishable from goal commits, the validation suite cannot verify checkpoint behavior. |
| #12 | case-05 / case-06 execution order | Validation ambiguity causes real-project friction. During DesignDocMCP onboarding, the correct order was discovered by trial and error, not documentation. |
| #6 | Continuation handoff prompt hardening | Scope expansion on cold-start wastes tokens and introduces risk. The prompt seed must be strong enough to constrain any model. |
| #7 | NO_OP goal false FAILs | False failures erode confidence in the validation suite. A legitimate no-change goal should pass case-06 without requiring dummy file modifications. |
| #8 | Windows bash heredoc failure | Core usability on Windows. If artifact emission fails silently on 50% of developer machines, the protocol is unreliable. |
| #10 | `.agents` directory convention | Onboarding blocker. New adopters need to understand why `.agents/` exists and how it relates to `.claude/`. |
| #11 | Real-project validation checklist | Onboarding blocker. Without a checklist, each real-project adoption requires rediscovering the validation sequence. |

### 5.2 Category B: Require Real-Project Data

These items cannot be resolved with theory alone; they need empirical data from real project usage.

| Item | Title | Justification |
|---|---|---|
| #3 | 10-file / 50-file scope threshold | The threshold was chosen arbitrarily. Calibration requires measuring goal commit sizes across multiple real projects and developers. |
| #1 | Session output capture for output contract automation | Depends on runtime capabilities (Claude Code session logging, agent SDK hooks). Implementation strategy varies by runtime and requires real-project testing to validate capture fidelity. |
| #4 | Continuation handoff validation | Blocked on item #1. Automated validation requires session output capture. |
| #9 | Test numbering standardization | Renumbering tests is a breaking change to documentation and muscle memory. Wait until the test suite stabilizes with real-project feedback. |

### 5.3 Category C: Obsolete or Remove

These items are already resolved, have negligible impact, or conflict with v2 direction.

| Item | Title | Justification |
|---|---|---|
| #2 | Duplicate state files (root + `.agents/dev-protocol/`) | **Completed** in v1. Root-level copies removed. No action needed. |
| #5 | Redundant git diff checks in case-06 | Intentional redundancy for documentation clarity. Removing it saves 4 lines of PowerShell but reduces readability. Cost of removal exceeds benefit. Keep as-is. |
| #9-runtime | Runtime directory migration `.agent/` → `.agents/` | **Completed** in v1. Migration finished. Fallback code in `/dev-resume` is dead code but harmless. Remove fallback in v2 cleanup phase if desired, but not a blocker. |

---

## 6. v2 Roadmap Phases

### R0: Redesign Planning

**Goal**: Produce this roadmap document and gain consensus on v2 direction.

**Scope**:

- Write `docs/v2-redesign-roadmap.md` with all 7 required sections
- Review against v1 retrospective and deferred improvements
- Ensure no placeholders, no "same as above", no vague wording

**Non-goals**:

- No code changes
- No state file format changes
- No command implementation

**Validation criteria**:

- [ ] Roadmap covers all 7 required sections with implementation-level detail
- [ ] Every deferred item is reclassified with justification
- [ ] Command surface is reduced from 7 to 5 commands with clear migration path
- [ ] Architecture boundary explicitly states what belongs outside protocol
- [ ] case-06 PASS on roadmap commit

### R1: Command Redesign

**Status**: Completed (documentation-first)

**Goal**: Implement v2 command surface (init, scope, save, status) and deprecate v1 commands.

**Scope**:

- ~~Create `skills/dev-init/` with PROMPT.md and SKILL.md~~ (deferred to R2)
- ~~Create `skills/dev-scope/` (merges goal + goal-template behavior)~~ (deferred to R2)
- ~~Create `skills/dev-save/` (replaces checkpoint)~~ (deferred to R2)
- ~~Create `skills/dev-status/` (merges resume + doctor + help)~~ (deferred to R2)
- ~~Update `.claude/skills/` symlinks~~ (deferred to R2)
- [x] Update `docs/onboarding.md` to reference new commands
- [x] Update `references/workflow-rules.md` to reference new commands
- [x] Update `README.md` command table
- [x] Update `docs/runtime-integrations.md` semantic operations table
- [x] Update `.agents/dev-protocol/project-rules.md` with reality priority and v2 commands
- ~~Add deprecated command aliases (print replacement + exit)~~ (deferred to R2)

**Non-goals**:

- Do not change state file format
- Do not change validation tests (case-05, case-06)
- Do not change scripts (fix-goal-output, run-tests)

**Validation criteria**:

- [x] v2 command surface documented (init, scope, save, status)
- [x] Deprecated commands documented with migration path
- [x] Documentation references only new commands (with deprecation notes)
- [x] case-06 PASS on command redesign goal commit
- [x] Onboarding answers first-contact question within 10 seconds
- [x] No duplicated command responsibility
- [x] Validation order explicitly documented (case-06 before save, case-05 after save)
- [x] `.agents` directory convention documented
- [x] Reality priority hierarchy defined

### R2: Onboarding Orchestration

**Goal**: Harden the first-time project onboarding experience.

**Scope**:

- Implement `/dev-init` skill with project maturity heuristics:
  - Inspect `git log --oneline` depth to estimate phase
  - Inspect existing documentation files to estimate project maturity
  - Inspect directory structure (src/, tests/, docs/, etc.) to estimate project type
- Add `.agents/` gitignore detection to `/dev-init` (warn if `.agents/` is ignored)
- Add dirty workspace warning to `/dev-init`
- Write `docs/real-project-validation-checklist.md` with step-by-step validation for new projects
- Write `docs/agents-convention.md` explaining `.agents/` rationale and naming

**Non-goals**:

- Do not auto-commit from `/dev-init`
- Do not modify existing project code or docs
- Do not create branches

**Validation criteria**:

- [ ] `/dev-init` on a mature project estimates phase >= p2 (not p1)
- [ ] `/dev-init` on a dirty workspace warns before proceeding
- [ ] `/dev-init` warns if `.agents/` matches `.gitignore`
- [ ] `docs/real-project-validation-checklist.md` exists and covers bootstrap → scope → save → status cycle
- [ ] `docs/agents-convention.md` explains `.agents/` vs `.agent/` vs `.claude/`
- [ ] case-06 PASS

### R3: State Reconciliation

**Goal**: Fix core state reconciliation bugs that caused drift during real-project validation.

**Scope**:

- Fix `/dev-status` (resume) to always run `git status` at invocation time:
  - Remove reliance on cached workspace status from `handoff.md`
  - Recompute repository state from git on every invocation
- Fix `/dev-save` (checkpoint) to persist phase changes:
  - `workflow-state.yml` phase must be derived from git history + file maturity, not just copied forward
  - If phase progression is detected, update `workflow-state.yml` before committing
- Fix checkpoint commit message contract:
  - `/dev-save` must generate `chore(checkpoint): ...` format
  - Must not reuse previous goal commit message
  - Enforce via skill prompt-level rules
- Fix `/dev-status` phase detection:
  - Cross-check `workflow-state.yml` phase against git log depth
  - Warn if persisted phase is significantly behind computed phase

**Non-goals**:

- Do not change state file schema
- Do not add new state files
- Do not change validation tests

**Validation criteria**:

- [ ] `/dev-status` reports accurate git status even when `handoff.md` claims otherwise
- [ ] After `/dev-save` on a progressed project, `workflow-state.yml` phase matches computed maturity
- [ ] `/dev-save` always generates checkpoint-style commit message
- [ ] case-05 PASS after `/dev-save`
- [ ] case-06 PASS after `/dev-scope` + `/dev-save` cycle
- [ ] Manual test: simulate stale handoff, verify `/dev-status` corrects it

### R4: Onboarding Hardening

**Goal**: Fix remaining usability blockers before real-project validation.

**Scope**:

- Fix Windows artifact emission:
  - Update goal-output generation instructions to use PowerShell-native creation on Windows
  - Update `docs/runtime-integrations.md` with OS-specific file creation guidance
  - Update skill prompts to prefer `Write-Host` / `Out-File` on Windows
- Fix NO_OP goal handling:
  - Update `tests/run-tests.ps1` case-06 to tolerate absent goal-output artifact when HEAD commit has zero file changes
  - Document NO_OP goal behavior in `references/workflow-rules.md`
- Fix continuation handoff prompt:
  - Update `templates/scope-prompt.md` with hardened continuation seed
  - Explicitly forbid repository scanning, prior assumptions, and scope expansion
  - Require adherence to documented context and boundary
- Fix case-05 / case-06 order documentation:
  - Update `references/workflow-rules.md` with explicit validation sequence: `/dev-scope → case-06 → /dev-save → case-05`
  - Update skill prompts to remind user of correct order

**Non-goals**:

- Do not implement session output capture (deferred to B-category)
- Do not change state file format
- Do not renumber tests

**Validation criteria**:

- [ ] Windows developer can create goal-output artifact reliably using documented method
- [ ] case-06 passes on a NO_OP goal (zero file changes)
- [ ] Continuation handoff prompt prevents scope expansion in cold-start test
- [ ] `references/workflow-rules.md` documents correct validation order
- [ ] case-06 PASS

### R5: Real Project Validation

**Goal**: Validate v2 protocol against a real external project and measure onboarding success.

**Scope**:

- Select a real project (DesignDocMCP or new project)
- Follow `docs/real-project-validation-checklist.md` exactly
- Measure onboarding time (target: < 15 minutes from clone to first `/dev-save`)
- Measure resume accuracy (target: phase correct in 100% of trials)
- Measure status freshness (target: git status accuracy 100%)
- Collect goal commit size data for threshold calibration (deferred #3)
- Document any new friction points
- Update deferred improvements with new findings

**Non-goals**:

- Do not modify the real project's code (protocol is workflow-only)
- Do not add v3 features
- Do not implement multi-agent support

**Validation criteria**:

- [ ] Onboarding checklist completed without deviation
- [ ] First `/dev-init` produces accurate phase estimation
- [ ] First `/dev-save` succeeds with checkpoint-style message
- [ ] `/dev-status` in new session restores correct phase and focus
- [ ] All validation tests (case-05, case-06) pass during real-project usage
- [ ] Goal commit size data collected from >= 5 goals
- [ ] No Category A deferred items remain open
- [ ] Retrospective document written: `docs/retrospective-v2.md`

---

## 7. Success Criteria

dev-protocol v2 is considered "Ready for real project onboarding" when all of the following measurable criteria are met:

### 7.1 Protocol Correctness

1. **State reconciliation accuracy**: `/dev-status` reports `git status` that matches `git status --short` in 100% of trials (n >= 10).
2. **Phase estimation accuracy**: `/dev-init` on a mature project (>= 10 commits, >= 3 docs) estimates phase >= p2 in 100% of trials (n >= 5 projects).
3. **Checkpoint commit contract**: `/dev-save` generates `chore(checkpoint): ...` format in 100% of trials (n >= 10).
4. **Self-drift detection**: `/dev-save` with no meaningful changes since last baseline early-exits without creating a commit in 100% of trials (n >= 5).
5. **Recoverability**: After `/dev-save`, a fresh session `/dev-status` restores the same phase, focus, and next actions as the previous session in 100% of trials (n >= 5).

### 7.2 Onboarding Success

6. **Onboarding time**: A developer unfamiliar with dev-protocol completes `docs/real-project-validation-checklist.md` from project clone to first successful `/dev-save` in < 15 minutes.
7. **First-try bootstrap success**: `/dev-init` succeeds without manual correction on first attempt in >= 80% of trials (n >= 5 projects).
8. **Documentation completeness**: `docs/onboarding.md` covers all 6 scenarios without referencing deprecated commands.
9. **No Category A blockers**: All Category A deferred items are resolved and closed.

### 7.3 Validation Suite

10. **case-05 PASS rate**: `pwsh tests/run-tests.ps1 -Case 05` passes in 100% of post-checkpoint trials (n >= 10).
11. **case-06 PASS rate**: `pwsh tests/run-tests.ps1 -Case 06` passes in 100% of post-scope trials (n >= 10), including NO_OP goals.
12. **Test coverage**: All user-facing commands (`init`, `scope`, `save`, `status`) have at least one validation case covering their primary success path.

### 7.4 Usability

13. **Command count**: Exactly 4 user-facing commands exist: `init`, `scope`, `save`, `status`.
14. **Deprecated command behavior**: All deprecated commands (`/dev-bootstrap`, `/dev-checkpoint`, `/dev-resume`, `/dev-doctor`, `/dev-help`, `/dev-goal-template`, `/goal`) print a deprecation message naming the replacement and exit with code 0.
15. **Windows reliability**: File creation operations (goal-output, state files) succeed on Windows without requiring bash heredoc syntax.

### 7.5 Exit Criteria

v2 development stops when criteria 1–15 are all satisfied and `docs/retrospective-v2.md` is written. No further protocol changes until a new real-project adoption triggers a v3 redesign.
