# dev-protocol

A session-resilient development workflow protocol for AI-assisted development.

## Problem

AI-assisted development sessions lose all context when the chat is cleared or a new session starts. Development progress — decisions made, changes staged, next steps planned — is trapped in conversation history and lost on session reset.

dev-protocol solves this by persisting development state to durable files in the repository, enabling any fresh session to resume work without prior chat history.

**Runtime-agnostic**: The protocol core works with Claude Code, Cursor, GitHub Copilot, custom agents, or manual workflows. Claude Code is the reference runtime; other environments use the same files and scripts through their own interaction models. See [`docs/runtime-integrations.md`](docs/runtime-integrations.md) for details.

---

## Agent Quick Start (Required)

Before making any changes:

1. Read `PROJECT_BACKGROUND.md`
2. Read `.agents/dev-protocol/handoff.md`
3. Run `/dev-status`
4. Check `.agents/dev-protocol/docs/deferred-improvements.md`
5. Follow active roadmap instead of inventing new direction

This repository is developed using **dev-protocol itself**.

Do not:
- start coding without reading context
- ignore deferred items
- redesign architecture without scope
- skip protocol state updates

Current development mode:

> stabilization → ergonomics → long-running robustness

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

### Command Reference

| Command | When to Use | Never Use For |
|---------|-------------|---------------|
| `/dev-status` | Start of session, check state, detect drift | Saving progress, declaring goals, modifying files |
| `/dev-scope` | Before any implementation work | Already-clear tasks, exploration without deliverables |
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
| Save | `/dev-save` | Yes | Persist protocol state files only, validate (fails on inconsistency) |
| Status | `/dev-status` | No | Inspect current protocol state and reconstruct context |

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

## Current Status

**Phase**: p3 (v2-frozen-ready-for-real-project-validation) — **active**

**Completed**:
- v2 command surface defined (init, scope, save, status)
- v1 commands deprecated with migration path
- State file templates and validation rules
- Runtime directory at `.agents/dev-protocol/`
- Commit convention and failure policy
- case-05 and case-06 test validation passed (17/17 checks)
- v1 retrospective completed and frozen
- Unified onboarding guide with happy path and recovery path
- Validation order explicitly documented
- `.agents` directory convention documented
- Incident logging mechanism
- Real-project onboarding guide
- External benchmark of 7 workflow systems (ECC, Superpowers, Spec Kit, LangGraph, wshobson/commands, barkain, Microsoft Agent Framework)
- v2 freeze readiness assessment: READY_TO_FREEZE_V2

**Known limitations (v2 scope)**:
- Single-agent only (no multi-agent support)
- No auto-repair or complex document inference
- No advanced hooks or long-term memory
- Confidence downgrade mechanism untested in real projects

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
