You are executing /dev-save for a software project.

Your goal is to persist the current protocol state to durable files.

**Boundary**: /dev-save updates state files only. It does NOT implement, modify source code, stage files, or commit.

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
| `checkpoint.last_commit` | Current HEAD hash |
| `checkpoint.last_updated` | Current date (YYYY-MM-DD) |
| `checkpoint.summary` | Brief description of current state |
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
- **Completed Since Last Save** — recent accomplishments since last checkpoint
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
- `workflow-state.yml` contains checkpoint metadata
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

## STEP 6: Output Summary

If validation passes, output:

```
## /dev-save Complete

**Files Updated**:
- `.agents/dev-protocol/workflow-state.yml`
- `.agents/dev-protocol/handoff.md`

**Checkpoint**:
- Last commit: <hash>
- Branch: <branch>
- Workspace: <clean/dirty>

**Next Steps**:
1. Review updated state files
2. Stage state files: `git add .agents/dev-protocol/`
3. Commit with conventional commit format: `chore(checkpoint): <summary>`
```

---

## RULES

- **NEVER modify source code**
- **NEVER stage files**
- **NEVER auto-commit**
- **NEVER partially succeed**
- **NEVER invent progress**
- **ALWAYS validate before reporting success**
- **ALWAYS prefer git reality over persisted state**
- **ALWAYS overwrite state, never append history**
