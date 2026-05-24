# /dev-help

## Purpose

Quick usage reference for dev-protocol commands and workflow.

Goal:

Provide immediate, actionable guidance without reading full documentation.

---

## When to Use

- New to dev-protocol and need orientation
- Forgot command order or lifecycle
- Unsure which command to run next
- Encountering unexpected behavior

---

## When NOT to Use

- You need to execute a command (use the command directly)
- You need deep design rationale (read docs/ or references/)
- You need to diagnose a specific problem (use `/dev-doctor`)

---

## What It Does

Displays a concise reference covering:

- Command overview with one-line descriptions
- Typical lifecycle and command order
- Common mistakes and how to avoid them
- When to use each command

---

## Typical Workflow

```
/dev-help
→ read output
→ proceed with appropriate command
```

---

## Responsibilities

### 1. Display Command Reference

Output the following sections:

---

#### Commands

| Command | Writes Files? | Purpose |
|---------|:------------:|---------|
| `/dev-bootstrap` | Yes | Initialize protocol, reconstruct state from project. No auto-commit. |
| `/dev-checkpoint` | Yes | Persist state, validate consistency, commit. Safe to /clear after. |
| `/dev-resume` | No | Recover context from state files. Read-only. |
| `/dev-goal-template` | No | Generate a goal template for `/goal` usage. |
| `/dev-doctor` | No | Diagnose protocol health issues. Read-only. |
| `/dev-help` | No | This reference. |

---

#### Typical Lifecycle

```
First time on a project:
  /dev-bootstrap → review → git commit → /dev-checkpoint

Daily workflow:
  /dev-resume → /goal <task> → implement → /dev-checkpoint → /clear

Recovery:
  /clear → /dev-resume → continue
```

---

#### Command Order Rules

1. `/dev-bootstrap` runs FIRST on any new project
2. `/dev-checkpoint` requires a clean or consistent state
3. `/dev-resume` requires existing state files (from bootstrap or checkpoint)
4. `/goal` should be set AFTER resume, BEFORE implementation
5. `/dev-checkpoint` should run AFTER meaningful changes

---

#### Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running `/dev-checkpoint` without prior `/dev-bootstrap` | Run `/dev-bootstrap` first |
| Running `/dev-resume` on a project without state files | Run `/dev-bootstrap` first |
| `/dev-checkpoint` creates no commit (self-drift) | Normal — no changes since last checkpoint |
| Dirty workspace during `/dev-checkpoint` | Commit or stash changes first, or let checkpoint handle it |
| Forgetting `/dev-checkpoint` before `/clear` | Run `/dev-resume` to recover, but uncheckpointed work may be lost |
| Running `/dev-bootstrap` on an already-initialized project | Safe — it will update state, not overwrite |

---

#### State Files Location

All state lives in `.agents/dev-protocol/`:

| File | Purpose |
|------|---------|
| `workflow-state.yml` | Machine-readable progress and checkpoint metadata |
| `handoff.md` | Human-readable session handoff |
| `project-rules.md` | Project-specific constraints and pitfalls |

---

#### Getting Help

- `/dev-doctor` — diagnose protocol health issues
- `docs/` — detailed design documents
- `references/` — protocol reference rules
- `README.md` — project overview and setup

---

## Failure Rules

`/dev-help` should never fail. If it does, output:

"Unable to display help. Check that skill files exist in skills/dev-help/"
