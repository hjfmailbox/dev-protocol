# Project Background

## What This Project Is

dev-protocol is a session-resilient development workflow protocol for AI-assisted development.

It defines a standardized way to:

- Persist development context across session boundaries
- Recover work state without chat history
- Structure development into scoped, validated, and saved loops
- Separate protocol state from project source code

The protocol is runtime-agnostic. It works with Claude Code, Cursor, Copilot, or manual workflows. The core is a set of conventions, state files, and validation rules — not a specific tool or framework.

## Why It Exists

AI-assisted development sessions lose all context when the chat is cleared or a new session starts. Decisions, progress, and next steps are trapped in conversation history.

dev-protocol solves this by writing state to files that live in the repository. Any fresh session can read these files and resume work immediately.

This problem was discovered during real-project use of AI coding assistants. The protocol emerged from repeated observation of:

- Session resets destroying development context
- Agents re-discovering project state on every new conversation
- No standardized way to declare "what was done" and "what is next"

## Mental Model

The protocol treats development as a cycle:

```
Init → Scope → Work → Save → Status → Scope → ...
```

Each step has a single responsibility:

- **Init** — Reconstruct project reality from the repository
- **Scope** — Declare what will be done and how to validate it
- **Work** — Implement changes within the declared scope
- **Save** — Persist protocol state to durable files
- **Status** — Recover context in a fresh session

State files are the single source of truth. Chat history is secondary.

## Repository Structure

```
.agents/dev-protocol/    Protocol state (workflow-state.yml, handoff.md, project-rules.md)
.claude/                 Claude Code adapter (hooks, settings, skill symlinks)
docs/                    Public documentation (onboarding, benchmarks, retrospectives)
references/              Protocol reference rules (workflow, memory, incidents)
skills/                  Canonical skill definitions (PROMPT.md, SKILL.md per command)
templates/               State file templates for new projects
tests/                   Validation suite (case-05, case-06)
scripts/                 Deterministic tooling (fix-goal-output, debug diagnostics)
```

Key boundary:

- `skills/` = canonical protocol runtime definitions
- `.claude/` = optional Claude Code adapter
- `.agents/` = project-local state

`.claude/skills/` contains only symlinks pointing to `skills/`. The canonical source is always `skills/`.

## Runtime Model

The protocol core contains no runtime-specific logic. It works through files and scripts.

Runtime adapters provide convenience automation:

- **Claude Code** — `.claude/` directory with hooks and skill symlinks
- **Cursor** — Manual workflow or future plugin
- **Copilot** — Manual workflow or future extension
- **Manual** — Direct script invocation

Removing `.claude/` does not break protocol correctness. The protocol functions through direct file operations.

## Expected Workflow

A typical session:

1. Start a new session (or `/clear`)
2. Run `/dev-status` to recover context
3. Review `handoff.md` for current focus and blockers
4. Run `/dev-scope` to declare the next objective
5. Implement changes (normal git commits during work)
6. Run `case-06` validation
7. Run `/dev-save` to persist protocol state
8. Run `case-05` validation

Next session begins at step 2.

Validation order is strict:

```
Scope → Work → case-06 → Save → case-05
```

Running case-05 before case-06 produces false failures because `/dev-save` changes HEAD.

## What This Project Is NOT

- **Not a code generator** — The protocol does not write project code
- **Not a build system** — No compilation, packaging, or deployment logic
- **Not a version control system** — Git handles history; dev-protocol handles context
- **Not a project management tool** — No tickets, sprints, or resource allocation
- **Not multi-agent** — v2 remains single-agent only
- **Not auto-repair** — Detects drift but does not auto-fix
- **Not a framework** — No required dependencies or runtime installation

## Current Direction

The protocol is in stabilization phase.

v2 command surface is frozen: `/dev-init`, `/dev-scope`, `/dev-save`, `/dev-status`.

v1 commands are deprecated with aliases.

Current work focuses on:

1. **Stabilization** — Harden onboarding, fix state reconciliation, document command contracts
2. **Ergonomics** — Reduce workflow friction, support optional arguments, improve phase recovery
3. **Long-running robustness** — Deterministic replay, stale task cleanup, constants audit

See `.agents/dev-protocol/docs/deferred-improvements.md` for active backlog.
See `docs/v2-redesign-roadmap.md` (or active roadmap file) for phase details.
