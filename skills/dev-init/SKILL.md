# /dev-init

## Purpose

Initialize dev-protocol v2 on any project through repository discovery and reality reconstruction.

Goal:

Convert a project into a recoverable development state without destroying existing work.

After init, the project must support:

- /dev-scope
- /dev-save
- /dev-status
- safe context reset

---

## When to Use

- First time adopting dev-protocol on a project
- After cloning a repository that lacks `.agents/dev-protocol/`
- State files are missing or corrupted
- After accidentally deleting `.agents/dev-protocol/`

---

## When NOT to Use

- `.agents/dev-protocol/` already exists and appears current (use `/dev-status` instead)
- You want to save progress (use `/dev-save` instead)
- You want to recover context after `/clear` (use `/dev-status` instead)
- You want to declare a goal (use `/dev-scope` instead)

---

## What It Does

Inspects the repository and reconstructs project reality, then creates state files in `.agents/dev-protocol/`:

- `workflow-state.yml` — machine-readable progress
- `handoff.md` — human-readable session handoff
- `project-rules.md` — project constraints

Does NOT auto-commit. Does NOT modify existing code. Does NOT stage files.

**Important**: Init is detect + recommend, NOT detect + mutate.

---

## Typical Workflow

```
# Fresh or existing project
/dev-init
→ review generated state files
→ git add .agents/
→ git commit -m "chore(protocol): initialize dev-protocol"
→ /dev-scope
```

---

## Responsibilities

### 1. Discover Git State

Must inspect:

- git initialized / uninitialized
- working tree clean / dirty
- current branch
- untracked files
- recent commit context (last 20 commits)

Must NOT rely on assumptions.

### 2. Assess Repository Maturity

Classify the repository into one of:

- **empty repo** — git initialized, no commits or nearly empty
- **early repo** — few commits, minimal structure, likely p1 phase
- **active repo** — regular commits, visible structure, mid-phase
- **mature repo** — rich history, docs, tests, CI, late phase

### 3. Detect Existing Protocol State

Check for `.agents/dev-protocol/`:

- If exists and contains valid state files → redirect to `/dev-status`
- If missing or empty → proceed with initialization
- If `.agent/dev-protocol/` exists (legacy v1) → note migration opportunity

### 4. Discover Project Context

Inspect:

- README.md
- docs/ directory
- CLAUDE.md, AGENTS.md
- architecture/design documents
- task/todo sources
- CI/CD configs
- build scripts
- dependency manifests
- runtime conventions

### 5. Detect Active Work

Identify:

- modified files
- ongoing branches
- obvious unfinished work (outstanding tasks, fix markers)

### 6. Define Deterministic Behavior

Four scenarios with explicit behavior:

| Scenario | Behavior |
|---|---|
| A. No git repo | Explain required setup. No destructive actions. |
| B. Git repo + clean + no protocol state | First-time initialization path. Generate state files. |
| C. Git repo + dirty + no protocol state | Safe onboarding path. Preserve current work. Generate state reflecting dirty workspace. |
| D. Existing `.agents/dev-protocol` | Redirect to `/dev-status`. Avoid accidental re-bootstrap. |

### 7. Generate State Files

Create or update in `.agents/dev-protocol/`:

- workflow-state.yml
- handoff.md
- project-rules.md

Rules:

- Never mutate source code
- Never auto-commit
- Never stage files
- Never overwrite existing state without explicit reason
- Prefer reality over history
- `checkpoint.last_commit` MUST be left empty/absent — no checkpoint baseline exists until first `/dev-save`

### 8. Review Before Commit

Init MUST NOT auto commit.

Agent must:

- summarize discoveries
- show generated state
- request review
- recommend next step

---

## Failure Rules

Init fails if:

- repository cannot be inspected
- project structure is unreadable
- state reconstruction confidence is too low
- existing protocol state detected but user did not acknowledge redirect
