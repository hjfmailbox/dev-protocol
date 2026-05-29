# dev-protocol

A session-resilient development workflow protocol for AI-assisted development.

## Problem

AI-assisted development sessions lose all context when the chat is cleared or a new session starts. Development progress — decisions made, changes staged, next steps planned — is trapped in conversation history and lost on session reset.

dev-protocol solves this by persisting development state to durable files in the repository, enabling any fresh session to resume work without prior chat history.

**Runtime-agnostic**: The protocol core works with Claude Code, Cursor, GitHub Copilot, custom agents, or manual workflows. Claude Code is the reference runtime; other environments use the same files and scripts through their own interaction models. See [`docs/runtime-integrations.md`](docs/runtime-integrations.md) for details.

---

## Agent Quick Start (Required)

Before making any changes:

1. **Read `docs/v2-redesign-roadmap.md`** -- this is the current execution roadmap and single source of truth for active work
2. **Read `docs/command-contracts.md`** -- exact contracts for when/how to use each `/dev-*` command
3. Read `PROJECT_BACKGROUND.md`
4. Read `.agents/dev-protocol/handoff.md`
5. Run `/dev-status`
6. Check `.agents/dev-protocol/docs/deferred-improvements.md`
7. Follow active roadmap instead of inventing new direction

This repository is developed using **dev-protocol itself**.

Do not:
- start coding without reading context
- ignore deferred items
- redesign architecture without scope
- skip protocol state updates

Current development mode:

> stabilization → ergonomics → long-running robustness

**New**: Semantic validation layer (Phase X.2) reduces false negatives from rigid string matching. Validation criteria, loop completion, and drift detection now support equivalent wording interpretation.

---

## Core Workflow

```
Init → Scope → Work → Save → New Session → Status → Scope → ...
```

1. **Init** — Inspect repository and reconstruct basic project reality. Creates `.agents/dev-protocol/` state files reflecting actual project state. Defaults to `phase: unknown` until user validation. No auto-commit.
2. **Scope** — Declare a focused, multi-step objective with validation criteria.
3. **Work** — Implement changes within the scoped objective. Make normal git commits during work.
4. **Save** — Persist protocol state files (`.agents/dev-protocol/*`), validate consistency, and create a protocol commit automatically. Does not modify source code or stage non-protocol files.
5. **New Session** — Reset conversation context. State survives in repository files.
6. **Status** — Inspect current protocol state and reconstruct development context. Read-only; never modifies files.

Repeat the scope → work → save → new session → status cycle as needed.

In Claude Code, these semantic operations map to slash commands:
`Init` = `/dev-init`, `Scope` = `/dev-scope`, `Save` = `/dev-save`, `Status` = `/dev-status`.

## Protocol Workflow

### Standard Implementation Loop

```text
/dev-status
/dev-scope
/goal
implement
/dev-save
```

1. `/dev-status` — Recover context in a fresh session
2. `/dev-scope` — Declare a focused goal with validation criteria
3. `/goal` — Implement changes within the declared scope
4. `implement` — Make normal git commits during work
5. `/dev-save` — Persist protocol state after completing the goal

### Simple Scope Loop (Auto-Execution)

For simple, low-risk work, `/dev-scope` can execute directly without a separate `/goal`.

```text
/dev-status
/dev-scope "fix typo in README"
/dev-save
```

**Auto-execution criteria** (ALL must be true):
- Affects ≤ 3 files
- No public API changes
- No cross-module dependencies
- Single-step validation
- Non-architectural change
- Low blast radius

If criteria are met, `/dev-scope` executes immediately, creates normal commits, and produces a goal-output artifact.

If criteria are NOT met, `/dev-scope` produces a scope document and waits for `/goal` as usual.

### Verification Loop

Not every loop requires source code changes.

```text
/dev-status
verify
/dev-save
```

1. `/dev-status` — Recover context
2. `verify` — Check existing behavior (e.g., audit, review, validation)
3. `/dev-save` — Record verification result even if no files changed

