# Command Contracts

Machine-actionable contracts for all `/dev-*` commands.

Each contract defines exact preconditions, outputs, failure modes, and recovery paths.

Agents must be able to read this document and deterministically decide:

- When to invoke a command
- What inputs to provide
- What side effects to expect
- How to recognize success vs failure

---

## /dev-init

### Purpose

Initialize dev-protocol state on a project through repository discovery and safe onboarding.

### When to use

- First time adopting dev-protocol on a project
- After cloning a repository that lacks `.agents/dev-protocol/`
- State files are missing or corrupted
- After accidentally deleting `.agents/dev-protocol/`

### When NOT to use

- `.agents/dev-protocol/` already exists and appears current (use `/dev-status` instead)
- You want to save progress (use `/dev-save` instead)
- You want to recover context after `/clear` (use `/dev-status` instead)
- You want to declare a goal (use `/dev-scope` instead)

### Inputs

None. /dev-init is a no-argument command.

### Preconditions

- Git repository is initialized (`git rev-parse --git-dir` succeeds)
- Agent has read access to repository root

### Side Effects

| Aspect | Behavior |
|---|---|
| Files modified | Creates `.agents/dev-protocol/workflow-state.yml`, `.agents/dev-protocol/handoff.md`, `.agents/dev-protocol/project-rules.md` |
| Git commit | **NO** -- never auto-commits |
| Git push | **NO** |
| Workflow state | Creates new state; `phase` is always `unknown`; `checkpoint.last_commit` is always empty |

### Outputs

```
## /dev-init Summary

**Scenario**: <A/B/C/D>
**Repository maturity**: <empty/early/active/mature>
**Git state**: <clean/dirty>
**State files**: <created/existing>
**Confidence**: <high/medium/low>

**Next step**: <specific recommendation>
```

### Success Signals

- `.agents/dev-protocol/` directory exists with three state files
- `workflow-state.yml` has valid YAML structure
- `phase` is `unknown`
- `checkpoint.last_commit` is empty
- Output includes scenario classification and next step

### Failure Modes

| Mode | Cause | Recovery |
|---|---|---|
| No git repo | `git rev-parse` fails | Run `git init`, create initial commit, then re-run |
| Existing state | `.agents/dev-protocol/` already exists | Use `/dev-status` instead |
| Low confidence | No README, no docs, dirty workspace, ambiguous structure | STOP and ask user for explicit confirmation |
| Dirty workspace | Modified/untracked files present | Explain dirty state, request explicit confirmation before proceeding |

### Examples

**Normal -- clean repo, no state**
```
/dev-init
→ Scenario B: Git repo + clean + no protocol state
→ Repository maturity: active
→ State files generated in .agents/dev-protocol/
→ Next: Review → git add .agents/ → git commit → /dev-scope
```

**Error -- existing state detected**
```
/dev-init
→ Existing protocol state detected at .agents/dev-protocol/
→ Recommended: /dev-status
→ Reason: Re-running init is unnecessary and may overwrite onboarding assumptions.
```

---

## /dev-status

### Purpose

Inspect current protocol state and reconstruct development context without chat history.

Read-only. Never modifies files.

### When to use

- At the start of any new session (after `/clear`, new day, different machine)
- After switching branches
- When unsure of current project state
- Before declaring a new scope
- After resuming from an interruption

### When NOT to use

- No state files exist yet (use `/dev-init` instead)
- You want to save progress (use `/dev-save` instead)
- You want to declare a goal (use `/dev-scope` instead)
- State files are known to be corrupted (use `/dev-init` to reconstruct)

### Inputs

None. /dev-status is a no-argument command.

### Preconditions

- Git repository is initialized
- `.agents/dev-protocol/` may or may not exist

### Side Effects

| Aspect | Behavior |
|---|---|
| Files modified | **NONE** -- strictly read-only |
| Git commit | **NO** |
| Git push | **NO** |
| Workflow state | **NO** |

### Outputs

```
## /dev-status Summary

**Current Phase**: <phase> (inferred from <source>)
**Focus**: <focus>
**Branch**: <current branch>
**Workspace**: <clean/dirty + details>
**Drift**: <none/low/high> -- <specifics>
**Confidence**: <high/medium/low>

**Active Work**:
- <in-progress tasks or "none">

**Blockers**:
- <blockers or "none">

**Recommended Next Action**:
- <concrete next step>
```

### Phase Inference Precedence

When `workflow-state.yml` reports `phase: unknown` or phase is stale:

```
git reality (branch, recent commit patterns, active work)
  ↓
workflow-state.yml (persisted phase, if not unknown and checkpoint current)
  ↓
current-focus (handoff.md Current Focus section, mapped to phase language)
  ↓
roadmap (docs/v2-redesign-roadmap.md or active roadmap phase label)
  ↓
fallback inference (unknown)
```

