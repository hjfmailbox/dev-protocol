# Command Contracts

Machine-actionable contracts for all `/dev-*` commands.

Each contract defines exact preconditions, outputs, failure modes, and recovery paths.

---

## /dev-status

### Purpose

Inspect current protocol state and reconstruct development context without chat history.

Read-only. Never modifies files.

### When To Use

- At the start of any new session (after `/clear`, new day, different machine)
- After switching branches
- When unsure of current project state
- Before declaring a new scope
- After resuming from an interruption

### Preconditions

- Git repository is initialized
- `.agents/dev-protocol/` may or may not exist

### Must NOT Use When

- No state files exist yet (use `/dev-init` instead)
- You want to save progress (use `/dev-save` instead)
- You want to declare a goal (use `/dev-scope` instead)
- State files are known to be corrupted (use `/dev-init` to reconstruct)

### Inputs

None. /dev-status is a no-argument command.

### Expected Outputs

**Summary block**:

```
## /dev-status Summary

**Current Phase**: <phase> <drift note if any>
**Focus**: <focus>
**Branch**: <current branch>
**Workspace**: <clean/dirty + details>
**Drift**: <none/low/high> — <specifics>
**Confidence**: <high/medium/low>

**Active Work**:
- <in-progress tasks or "none">

**Blockers**:
- <blockers or "none">

**Recommended Next Action**:
- <concrete next step>
```

**Drift classification rules**:

| Severity | Condition |
|---|---|
| **none** | All checks pass, including commit-type check |
| **low** | Minor mismatch (focus wording outdated, one task status mismatch) |
| **high** | Major mismatch (phase wrong, workspace claim contradicts git status, unrecorded non-protocol commits) |

**Protocol commit detection** (for commit-type drift check):

A commit is a protocol commit if ANY of the following hold:

| Pattern | Example |
|---|---|
| `chore(checkpoint):*` | `chore(checkpoint): sync state after auth goal` |
| `chore(protocol):*` | `chore(protocol): initialize dev-protocol` |
| `chore(state):*` | `chore(state): update focus and progress` |
| Contains "sync state" AND only `.agents/` files changed | Semantic protocol persistence |
| Contains "protocol" AND only `.agents/` or `docs/` files changed | Semantic protocol maintenance |

**Checkpoint meaning**:

- `checkpoint.last_commit` in `workflow-state.yml` records the baseline commit hash
- When `checkpoint.last_commit` == HEAD: state is current
- When `checkpoint.last_commit` != HEAD: inspect intermediate commits
- If ALL intermediate commits are protocol commits: drift = none
- If ANY intermediate commit is NOT a protocol commit: drift = high

**Git reality precedence**:

```
git reality (git status, git log) > explicit docs (README, CLAUDE.md) > protocol state (workflow-state.yml) > assumptions
```

### Failure Modes

| Mode | Cause | Output |
|---|---|---|
| Missing state | `.agents/dev-protocol/` does not exist | "State files not found. Run /dev-init to initialize." |
| Corrupted repository | `git status` fails | "Repository corrupted. Verify git installation and repository integrity." |
| Severe inconsistency | State contradicts git reality beyond recovery | Drift = high + recommend `/dev-init` |

### Recovery

- Missing state → run `/dev-init`
- Corrupted repository → fix git repository externally
- Severe inconsistency → run `/dev-init` to refresh state, or manually reconcile

### Examples

```
# Fresh session
/dev-status
→ Current Phase: p3 — no drift
→ Focus: dev-status protocol commit detection
→ Workspace: clean
→ Drift: none
→ Recommended Next Action: continue current work or declare new scope

# After source commits without /dev-save
/dev-status
→ Drift: high — unrecorded commits detected since last checkpoint
→ Recommended Next Action: run /dev-save to capture current state
```

---

## /dev-save

### Purpose

Persist protocol state to durable files and create a protocol commit automatically.

Updates `.agents/dev-protocol/workflow-state.yml` and `.agents/dev-protocol/handoff.md`.

### When To Use

- After completing meaningful work within a scoped goal
- Before starting a new session
- When protocol state is stale relative to repository reality
- After `/dev-status` reveals drift that needs recording

### Preconditions

- `.agents/dev-protocol/workflow-state.yml` exists
- `.agents/dev-protocol/handoff.md` exists
- Git repository is initialized
- `git rev-parse HEAD` succeeds

### Must NOT Use When

- No state files exist yet (use `/dev-init` first)
- Workspace has uncommitted source code changes that should be committed first
- You want to declare a new goal (use `/dev-scope` instead)
- You want to inspect state (use `/dev-status` instead)

### Inputs

None. /dev-save is currently a no-argument command.

