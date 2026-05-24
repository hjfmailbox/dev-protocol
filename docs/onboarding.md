# Real-Project Onboarding Guide

How to adopt dev-protocol in existing repositories.

---

## Prerequisites

- Claude Code installed and configured
- Repository accessible locally
- Basic familiarity with dev-protocol commands (`/dev-help` for reference)

---

## Scenario 1: Fresh Repository (No Commits)

```bash
mkdir my-project && cd my-project
git init
# Add initial files...
git add . && git commit -m "initial commit"
```

Then in Claude Code:

```
/dev-bootstrap
```

Bootstrap will:

- Detect project structure
- Create `.agents/dev-protocol/` with state files
- NOT auto-commit (you review and commit manually)

After reviewing:

```bash
git add .agents/
git commit -m "chore(protocol): initialize dev-protocol"
/dev-checkpoint
```

---

## Scenario 2: Existing Git Repository

```bash
cd existing-project
```

In Claude Code:

```
/dev-bootstrap
```

Bootstrap will:

- Scan git history, docs, code structure
- Reconstruct current development phase
- Create state files reflecting actual progress
- NOT auto-commit

Review the generated state, then:

```bash
git add .agents/
git commit -m "chore(protocol): initialize dev-protocol"
/dev-checkpoint
```

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
- [ ] `/dev-checkpoint` succeeded (one commit created)
- [ ] `/dev-resume` restores correct context after `/clear`
- [ ] `.agents/` is tracked in git (not in `.gitignore`)

---

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| `.agents/` accidentally gitignored | Remove from `.gitignore`, commit |
| Bootstrap on wrong branch | State files are branch-specific; re-bootstrap on correct branch |
| Skipping first checkpoint after bootstrap | Bootstrap creates state but no commit — always checkpoint after bootstrap |
| State files in wrong location | Must be in `.agents/dev-protocol/`, not root or `.agent/` |
| Running checkpoint before any commits | Make at least one commit before checkpoint |

---

## What Bootstrap Does NOT Do

- Does NOT auto-commit
- Does NOT modify existing code or docs
- Does NOT create branches
- Does NOT stash or reset changes
- Does NOT configure CI/CD
- Does NOT install dependencies

Bootstrap is **detect + recommend**, not detect + mutate.