Stop at first valid result.

### Focus Inference Precedence

When `workflow-state.yml` focus may be stale:

```
git reality (recent commits, changed files)
  ↓
recent scoped work (aggregated commit themes)
  ↓
workflow-state.yml (persisted focus, ONLY if checkpoint fresh)
  ↓
current-focus (handoff.md Current Focus section)
  ↓
roadmap fallback
  ↓
unknown
```

Stop at first valid result.

### Checkpoint Freshness

| Level | Source commits since last checkpoint | Confidence |
|---|---|---|
| fresh | 0-1 | high |
| stale | 2-5 | medium |
| outdated | >5 | low |

If stale or outdated: workflow-state focus is low-confidence; prefer git-derived focus.

### Success Signals

- Summary block contains phase, focus, branch, workspace, drift, confidence
- Drift classification is one of: none, low, high
- If state files exist: context is reconstructed from state + git reality
- If state files missing: clear recommendation to run `/dev-init`

### Failure Modes

| Mode | Cause | Recovery |
|---|---|---|
| Missing state | `.agents/dev-protocol/` does not exist | "State files not found. Run /dev-init to initialize." |
| Corrupted repository | `git status` fails | Fix git repository externally |
| Severe inconsistency | State contradicts git reality beyond recovery | Drift = high + recommend `/dev-init` |

### Examples

**Normal -- fresh session**
```
/dev-status
→ Current Phase: p3 -- stabilization (inferred from roadmap)
→ Focus: command contract hardening
→ Workspace: clean
→ Drift: none
→ Recommended Next Action: continue current work or declare new scope
```

**Error -- unrecorded commits**
```
/dev-status
→ Drift: high -- unrecorded commits detected since last checkpoint
→ Recommended Next Action: run /dev-save to capture current state
```

---

## /dev-save

### Purpose

Persist protocol state to durable files and create a protocol commit automatically.

### When to use

- After completing meaningful work within a scoped goal
- Before starting a new session
- When protocol state is stale relative to repository reality
- After `/dev-status` reveals drift that needs recording
- Clean workspace verification loops (no-op saves)

### When NOT to use

- No state files exist yet (use `/dev-init` first)
- Workspace has uncommitted source code changes that should be committed first
- You want to declare a new goal (use `/dev-scope` instead)
- You want to inspect state (use `/dev-status` instead)

### Inputs

None. /dev-save is currently a no-argument command.

### Preconditions

- `.agents/dev-protocol/workflow-state.yml` exists
- `.agents/dev-protocol/handoff.md` exists
- Git repository is initialized
- `git rev-parse HEAD` succeeds

### Side Effects

| Aspect | Behavior |
|---|---|
| Files modified | Overwrites `.agents/dev-protocol/workflow-state.yml` and `.agents/dev-protocol/handoff.md` |
| Git commit | **YES** -- creates `chore(checkpoint):` commit with only `.agents/dev-protocol/*` changes |
| Git push | **NO** |
| Workflow state | Updates `checkpoint.last_commit`, `checkpoint.last_updated`, `current_state.focus`, `progress` fields |

### Outputs

**Standard save:**
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

**No-op save:**
```
## /dev-save Complete (No-op)

**Validation Result**: No source changes required
**Validated Target**: <what was verified>
**Summary**: <brief summary>
**Reasoning**: <why no changes were needed>

**Protocol Commit**:
- Message: chore(checkpoint): sync state after validation -- no changes required
- Hash: <new-commit-hash>

**Next Steps**:
1. Continue working or start a new session with /dev-status
```

### DO

- Stage ONLY `.agents/dev-protocol/*` files
- Create protocol commit with `chore(checkpoint):` prefix
- Update `checkpoint.last_commit` to current HEAD
- Validate state consistency before committing
- Allow no-op saves on clean workspace

### DO NOT

- Stage or commit source code files
- Stage or commit non-protocol files
- Create mixed commits (protocol + source changes together)
- Ask for confirmation -- commit automatically
- Modify source code
- Overwrite state without validation

### Success Signals

- Protocol commit created with `chore(checkpoint):` prefix
- Commit contains ONLY `.agents/dev-protocol/*` changes
- `checkpoint.last_commit` updated to new commit hash
- No source files staged or committed
- Output includes "Complete" or "Complete (No-op)"

### Failure Modes

| Mode | Cause | Recovery |
|---|---|---|
| Missing state | State files do not exist | "State files not found. Run /dev-init to initialize." |
| Validation fail | `workflow-state.yml` invalid or required fields missing | Fix state files manually or run `/dev-init` |
| Recoverability fail | Fresh session cannot reconstruct context from state | Enrich state files with more context |
| Git error | `git commit` fails | Resolve git conflict or repository issue externally |
| Mixed staged files | Both protocol files AND source files are staged | STOP. Unstage source files first. Only `.agents/dev-protocol/*` may be committed by /dev-save. |

