# dev-protocol

A session-resilient development workflow protocol for AI-assisted development.

## Problem

AI-assisted development sessions lose all context when the chat is cleared or a new session starts. Development progress — decisions made, changes staged, next steps planned — is trapped in conversation history and lost on session reset.

dev-protocol solves this by persisting development state to durable files in the repository, enabling any fresh session to resume work without prior chat history.

**Runtime-agnostic**: The protocol core works with Claude Code, Cursor, GitHub Copilot, custom agents, or manual workflows. Claude Code is the reference runtime; other environments use the same files and scripts through their own interaction models. See [`docs/runtime-integrations.md`](docs/runtime-integrations.md) for details.

## Core Workflow

```
Bootstrap → Checkpoint → New Session → Resume → Goal → Checkpoint
```

1. **Init** — Initialize protocol on a project. Inspects git history, docs, and directory structure. Creates `.agents/dev-protocol/` state files. No auto-commit.
2. **Scope** — Declare a focused, multi-step objective with validation criteria.
3. **Work** — Implement changes within the scoped objective.
4. **Save** — Persist progress to state files, validate consistency, and commit. After save, it is safe to start a new session.
5. **New Session** — Reset conversation context. State survives in repository files.
6. **Status** — Recover full development context from state files. Diagnose issues. Read-only; never modifies files.

Repeat the scope → work → save → new session → status cycle as needed.

In Claude Code, these semantic operations map to slash commands:
`Init` = `/dev-init`, `Scope` = `/dev-scope`, `Save` = `/dev-save`, `Status` = `/dev-status`.

## Commands

Protocol commands are semantic operations. The Claude Code representations use slash commands; other runtimes may use function calls, CLI tools, or chat prompts.

| Command | Claude Code | Writes Files? | Description |
|----------|:-----------:|:------------:|-------------|
| Init | `/dev-init` | Yes | Initialize protocol on a project, reconstruct state |
| Scope | `/dev-scope` | No | Declare a focused goal with validation criteria |
| Save | `/dev-save` | Yes | Persist state, validate, commit (fails on inconsistency) |
| Status | `/dev-status` | No | Inspect state, diagnose issues, resume context, show help |

Key guarantees:

- **State over history**: current file truth > appended logs
- **Fail-fast**: hard failure on corruption, soft failure on ambiguity
- **No partial commits**: checkpoint either fully succeeds or produces no commit
- **Self-drift detection**: repeated checkpoint with no real changes produces no commit
- **Runtime-agnostic**: protocol correctness does not depend on any specific AI runtime

## State Files

All state files live in `.agents/dev-protocol/`:

| File | Purpose |
|------|---------|
| `workflow-state.yml` | Machine-readable progress, phase, and checkpoint metadata |
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

**Phase**: p3 (v1-frozen-deferred-backlog-review) — **active**

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

**Known limitations (v2 scope)**:
- Single-agent only (no multi-agent support)
- No auto-repair or complex document inference
- No advanced hooks or long-term memory
- New skill files for v2 commands not yet created (documentation-first redesign)

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
.agents/dev-protocol/    State files (workflow-state.yml, handoff.md, project-rules.md, incidents.md)
.claude/                 Optional Claude Code runtime adapter (hooks, settings, skill symlinks)
docs/                    Design documents, retrospective, onboarding guide, runtime integrations
references/              Protocol reference rules (commit, failure, sync, memory, workflow, incidents)
skills/                  Skill definitions (PROMPT.md, SKILL.md per command)
templates/               State file templates for new projects
tests/                   Test cases and plans
```

For detailed design documents, see `docs/`. For protocol rules, see `references/`.
For onboarding a new project, see `docs/onboarding.md`.
For runtime integration details, see `docs/runtime-integrations.md`.
