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

1. **Bootstrap** — Initialize protocol on a project. Reconstructs current state from code, docs, and git history into state files. No auto-commit.
2. **Checkpoint** — Persist changes to state files, validate consistency, and commit. After checkpoint, it is safe to start a new session.
3. **New Session** — Reset conversation context. State survives in repository files.
4. **Resume** — Recover full development context from state files. Read-only; never modifies files.
5. **Goal** — Set a scoped, multi-step objective with validation criteria.
6. **Checkpoint** — Save progress toward the goal.

Repeat the checkpoint → new session → resume cycle as needed.

In Claude Code, these semantic operations map to slash commands:
`Bootstrap` = `/dev-bootstrap`, `Checkpoint` = `/dev-checkpoint`, `Resume` = `/dev-resume`, `Goal` = `/goal`.

## Commands

Protocol commands are semantic operations. The Claude Code representations use slash commands; other runtimes may use function calls, CLI tools, or chat prompts.

| Semantic | Claude Code | Writes Files? | Description |
|----------|:-----------:|:------------:|-------------|
| Bootstrap | `/dev-bootstrap` | Yes | Initialize protocol, reconstruct state, no auto-commit |
| Checkpoint | `/dev-checkpoint` | Yes | Persist state, validate, commit (fails on inconsistency) |
| Resume | `/dev-resume` | No | Recover context from state files (read-only) |
| Goal Template | `/dev-goal-template` | No | Generate a standardized goal template for `Goal` |
| Doctor | `/dev-doctor` | No | Diagnose protocol health issues (read-only) |
| Help | `/dev-help` | No | Quick usage reference |

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
| `case-01-basic` | Full lifecycle: bootstrap → change → checkpoint → resume → idempotent checkpoint |
| `case-05-first-checkpoint` | First checkpoint from a bootstrapped (no prior commit) state |
| `case-06-goal-workflow` | Goal setting and completion cycle |

## Current Status

**Phase**: p3 (v1-frozen-deferred-backlog-review) — **active**

**Completed**:
- Three core commands defined and implemented
- State file templates and validation rules
- Runtime directory at `.agents/dev-protocol/`
- Commit convention and failure policy
- case-05 and case-06 test validation passed (17/17 checks)
- v1 retrospective completed and frozen
- Usability commands added (goal-template, doctor, help)
- Incident logging mechanism
- Real-project onboarding guide

**Known limitations (v1 scope)**:
- Single-agent only (no multi-agent support)
- No auto-repair or complex document inference
- No advanced hooks or long-term memory

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