### Examples

**Normal -- after completing goal work**
```
/dev-save
→ Files Updated: workflow-state.yml, handoff.md
→ Protocol Commit: chore(checkpoint): sync state after auth goal (abc1234)
→ Workspace: clean
→ Next: start new session with /dev-status
```

**Boundary -- with uncommitted source changes**
```
/dev-save
→ Files Updated: workflow-state.yml, handoff.md
→ Protocol Commit: chore(checkpoint): sync state after api refactor (def5678)
→ Workspace: dirty (3 modified files not staged)
→ Warning: non-protocol files remain uncommitted
→ Next: commit source changes before new session
```

**No-op -- clean workspace, no source changes**
```
/dev-save
→ Validation Result: No source changes required
→ Protocol Commit: chore(checkpoint): sync state after validation -- no changes required (ghi9012)
→ Workspace: clean
→ Next: start new session with /dev-status
```

---

## /dev-scope

### Purpose

Declare a focused, bounded goal with validation criteria.

Convert user intent into an explicit scoped objective that an agent can execute without ambiguity.

### When to use

- Before starting any implementation work
- When a task feels too large or ambiguous
- After `/dev-status` reveals the project is ready for new work
- When user provides a vague request that needs structure

### When NOT to use

- The goal is already fully specified by the user
- Simple single-file changes with obvious scope
- Exploration or research without concrete deliverables
- You want to save progress (use `/dev-save` instead)
- You want to inspect state (use `/dev-status` instead)

### Inputs

User intent: brief description of what to accomplish.

If no description provided, prompt:
"What would you like to accomplish? Provide a brief description."

### Preconditions

- Git repository is initialized
- Project state is known (run `/dev-status` first if unsure)

### Side Effects

| Aspect | Behavior |
|---|---|
| Files modified | **NONE** -- only produces output text |
| Git commit | **NO** |
| Git push | **NO** |
| Workflow state | **NO** |

### Outputs

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

### DO

- Ask clarifying questions when intent is ambiguous
- Define explicit in-scope and out-of-scope boundaries
- Include machine-checkable validation criteria
- Prefer smaller scopes (1-3 files ideal)
- Suggest decomposition for scopes affecting 8+ files

### DO NOT

- Implement code
- Modify repository files
- Commit or checkpoint
- Silently expand scope
- Proceed with ambiguous requirements
- Auto-execute when scope is ambiguous, architectural, affects > 3 files, or modifies public APIs

### Scope Size Guidance

| Size | Guidance |
|---|---|
| Small (1-3 files) | Ideal. Prefer this. May auto-execute. |
| Medium (4-7 files) | Acceptable if tightly related. Requires `/goal`. |
| Large (8+ files) | Must decompose. Suggest splitting. |

### Auto-Execution

For simple, low-risk scopes, `/dev-scope` may execute directly without requiring a separate `/goal`.

**Auto-execution criteria** (ALL must be true):

1. File count <= 3
2. No public API changes
3. No cross-module dependencies
4. Single-step validation
5. No ambiguous language
6. Non-architectural change
7. Low blast radius

**Behavior**:

| Result | Action |
|---|---|
| ALL criteria met | Execute immediately; create normal commits; produce goal-output artifact |
| ANY criterion not met | Output scope document; STOP; wait for `/goal` |

**Examples**:

```text
/dev-scope "fix typo in README"
-> auto-executes (1 file, non-architectural, concrete)
-> produces commit: docs(readme): fix typo
-> prompts for /dev-save
```

```text
/dev-scope "refactor auth across all modules"
-> produces scope document (affects > 3 files, cross-cutting)
-> STOPs
-> user reviews, then runs /goal
```

### Success Signals

- Structured scope document with all 5 sections (Goal, Scope, Requirements, Non-goals, Validation)
- In-scope and out-of-scope are explicitly listed
- Validation criteria are machine-checkable
- Scope size is appropriate (<=7 files or decomposed)

### Failure Modes

| Mode | Cause | Recovery |
|---|---|---|
| Empty intent | No description provided | Prompt for description |
| Ambiguous intent | Cannot determine boundaries | Ask 1-3 clarifying questions |
| Missing validation | No criteria defined | Require validation criteria |
| Scope too large | > 7 files or ambiguous breadth | Suggest decomposition |

### Examples

**Normal -- clear intent**
```
/dev-scope "Add user authentication to API"
→ Goal: Add user authentication to API endpoints
→ In-scope: src/auth.py, tests/test_auth.py, docs/api.md
→ Out-of-scope: frontend changes, database migration, OAuth integration
→ Validation: case-06 passes, tests cover login/logout/validate
→ "Review the scope above. Confirm or refine before proceeding to implementation."
```

