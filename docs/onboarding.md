# Real-Project Onboarding Guide

How to adopt dev-protocol in existing repositories.

**Runtime-agnostic**: This guide uses Claude Code as the reference runtime. If you use Cursor, GitHub Copilot, or manual workflows, the same steps apply using your runtime's interaction model. See [`runtime-integrations.md`](runtime-integrations.md) for non-Claude environments.

---

## Prerequisites

- AI assistant or manual workflow capable of reading/writing files and running shell commands
- Repository accessible locally
- Basic familiarity with dev-protocol operations (`/dev-help` in Claude Code, or read `references/workflow-rules.md`)

---

## Scenario 1: Fresh Repository (No Commits)

```bash
mkdir my-project && cd my-project
git init
# Add initial files...
git add . && git commit -m "initial commit"
```

Then bootstrap the protocol. In Claude Code:

```
/dev-bootstrap
```

Or manually: create `.agents/dev-protocol/workflow-state.yml`, `handoff.md`, and `project-rules.md` reflecting your project state.

Bootstrap will:

- Detect project structure
- Create `.agents/dev-protocol/` with state files
- NOT auto-commit (you review and commit manually)

After reviewing:

```bash
git add .agents/
git commit -m "chore(protocol): initialize dev-protocol"
```

Then checkpoint. In Claude Code: `/dev-checkpoint`. Or manually: update state files to reflect current progress and commit.

---

## Scenario 2: Existing Git Repository

```bash
cd existing-project
```

Then bootstrap. In Claude Code:

```
/dev-bootstrap
```

Or manually: inspect the project and create state files in `.agents/dev-protocol/`.

Bootstrap will:

- Scan git history, docs, code structure
- Reconstruct current development phase
- Create state files reflecting actual progress
- NOT auto-commit

Review the generated state, then:

```bash
git add .agents/
git commit -m "chore(protocol): initialize dev-protocol"
```

Then checkpoint. In Claude Code: `/dev-checkpoint`. Or manually: update state files and commit.

---

## Scenario 3: Dirty Workspace (Uncommitted Changes)

**Before bootstrap:**

dev-protocol does NOT auto-commit or auto-stash. If your workspace is dirty:

Option A — Commit first:
```bash
git add .
git commit -m "chore: save current progress"
/dev-bootstrap
```

Option B — Stash first:
```bash
git stash
/dev-bootstrap
git stash pop
```

Option C — Bootstrap with dirty workspace:
```
/dev-bootstrap
```

Bootstrap will report the dirty state and include it in the reconstructed context. The state files will reflect the dirty workspace as "in progress" work.

**Important**: `/dev-checkpoint` may fail or produce unexpected results on a dirty workspace. Commit or stash before checkpoint.

---

## Scenario 4: Untracked Files

Untracked files are visible to bootstrap and will be included in project inspection.

If untracked files are intentional (new feature, experiment):

```
/dev-bootstrap
```

Bootstrap will note untracked files in the reconstructed state.

If untracked files are artifacts (build output, temp files):

```bash
# Add to .gitignore first
echo "build/" >> .gitignore
echo "*.tmp" >> .gitignore
git add .gitignore
git commit -m "chore: update gitignore"
/dev-bootstrap
```

---

## Scenario 5: Existing Branches

dev-protocol works on the current branch. State files are branch-specific.

**On your working branch:**

```bash
git checkout feature-branch
```

```
/dev-bootstrap
```

State files will be created on `feature-branch`. When you switch branches:

```bash
git checkout main
# State files from feature-branch won't be here (unless merged)
```

**Recommendation**: Bootstrap on the branch you plan to work on. State files should be committed to that branch.

---

## Scenario 6: Missing Git Initialization

If the project directory is not a git repository:

```
/dev-bootstrap
```

Bootstrap will detect this and report:

```
ERROR: Not a git repository
Recommendation: Run `git init` and make an initial commit first
```

Fix:

```bash
git init
git add .
git commit -m "initial commit"
/dev-bootstrap
```

dev-protocol requires git. No git = no checkpoint = no recovery.

---

## Post-Onboarding Checklist

After bootstrap and first checkpoint:

- [ ] `.agents/dev-protocol/workflow-state.yml` exists and reflects project state
- [ ] `.agents/dev-protocol/handoff.md` exists with current focus
- [ ] `.agents/dev-protocol/project-rules.md` exists with project constraints
- [ ] Checkpoint succeeded (one commit created) — in Claude Code: `/dev-checkpoint`; manual: commit state files
- [ ] Resume restores correct context in a new session — in Claude Code: `/dev-resume`; manual: read `handoff.md`
- [ ] `.agents/` is tracked in git (not in `.gitignore`)

---

## Manual Fallback Workflow (No Hooks)

If your runtime does not support hooks or slash commands, use this manual workflow:

1. **Bootstrap**: Create `.agents/dev-protocol/` state files manually or with a script.
2. **Goal work**: Implement changes within a written scope.
3. **Normalize**: Before completing a goal, always run:
   ```powershell
   pwsh scripts/fix-goal-output.ps1
   ```
4. **Validate**: Run case-06:
   ```powershell
   pwsh tests/run-tests.ps1 -Case 06
   ```
5. **Checkpoint**: Commit state files and changes:
   ```bash
   git add .
   git commit -m "chore(checkpoint): describe change"
   ```
6. **Resume**: In a new session, read `.agents/dev-protocol/handoff.md` to recover context.

The only difference from hook mode is that normalization and validation are triggered manually instead of automatically. The protocol behavior is identical.

---

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| `.agents/` accidentally gitignored | Remove from `.gitignore`, commit |
| Bootstrap on wrong branch | State files are branch-specific; re-bootstrap on correct branch |
| Skipping first checkpoint after bootstrap | Bootstrap creates state but no commit — always checkpoint after bootstrap |
| State files in wrong location | Must be in `.agents/dev-protocol/`, not root or `.agent/` |
| Running checkpoint before any commits | Make at least one commit before checkpoint |
| Forgetting to run `fix-goal-output.ps1` before goal completion | Add it to your checklist, or use a runtime with hook support |

---

## What Bootstrap Does NOT Do

- Does NOT auto-commit
- Does NOT modify existing code or docs
- Does NOT create branches
- Does NOT stash or reset changes
- Does NOT configure CI/CD
- Does NOT install dependencies
- Does NOT require any specific AI runtime

Bootstrap is **detect + recommend**, not detect + mutate.
