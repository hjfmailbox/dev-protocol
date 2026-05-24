# dev-protocol

A session-resilient development workflow protocol for Claude Code.

## Problem

Claude Code sessions lose all context when the chat is cleared or a new session starts. Development progress — decisions made, changes staged, next steps planned — is trapped in conversation history and lost on `/clear`.

dev-protocol solves this by persisting development state to durable files in the repository, enabling any fresh session to resume work without prior chat history.

## Core Workflow

```
/dev-bootstrap → /dev-checkpoint → /clear → /dev-resume → /goal → /dev-checkpoint
```

1. **`/dev-bootstrap`** — Initialize protocol on a project. Reconstructs current state from code, docs, and git history into state files. No auto-commit.
2. **`/dev-checkpoint`** — Persist changes to state files, validate consistency, and commit. After checkpoint, it is safe to clear chat.
3. **`/clear`** — Reset conversation context. State survives in repository files.
4. **`/dev-resume`** — Recover full development context from state files. Read-only; never modifies files.
5. **`/goal`** — Set a scoped, multi-step objective with validation criteria.
6. **`/dev-checkpoint`** — Save progress toward the goal.

Repeat the checkpoint → clear → resume cycle as needed.

## Commands

| Command | Writes Files? | Description |
|---------|:------------:|-------------|
| `/dev-bootstrap` | Yes | Initialize protocol, reconstruct state, no auto-commit |
| `/dev-checkpoint` | Yes | Persist state, validate, commit (fails on inconsistency) |
| `/dev-resume` | No | Recover context from state files (read-only) |
| `/dev-goal-template` | No | Generate a standardized goal template for `/goal` |
| `/dev-doctor` | No | Diagnose protocol health issues (read-only) |
| `/dev-help` | No | Quick usage reference |

Key guarantees:

- **State over history**: current file truth > appended logs
- **Fail-fast**: hard failure on corruption, soft failure on ambiguity
- **No partial commits**: checkpoint either fully succeeds or produces no commit
- **Self-drift detection**: repeated `/dev-checkpoint` with no real changes produces no commit

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

## Project Structure

```
.agents/dev-protocol/    State files (workflow-state.yml, handoff.md, project-rules.md, incidents.md)
.claude/skills/          Claude Code skill definitions (symlinks to skills/)
docs/                    Design documents, retrospective, onboarding guide
references/              Protocol reference rules (commit, failure, sync, memory, workflow, incidents)
skills/                  Skill definitions (PROMPT.md, SKILL.md per command)
templates/               State file templates for new projects
tests/                   Test cases and plans
```

For detailed design documents, see `docs/`. For protocol rules, see `references/`.
For onboarding a new project, see `docs/onboarding.md`.