**Rule**: Not all loops produce code or documentation changes. Verification loops, no-op confirmations, and behavioral audits are valid outcomes. `/dev-save` supports these cases.

### Planned Execution Loop (`continue loop`)

When `next-phase-plan.md` exists, automatically derive and execute the next planned loop.

```text
/dev-status
generate plan
continue loop
/dev-save
```

1. `/dev-status` — Recover context
2. `generate plan` — Read context, decompose goal into loops, write `next-phase-plan.md`
3. `continue loop` — Read plan, find next incomplete loop, derive scope, auto-execute or produce scope document
4. `/dev-save` — Persist protocol state after loop completion

**Behavior**:
- If no plan exists: `generate plan` creates one from context
- If next loop is simple (≤3 files, non-architectural, concrete): auto-executes directly
- If next loop is complex: produces scope document, waits for `/goal`
- If all loops completed: reports completion

**Canonical autonomous workflow**:
```text
goal → generate plan → continue loop → /dev-save
```

### Command Reference

| Command | When to Use | Never Use For |
|---------|-------------|---------------|
| `/dev-status` | Start of session, check state, detect drift | Saving progress, declaring goals, modifying files |
| `/dev-scope` | Before any implementation work; auto-executes simple scopes | Already-clear tasks, exploration without deliverables |
| `generate plan` | Before `continue loop`, when no plan exists; decompose goal into loops | Executing work, inspecting state, saving progress |
| `continue loop` | When `next-phase-plan.md` exists; proceed to next planned loop | No plan exists, ambiguous next loop, dirty workspace |
| `/goal` | Implementation within a scoped objective | Unscoped work, saving state, inspecting context |
| `/dev-save` | After completing work, before ending session | Uncommitted source changes you intend to keep, unscoped work |
| `/dev-init` | First contact, missing state files, corrupted state | Projects with existing valid state |

For detailed command contracts, see [`docs/command-contracts.md`](docs/command-contracts.md).

## Commands

Protocol commands are semantic operations. The Claude Code representations use slash commands; other runtimes may use function calls, CLI tools, or chat prompts.

### Canonical v2 Commands

| Command | Claude Code | Writes Files? | Description |
|----------|:-----------:|:------------:|-------------|
| Init | `/dev-init` | Yes | Inspect repository, reconstruct project reality, initialize protocol state |
| Scope | `/dev-scope` | No | Declare a focused goal with validation criteria |
| Plan | `generate plan` | Yes | Generate `next-phase-plan.md` from context and goal decomposition |
| Save | `/dev-save` | Yes | Persist protocol state files only, validate (fails on inconsistency) |
| Status | `/dev-status` | No | Inspect current protocol state and reconstruct context |
| Continue | `continue loop` | Conditional | Derive and execute next loop from `next-phase-plan.md` |

### Legacy Aliases (Backward Compatibility Only)

| Legacy Command | Replacement | Status |
|---|---|---|
| `/dev-bootstrap` | `/dev-init` | Deprecated, redirects to v2 |
| `/dev-checkpoint` | `/dev-save` | Deprecated, redirects to v2 |
| `/dev-resume` | `/dev-status` | Deprecated, redirects to v2 |
| `/dev-doctor` | `/dev-status --diagnose` | Deprecated, redirects to v2 |
| `/dev-help` | `/dev-status --help` | Deprecated, redirects to v2 |
| `/dev-goal-template` | `/dev-scope` | Deprecated, redirects to v2 |
| `/goal` | `/dev-scope` | Deprecated, redirects to v2 |

Key guarantees:

- **State over history**: current file truth > appended logs
- **Fail-fast**: hard failure on corruption, soft failure on ambiguity
- **State files only**: /dev-save writes only `.agents/dev-protocol/*`, never source code
- **Self-drift detection**: repeated save with no real changes requires no action
- **Runtime-agnostic**: protocol correctness does not depend on any specific AI runtime

## State Files

All state files live in `.agents/dev-protocol/`:

| File | Purpose |
|------|---------|
| `workflow-state.yml` | Machine-readable progress, phase, and persistence metadata |
| `handoff.md` | Human-readable session handoff with current focus and next actions |
| `project-rules.md` | Project-specific constraints, coding standards, and known pitfalls |

