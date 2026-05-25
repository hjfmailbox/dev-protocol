# /dev-init

## Purpose

Initialize dev-protocol v2 on any project through repository discovery and safe onboarding.

Goal:

Convert a project into a recoverable development state without destroying existing work.

After init, the project must support:

- /dev-scope
- /dev-save
- /dev-status
- safe context reset

**Boundary rule**: /dev-init is onboarding, not project analysis. It stops at reconstructing repository reality. It does NOT perform deep architecture reasoning, implementation planning, business/domain analysis, or design conclusion generation.

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

Inspects the repository and reconstructs basic project reality, then creates minimal state files in `.agents/dev-protocol/`:

- `workflow-state.yml` — machine-readable progress
- `handoff.md` — human-readable session handoff
- `project-rules.md` — minimal project constraints (never invented)

Does NOT auto-commit. Does NOT modify existing code. Does NOT stage files.

**Important**: Init is detect + recommend, NOT detect + mutate.
**Important**: Init is onboarding, NOT project analysis. Stop at "knowing the project reality," not "understanding how the project works."

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

### 2. Assess Repository Maturity (Confidence Only)

Classify the repository into one of:

- **empty repo** — git initialized, no commits or nearly empty
- **early repo** — few commits, minimal structure forming
- **active repo** — regular commits, visible structure
- **mature repo** — rich history, docs, tests, CI

This classification is for confidence calibration only. It MUST NOT be used to infer `phase`. The generated `workflow-state.yml` always uses `phase: unknown`.

### 3. Detect Existing Protocol State

Check for `.agents/dev-protocol/`:

- If exists and contains valid state files → recommend `/dev-status`, STOP without overwriting
- If missing or empty → proceed with initialization
- If `.agent/dev-protocol/` exists (legacy v1) → note migration opportunity

**Never hard-redirect.** Always present as recommendation with rationale. Preserve no-overwrite, no-mutation guarantees.

### 4. Discover Project Context (High-Level Only)

Inspect top-level sources only. Gather surface facts, not deep understanding.

Allowed:

- README.md (purpose, setup — not architecture conclusions)
- docs/ directory (existence and top-level structure only)
- CLAUDE.md, AGENTS.md (runtime conventions)
- dependency manifests (language/framework indicators)
- CI/CD configs (presence only)
- build/test tooling (presence only)

Forbidden:

- Deep source code reading
- Architecture inference beyond explicit docs
- Implementation recommendations
- Generating project conclusions
- Business/domain analysis

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
| B. Git repo + clean + no protocol state | First-time initialization path. Auto-generate state files allowed. |
| C. Git repo + dirty + no protocol state | Safe onboarding path. Explain dirty state, recommend action, ask for confirmation before generating state. |
| D. Existing `.agents/dev-protocol` | Recommend `/dev-status`. Explain why re-init is unnecessary. STOP without overwriting. |

### 7. Generate State Files (Conditional)

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
- `phase` MUST be `unknown` until validated by user
- `project-rules.md` MUST NOT contain invented facts — use "Unknown / Requires Validation" for uncertain items

Confidence gating:

| Confidence | Auto-generate? | Action |
|---|---|---|
| High | Yes | Proceed with state generation |
| Medium | Yes | Proceed, note uncertainties in handoff |
| Low | No | STOP and ask for user confirmation before generating state |

Low-confidence signals:

- No README
- No docs/
- Ambiguous repo structure
- Dirty workspace
- Low discoverability

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
- state reconstruction confidence is too low (and user did not confirm)
- existing protocol state detected but user demands overwrite without acknowledging risk
