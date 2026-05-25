# Onboarding Guide

How to start using dev-protocol in any project.

**Runtime-agnostic**: This guide uses Claude Code slash commands as examples. If you use Cursor, Copilot, or manual workflows, the same operations apply through your runtime's interaction model. See [`runtime-integrations.md`](runtime-integrations.md) for non-Claude environments.

---

## First-Contact Answer

> **我第一次接入真实项目时，第一步应该做什么？**
>
> 运行 `/dev-init`。它会检查你的项目，生成状态文件，然后你审阅、提交，就完成了初始化。

---

## Happy Path

The ideal first-contact flow. Use this when your project is already a git repository with a clean working tree.

```
Step 1: /dev-init          → Protocol inspects repository, reconstructs reality, creates .agents/dev-protocol/
Step 2: Review state files → Check workflow-state.yml, handoff.md, project-rules.md
Step 3: git add .agents/   → Track state files in git
Step 4: git commit         → chore(protocol): initialize dev-protocol
Step 5: /dev-scope         → Declare your first goal
Step 6: Work               → Implement changes (normal git commits during work)
Step 7: /dev-save          → Persist protocol state and commit state files
```

After Step 7, you can safely end the session. Next session: run `/dev-status` to resume.

**Important**: `/dev-save` does **not** replace normal development commits. During Step 6, you commit your code changes as usual (`git commit -m "feat: add feature"`). `/dev-save` only commits the protocol state files (`.agents/dev-protocol/*`) to record progress and context.

---

## Recovery Path

If the happy path does not match your situation, find your state below and follow the corresponding branch.

### No Git Repository

```bash
git init
git add .
git commit -m "initial commit"
/dev-init
```

dev-protocol requires git. Without git, there is no history to inspect and no way to checkpoint.

### Git Repository but Dirty Workspace

**Option A — Commit first (recommended):**
```bash
git add .
git commit -m "chore: save current progress"
/dev-init
```

**Option B — Stash first:**
```bash
git stash
/dev-init
git stash pop
```

**Option C — Init with dirty workspace:**
```
/dev-init
```

`/dev-init` will detect the dirty state and include it in reconstructed context. State files will reflect the dirty workspace as "in progress" work. You must clean the workspace before `/dev-save`.

### Existing `.agents/dev-protocol`

If the project already has dev-protocol state files:

```
/dev-status
```

Do not run `/dev-init`. `/dev-status` inspects existing state and reports whether it is current, stale, or broken. If stale, `/dev-status` recommends re-syncing. If missing, `/dev-status` recommends `/dev-init`.

### Existing Design Documents

If the project has `README.md`, `docs/`, `CLAUDE.md`, or architecture documents:

```
/dev-init
```

`/dev-init` inspects existing documents to estimate project maturity and phase. Review the generated `workflow-state.yml` to verify the estimated phase is accurate.

### No Design Documents

If the project has no documentation:

```
/dev-init
```

`/dev-init` estimates phase from git history depth and directory structure alone. The estimate may be conservative (p1). Update `workflow-state.yml` manually if you know the project is more mature.

---

## Normal Commits vs Protocol Saves

| Operation | What it commits | When to do it | Example message |
|---|---|---|---|
| Normal commit | Your code changes, docs, tests | During work, when a change is complete | `feat(api): add user authentication` |
| Protocol save | `.agents/dev-protocol/*` state files only | After completing a goal or at session end | `chore(checkpoint): sync state after auth goal` |

**Rule**: You make normal commits throughout your work. You make protocol saves only at boundaries (goal complete, session end, natural breakpoint). `/dev-save` never commits your source code — it only commits state files that record where you are and what is next.

---

## Command Reference

| Command | Purpose | When to Use |
|---|---|---|
| `/dev-init` | Inspect repository, reconstruct project reality, initialize protocol state | First contact, or after cloning a repo without `.agents/` |
| `/dev-scope` | Declare a focused goal with validation criteria | Before starting any implementation work |
| `/dev-save` | Persist protocol state files, validate consistency, commit state only | After completing a goal or at natural stopping points |
| `/dev-status` | Inspect current protocol state and reconstruct context | Every new session, or when unsure of current state |