The state directory is the single source of truth. History is secondary.

## Testing

Test cases are under `tests/`:

| Case | Description |
|------|-------------|
| `case-01-basic` | Full lifecycle: init → scope → work → save → status → idempotent save |
| `case-05-first-checkpoint` | First save from an initialized (no prior checkpoint) state |
| `case-06-goal-workflow` | Scope declaration and completion cycle |
| `case-07-dirty-workspace` | Dirty workspace handling during save |
| `case-08-noop-save` | No-op workflow with clean workspace |
| `case-09-history-rewrite` | History rewrite (rebase/reset) resilience |
| `case-10-compact-resume` | Session compaction survival |
| `case-11-phase-inference` | Phase inference from context |
| `case-12-protocol-commit` | Protocol commit classification |
| `case-24-phase-inference-extended` | Phase inference extended validation |
| `case-25-noop-save-extended` | No-op save extended validation |
| `case-26-focus-migration` | Focus recovery without current-focus.md |

Run all tests:

```bash
pwsh tests/run-tests.ps1
```

For the full protocol test matrix, see [`docs/test-matrix.md`](docs/test-matrix.md).

## Current Status

**Phase**: p3 (v2-frozen-ready-for-real-project-validation) — **active**

**Completed**:
- v2 command surface defined and implemented (`/dev-init`, `/dev-scope`, `/dev-save`, `/dev-status`)
- v1 commands deprecated with redirect aliases
- State file templates and validation rules
- Runtime directory at `.agents/dev-protocol/`
- Commit convention and failure policy
- Unified onboarding guide with happy path and recovery paths
- Validation order explicitly documented
- `.agents` directory convention documented
- External benchmark of 7 workflow systems -- assessment: READY_TO_FREEZE_V2
- Command contracts documented (`docs/command-contracts.md`)
- Phase inference implemented (5-step priority)
- No-op save support (clean workspace checkpoint commits)
- Protocol commit detection stable (case-12)
- Test matrix expanded to case-12 + case-A/B/C
- All active tests passing: case-05~12 PASS, case-A/B/C PASS

**In progress (stabilization)**:
- v1 reference cleanup across docs and alias skills
- Project background generation workflow
- Test coverage gap closure

**Known limitations (v2 scope)**:
- Single-agent only (no multi-agent support)
- No auto-repair or complex document inference
- No advanced hooks or long-term memory
- Confidence downgrade mechanism untested in real projects
- Workflow compression design complete, implementation deferred

## Runtime Support

| Runtime | Integration | Status |
|---|---|---|
| Claude Code | `.claude/` directory with hooks and settings | Active (reference runtime) |
| Cursor | Manual workflow or future plugin | Compatible |
| GitHub Copilot | Manual workflow or future extension | Compatible |
| Manual / Other | Direct script invocation | Compatible |

The protocol core (`scripts/`, `tests/`, `.agents/`, `docs/`, `references/`) contains no runtime-specific logic. Runtime adapters live in optional directories (e.g., `.claude/`) and are convenience automation only. See [`docs/runtime-integrations.md`](docs/runtime-integrations.md) for integration details.

## Project Structure

```
.agents/dev-protocol/    Project-local protocol state (workflow-state.yml, handoff.md, project-rules.md)
.claude/                 Claude Code adapter layer only (hooks, settings, skill symlinks)
docs/                    Design documents, retrospective, onboarding guide, runtime integrations
references/              Protocol reference rules (commit, failure, sync, memory, workflow, incidents)
skills/                  Protocol runtime — canonical skill definitions (PROMPT.md, SKILL.md per command)
templates/               State file templates for new projects
tests/                   Protocol validation suite (case-05, case-06)
scripts/                 Deterministic tooling (fix-goal-output, debug diagnostics)
```

For detailed design documents, see `docs/`. For protocol rules, see `references/`.
For onboarding a new project, see `docs/onboarding.md`.
For runtime integration details, see `docs/runtime-integrations.md`.