**Boundary -- ambiguous intent**
```
/dev-scope "Improve performance"
→ STOP
→ "Which specific endpoints or operations should be optimized?"
→ "What metric defines 'improved' -- latency, throughput, or resource usage?"
→ "Should this include profiling infrastructure or only code changes?"
```

---

## /goal

### Purpose

Execute a scoped objective within the boundaries defined by `/dev-scope`.

/goal is the implementation phase. It consumes the scope document and produces code changes.

### When to use

- After `/dev-scope` has produced a validated scope document
- When the scope boundaries are clear and agreed upon
- For concrete implementation work within defined constraints

### When NOT to use

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

### Preconditions

- `/dev-scope` has produced a scope document
- Scope boundaries are confirmed
- Workspace is in a known state (run `/dev-status` if unsure)

### Side Effects

| Aspect | Behavior |
|---|---|
| Files modified | Modifies source code, tests, docs within scope boundaries |
| Git commit | **YES** -- creates normal commits (`feat:`, `fix:`, `docs:`, etc.) during implementation |
| Git push | **NO** |
| Workflow state | **NO** -- does not modify protocol state files |

### Outputs

- Code changes within scope boundaries
- Normal git commits during work
- `goal-output.json` or `goal-output.md` artifact in `.agents/dev-protocol/`

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

### DO

- Implement changes within scope boundaries
- Create normal git commits during work (`feat:`, `fix:`, `docs:`, etc.)
- Produce goal-output artifact
- Derive `changed_files` from `git diff-tree --no-commit-id --name-only -r HEAD`

### DO NOT

- Exceed scope boundaries without new `/dev-scope`
- Modify protocol state files (`.agents/dev-protocol/*`)
- Create protocol commits (`chore(checkpoint):`)
- Invent changed_files -- must match actual commit

### Success Signals

- Scope requirements are implemented
- Validation criteria are met
- Normal commits created with conventional commit format
- goal-output artifact present with valid status

### Failure Modes

| Mode | Cause | Recovery |
|---|---|---|
| Scope violation | Changes exceed defined boundaries | STOP, report violation, recommend new scope |
| Validation fail | Criteria not met | Report failures, recommend fix scope |
| Blocked | External dependency prevents completion | goal_status: BLOCKED + specific blocker |
| No changes | Goal completes without file modifications | goal_status: COMPLETED + note no changes |

### Examples

**Normal -- standard implementation**
```
/goal <scope from /dev-scope>
→ implements changes
→ git commit -m "feat(api): add user authentication"
→ goal-output.json created
→ case-06 validation passes
→ /dev-save
```

**Boundary -- no-op goal**
```
/goal <scope from /dev-scope>
→ behavior already correct, no changes needed
→ goal-output.json created with goal_status: COMPLETED
→ case-06 validation passes (with no changes)
→ /dev-save
```

---

## Secondary Commands (Deprecated Aliases)

These commands redirect to canonical v2 commands. They remain callable for backward compatibility.

### /dev-bootstrap

- **Redirect**: `/dev-init`
- **Status**: Deprecated
- **Behavior**: Identical to `/dev-init`

### /dev-checkpoint

- **Redirect**: `/dev-save`
- **Status**: Deprecated
- **Behavior**: Identical to `/dev-save`

### /dev-resume

- **Redirect**: `/dev-status`
- **Status**: Deprecated
- **Behavior**: Identical to `/dev-status`

### /dev-doctor

- **Redirect**: `/dev-status --diagnose`
- **Status**: Deprecated
- **Behavior**: Diagnostic mode of `/dev-status`

### /dev-help

- **Redirect**: `/dev-status --help`
- **Status**: Deprecated
- **Behavior**: Help mode of `/dev-status`

### /dev-goal-template

- **Redirect**: `/dev-scope`
- **Status**: Deprecated
- **Behavior**: Identical to `/dev-scope`

---

## Command Relationship Map

```
/dev-init     -- first contact, creates state
   ↓
/dev-status   -- inspect state (read-only)
   ↓
/dev-scope    -- declare goal (auto-executes if criteria met)
   ↓              ↓ (auto-execution)
/goal         -- implement within scope   normal commits
   ↓ (commit source)                       goal-output artifact
   ↓                                         ↓
case-06       -- validate goal commit ←──────┘
   ↓
/dev-save     -- persist protocol state
   ↓
case-05       -- validate checkpoint
   ↓
/dev-status   -- inspect updated state
```

**Key rules**:

- /dev-save NEVER commits source code. Source commits happen during /goal or auto-execution.
- /dev-status NEVER modifies anything. It is strictly read-only.
- /dev-scope MAY implement directly when auto-execution criteria are ALL met.
- /dev-scope declares intent; auto-execution is an optimization for simple scopes.
- /dev-init NEVER auto-commits. User must manually commit state files.
- /goal NEVER modifies protocol state files.