**Future**: optional arguments may be supported (deferred D03):
- `/dev-save "loop 5 undo implementation"`
- `/dev-save --summary="loop 5"`
- `/dev-save --type=checkpoint`

### Expected Outputs

**Success block**:

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

**Dirty workspace behavior**:

- /dev-save does NOT stage or commit non-protocol files
- If workspace has uncommitted source changes, /dev-save still proceeds
- Protocol commit contains ONLY `.agents/dev-protocol/*` changes
- Source changes remain unstaged/uncommitted
- Output must note: "Non-protocol files modified but not staged"

**Protocol commit vs source commit distinction**:

| Aspect | Protocol Commit | Source Commit |
|---|---|---|
| Created by | `/dev-save` | Normal `git commit` during work |
| Contains | `.agents/dev-protocol/*` only | Source code, tests, docs, config |
| Message prefix | `chore(checkpoint):` | `feat:`, `fix:`, `docs:`, `test:`, `refactor:` |
| When | After completing scope work | During implementation |
| Purpose | Persist protocol state | Record actual code changes |

**When source must be committed first**:

- Before running `/dev-save`, source changes SHOULD be committed if they represent completed work
- /dev-save does not enforce this; it only commits protocol state
- Recommended: commit source → run case-06 → run /dev-save → run case-05

**No-op save behavior**:

- If no meaningful changes exist since last checkpoint (only protocol files modified by manual edits):
  - Self-drift detection: compare `last_commit..HEAD` diff
  - If diff includes only state files: classify as NONE, early exit
  - No redundant commit created
- If workspace is completely clean and state files unchanged:
  - Report: "No meaningful changes detected. State is current."
  - No commit created

**Save success meaning**:

- Protocol state is now persisted to git history
- Fresh session can recover context by reading state files
- `checkpoint.last_commit` updated to current HEAD
- Workspace may still contain uncommitted source changes

### Failure Modes

| Mode | Cause | Output |
|---|---|---|
| Missing state | State files do not exist | "State files not found. Run /dev-init to initialize." |
| Validation fail | `workflow-state.yml` invalid or required fields missing | Specific failure + recommendation |
| Recoverability fail | Fresh session cannot reconstruct context from state | Specific failure + recommendation |
| Git error | `git commit` fails | Specific git error + recommendation |

### Recovery

- Missing state → run `/dev-init`
- Validation fail → fix state files manually or run `/dev-init`
- Recoverability fail → enrich state files with more context
- Git error → resolve git conflict or repository issue externally

### Examples

```
# After completing goal work
/dev-save
→ Files Updated: workflow-state.yml, handoff.md
→ Protocol Commit: chore(checkpoint): sync state after auth goal (abc1234)
→ Workspace: clean
→ Next: start new session with /dev-status

# With uncommitted source changes
/dev-save
→ Files Updated: workflow-state.yml, handoff.md
→ Protocol Commit: chore(checkpoint): sync state after api refactor (def5678)
→ Workspace: dirty (3 modified files not staged)
→ Warning: non-protocol files remain uncommitted
→ Next: commit source changes before new session

# No-op save
/dev-save
→ No meaningful changes detected. State is current.
→ No commit created.
```

---

## /dev-scope

### Purpose

Declare a focused, bounded goal with validation criteria.

Convert user intent into an explicit scoped objective that an agent can execute without ambiguity.

### When To Use

- Before starting any implementation work
- When a task feels too large or ambiguous
- After `/dev-status` reveals the project is ready for new work
- When user provides a vague request that needs structure

### Preconditions

- Git repository is initialized
- Project state is known (run `/dev-status` first if unsure)

### Must NOT Use When

- The goal is already fully specified by the user
- Simple single-file changes with obvious scope
- Exploration or research without concrete deliverables
- You want to save progress (use `/dev-save` instead)
- You want to inspect state (use `/dev-status` instead)

### Inputs

User intent: brief description of what to accomplish.

If no description provided, prompt:
"What would you like to accomplish? Provide a brief description."

### Expected Outputs

**Structured scope document**:

```
## Goal

<one-sentence objective>

## Scope

### In-scope
- <specific file, directory, or behavior>
- ...

### Out-of-scope
- <specific exclusion>
- ...

## Requirements
1. <concrete requirement>
2. <concrete requirement>
...

## Non-goals
- <what this goal does NOT cover>
- ...

## Validation
1. <machine-checkable criterion>
2. <machine-checkable criterion>
...
```

**Ambiguity detection**:

STOP and ask clarifying questions if:
- Vague verbs ("improve," "optimize," "clean up")
- No file or module mentioned
- Multiple unrelated changes in one sentence
- Missing validation criteria
- Scope would affect more than 10 files

**Scope size guidance**:

| Size | Guidance |
|---|---|
| Small (1–3 files) | Ideal. Prefer this. |
| Medium (4–7 files) | Acceptable if tightly related. |
| Large (8+ files) | Must decompose. Suggest splitting. |