**Deprecated v1 commands** (still work but print a deprecation warning):

| Deprecated | Replacement |
|---|---|
| `/dev-bootstrap` | `/dev-init` |
| `/dev-checkpoint` | `/dev-save` |
| `/dev-resume` | `/dev-status` |
| `/dev-doctor` | `/dev-status --diagnose` |
| `/dev-help` | `/dev-status --help` |
| `/dev-goal-template` | `/dev-scope` (template built-in) |
| `/goal` | `/dev-scope` |

---

## Validation Order

After goal work, validate in this exact order:

```
/dev-scope → work → case-06 → /dev-save → case-05
```

1. **After `/dev-scope` and work**: Run `pwsh tests/run-tests.ps1 -Case 06` to verify the goal commit and artifact are valid.
2. **After `/dev-save`**: Run `pwsh tests/run-tests.ps1 -Case 05` to verify the checkpoint commit and state consistency.

Running `case-05` before `case-06` will fail because `/dev-save` changes HEAD to a checkpoint commit, invalidating the goal artifact checks in `case-06`.

---

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| `.agents/` accidentally gitignored | Remove from `.gitignore`, commit |
| Running `/dev-init` on a project that already has `.agents/` | Run `/dev-status` instead |
| Skipping first `/dev-save` after `/dev-init` | `/dev-init` creates state but no commit — always `/dev-save` after init |
| Running `case-06` after `/dev-save` | `case-06` must run before `/dev-save`; `case-05` runs after |
| Forgetting to run `fix-goal-output.ps1` before goal completion | Run `pwsh scripts/fix-goal-output.ps1` after writing goal-output, before `case-06` |
| State files in wrong location | Must be in `.agents/dev-protocol/`, not root or `.agent/` |

---

## What `/dev-init` Does NOT Do

- Does NOT auto-commit
- Does NOT modify existing code or docs
- Does NOT create branches
- Does NOT stash or reset changes
- Does NOT configure CI/CD
- Does NOT install dependencies
- Does NOT require any specific AI runtime

``/dev-init` performs full repository discovery and project reality reconstruction. It does not simply create files. It inspects:

- **Git history** — commit depth, branching patterns, recent activity
- **Architecture/design documents** — `README.md`, `docs/`, `CLAUDE.md`, `AGENTS.md`, architecture diagrams
- **Active work** — uncommitted changes, open branches, outstanding tasks, fix markers in code
- **Repository maturity** — directory structure (`src/`, `tests/`, `lib/`), file count, dependency manifests
- **Existing workflows** — CI/CD configs, build scripts, lint rules
- **Project type** — language indicators, framework signatures

`/dev-init` is **detect + recommend**, not detect + mutate.

---

## `.agents` Directory Convention

`.agents/dev-protocol/` is the runtime directory for dev-protocol state.

**Why `.agents` (plural)?**

- Aligns with multi-agent ecosystem conventions
- Enables shared skill discovery across different AI runtimes
- Distinguishes from single-runtime `.agent/` or `.claude/`

**Relationship to `.claude/`**

| Directory | Purpose | Content |
|---|---|---|
| `.agents/dev-protocol/` | Protocol state | `workflow-state.yml`, `handoff.md`, `project-rules.md` |
| `.claude/` | Claude Code runtime adapter | `settings.json`, hooks, skill symlinks |
| `.claude/skills/` | Claude auto-discovery | Symlinks to `skills/` only |
| `skills/` | Canonical skill definitions | `PROMPT.md`, `SKILL.md` per command |

**Rule**: `skills/` is the canonical source. `.claude/skills/` contains only symlinks. `.agents/dev-protocol/` contains only state files. No duplicated copies anywhere.

**Cross-agent compatibility**: `.agents/` is runtime-agnostic. Claude Code, Cursor, Copilot, or manual workflows all read and write the same `.agents/dev-protocol/` files. Runtime-specific configuration lives in `.claude/`, `.cursor/`, etc.
