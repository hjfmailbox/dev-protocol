You are executing /dev-save for a software project.

Your goal is to persist the current protocol state to durable files and commit them automatically.

**Boundary**: /dev-save updates state files, stages them, and creates a protocol commit. It does NOT modify source code, stage non-protocol files, or ask for confirmation.

---

## STEP 0: Reality Priority

When sources conflict, this hierarchy wins:

```
Git reality (git status, git log) > Explicit docs (README, CLAUDE.md) > Protocol state (workflow-state.yml) > Assumptions
```

Never trust assumptions over observable reality.

---

## STEP 1: Validate Preconditions

Verify state files exist:

- `.agents/dev-protocol/workflow-state.yml`
- `.agents/dev-protocol/handoff.md`

If missing:

STOP. Output: "State files not found. Run /dev-init to initialize."

Also verify:

- Git repository is initialized (`git rev-parse HEAD` succeeds)

---

## STEP 2: Inspect Repository Reality

Collect:

- `git rev-parse HEAD` — current commit hash
- `git status --short` — workspace state
- `git branch --show-current` — current branch

Rules:

- Use actual git output. Never assume `main` or any branch name.
- Record dirty/clean state accurately.
- Note untracked files.

---

## STEP 3: Update workflow-state.yml

Read existing `.agents/dev-protocol/workflow-state.yml`.

Update these fields to reflect current reality:

| Field | Value |
|---|---|
| `checkpoint.last_commit` | Current HEAD hash (save tracking) |
| `checkpoint.last_updated` | Current date (YYYY-MM-DD) (save tracking) |
| `checkpoint.summary` | Brief description of current state (save tracking) |
| `current_state.focus` | Current work focus |
| `progress.in_progress` | Currently active tasks (array) |
| `progress.blocked` | Blocked tasks (array) |

Rules:

- MUST NOT append history
- MUST overwrite outdated state
- MUST NOT invent progress not reflected in reality
- MUST leave `confidence` and other fields intact unless they changed

---

## STEP 4: Update handoff.md

Read existing `.agents/dev-protocol/handoff.md`.

Update sections to reflect current reality:

- **Current Focus** — what is actively being worked on
- **Current Status** — active, blocked, waiting
- **Completed Since Last Save** — recent accomplishments since last state update
- **In Progress** — ongoing tasks
- **Blockers** — anything preventing progress
- **Next Recommended Actions** — 1-3 concrete next steps
- **Notes For Next Session** — critical context a fresh session needs

Rules:

- MUST reflect current truth, not planned future state
- MUST NOT append logs — overwrite sections
- If no blockers, write "none"
- If no in-progress work, write "none"

---

## STEP 5: Validate State Consistency

Before considering save complete, validate:

### 5.1 Structural validation

- `workflow-state.yml` is valid YAML
- Required top-level keys exist: `version`, `project`, `current_state`, `progress`, `checkpoint`
- `checkpoint.last_commit` is a non-empty string resembling a commit hash
- `checkpoint.last_updated` matches YYYY-MM-DD format

### 5.2 Content validation

- `current_state.phase` is not empty
- `current_state.focus` is not empty
- `handoff.md` has all required sections

### 5.3 Recoverability validation

Simulate: "Can /dev-status reconstruct meaningful context from these files?"

Required for recoverability:

- `handoff.md` contains Current Focus
- `workflow-state.yml` contains save-tracking metadata
- State is internally consistent (no contradictions between files)

If any validation fails:

STOP. Output:
```
## /dev-save FAILED

**Reason**: <specific failure>
**Recommendation**: <how to fix>
```

Do NOT report save as successful.

---

## STEP 6: Stage and Commit Protocol State

After validation passes, automatically persist the state files:

1. **Stage ONLY protocol state files**:
   ```bash
   git add .agents/dev-protocol/
   ```

2. **Create protocol commit** with conventional format:
   ```bash
   git commit -m "chore(checkpoint): sync state after <focus summary>"
   ```

   Rules for commit message:
   - MUST use `chore(checkpoint):` prefix
   - MUST describe current focus (e.g., "sync state after auth goal", "sync state after onboarding")
   - MUST NOT reuse the previous goal commit message
   - MUST NOT include source code changes

3. **Verify clean workspace**:
   - `git status --short` should show nothing staged and nothing modified in `.agents/`
   - If non-protocol files are modified, they were NOT staged (correct behavior)

---

## STEP 7: Output Summary

After successful commit, output:

```
## /dev-save Complete

**Files Updated**:
- `.agents/dev-protocol/workflow-state.yml`
- `.agents/dev-protocol/handoff.md`

**Protocol Commit**:
- Message: chore(checkpoint): sync state after <focus>
- Hash: <new-commit-hash>

**Git Context**:
- Last commit: <hash>
- Branch: <branch>
- Workspace: <clean/dirty>

**Next Steps**:
1. Continue working or start a new session with /dev-status
```

---

## RULES

- **NEVER modify source code**
- **NEVER stage non-protocol files**
- **NEVER ask for confirmation** — commit automatically
- **NEVER partially succeed**
- **NEVER invent progress**
- **ALWAYS validate before committing**
- **ALWAYS prefer git reality over persisted state**
- **ALWAYS overwrite state, never append history**
- **ALWAYS create a protocol commit** — do not leave modified state files unstaged