### Failure Modes

| Mode | Cause | Output |
|---|---|---|
| Empty intent | No description provided | Prompt for description |
| Ambiguous intent | Cannot determine boundaries | Ask 1–3 clarifying questions |
| Missing validation | No criteria defined | Require validation criteria |
| Scope too large | > 10 files or ambiguous breadth | Suggest decomposition |

### Recovery

- Empty intent → provide description
- Ambiguous intent → answer clarifying questions
- Missing validation → define criteria
- Scope too large → split into smaller scopes

### Examples

```
# Clear intent
/dev-scope "Add user authentication to API"
→ Goal: Add user authentication to API endpoints
→ In-scope: src/auth.py, tests/test_auth.py, docs/api.md
→ Out-of-scope: frontend changes, database migration, OAuth integration
→ Validation: case-06 passes, tests cover login/logout/validate

# Ambiguous intent
/dev-scope "Improve performance"
→ STOP
→ "Which specific endpoints or operations should be optimized?"
→ "What metric defines 'improved' — latency, throughput, or resource usage?"
→ "Should this include profiling infrastructure or only code changes?"
```

---

## /goal

### Purpose

Execute a scoped objective within the boundaries defined by `/dev-scope`.

/goal is the implementation phase. It consumes the scope document and produces code changes.

### When To Use

- After `/dev-scope` has produced a validated scope document
- When the scope boundaries are clear and agreed upon
- For concrete implementation work within defined constraints

### Preconditions

- `/dev-scope` has produced a scope document
- Scope boundaries are confirmed
- Workspace is in a known state (run `/dev-status` if unsure)

### Must NOT Use When

- Scope is ambiguous or not yet defined (run `/dev-scope` first)
- You want to save progress (use `/dev-save` instead)
- You want to inspect state (use `/dev-status` instead)
- You want to initialize protocol (use `/dev-init` instead)

### Inputs

Scope document from `/dev-scope`:
- Goal statement
- In-scope / out-of-scope boundaries
- Numbered requirements
- Validation criteria

### Expected Outputs

**Implementation results**:

- Code changes within scope boundaries
- Normal git commits during work (not protocol commits)
- goal-output.json or goal-output.md artifact in `.agents/dev-protocol/`

**goal-output artifact** (required for case-06 validation):

```json
{
  "goal_status": "COMPLETED | PARTIALLY_COMPLETED | BLOCKED | FAILED | ABORTED",
  "goal_summary": "one-sentence summary",
  "changed_files": ["file1", "file2"],
  "validation_results": "...",
  "stop_reason": "...",
  "risks_followups": "...",
  "continuation_handoff": {
    "context": "...",
    "boundary": "...",
    "next_candidate_goal": "...",
    "prompt_seed": "..."
  }
}
```

**changed_files rule**:

- MUST be derived from `git diff-tree --no-commit-id --name-only -r HEAD`
- MUST match actual files in the goal commit
- MUST NOT be invented or guessed

### Failure Modes

| Mode | Cause | Output |
|---|---|---|
| Scope violation | Changes exceed defined boundaries | STOP, report violation, recommend new scope |
| Validation fail | Criteria not met | Report failures, recommend fix scope |
| Blocked | External dependency prevents completion | goal_status: BLOCKED + specific blocker |
| No changes | Goal completes without file modifications | goal_status: COMPLETED + note no changes |

### Recovery

- Scope violation → run new `/dev-scope` for additional work
- Validation fail → fix within current scope or re-scope
- Blocked → document blocker, run `/dev-save`, resolve externally
- No changes → still produce goal-output artifact, run `/dev-save`

### Examples

```
# Standard implementation
/goal <scope from /dev-scope>
→ implements changes
→ git commit -m "feat(api): add user authentication"
→ goal-output.json created
→ case-06 validation passes
→ /dev-save

# No-op goal
/goal <scope from /dev-scope>
→ behavior already correct, no changes needed
→ goal-output.json created with goal_status: COMPLETED
→ case-06 validation passes (with no changes)
→ /dev-save
```

---

## Command Relationship Map

```
/dev-init     → first contact, creates state
   ↓
/dev-status   → inspect state (read-only)
   ↓
/dev-scope    → declare goal
   ↓
/goal         → implement within scope
   ↓ (commit source)
case-06       → validate goal commit
   ↓
/dev-save     → persist protocol state
   ↓
case-05       → validate checkpoint
   ↓
/dev-status   → inspect updated state
```

**Key rule**: /dev-save NEVER commits source code. Source commits happen during /goal.

**Key rule**: /dev-status NEVER modifies anything. It is strictly read-only.

**Key rule**: /dev-scope NEVER implements anything. It only declares intent.
