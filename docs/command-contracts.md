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

### Semantic Drift Classification

Beyond commit counting, classify commits by semantic intent:

| Pattern | Type | Drift |
|---|---|---|
| `chore(checkpoint):*` | Protocol-only | none |
| `docs(*):*` without source changes | Documentation-only | low |
| `test(*):*` without source changes | Test-only | low |
| `feat(*):*` or `fix(*):*` | Source-impacting | high |
| Stabilization-pattern sequence | Stabilization | low |
| Roadmap-aligned commits | Roadmap-aligned | medium |

**Application**: When reporting drift, include semantic classification:
```
Drift: high — 3 source-impacting commits, 2 stabilization-pattern commits
```

### Semantic Active-Work Reconstruction

When `/dev-save` has NOT been run after recent goal work, reconstruct active work from git history using semantic theme inference:

| Pattern | Inferred Theme |
|---|---|
| Multiple `docs(*):*` + `fix(tests):*` | Stabilization / documentation hardening |
| Multiple `feat(protocol):*` + `skills/*` | Protocol feature expansion |
| `test(case-NN):*` sequence | Test coverage expansion |
| Mix of `feat:`, `fix:`, `test:` on same component | Active development on that component |

**Sources for semantic enrichment**:
1. Git history (primary)
2. Roadmap active items (secondary)
3. Deferred improvements (tertiary)
4. Goal-output summaries (if present)

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

## continue loop

### Purpose

Reduce manual orchestration for planned execution by automatically deriving and executing the next loop from `next-phase-plan.md`.

### When to use

- `next-phase-plan.md` exists with planned work
- User wants to proceed to the next planned loop without manual scoping
- After `/dev-save`, when the next loop is already defined in the plan

### When NOT to use

- No `next-phase-plan.md` exists (use `/dev-scope` instead)
- Workspace has uncommitted non-protocol changes
- Next planned loop is ambiguous (use `/dev-scope` instead)
- All planned loops are already completed
- You want to inspect state (use `/dev-status` instead)
- You want to save progress (use `/dev-save` instead)

### Inputs

None. `continue loop` is a no-argument command.

### Preconditions

ALL must be true:

| # | Condition |
|---|---|
| 1 | `next-phase-plan.md` exists in `.agents/dev-protocol/` |
| 2 | `next-phase-plan.md` is not empty |
| 3 | Workspace is clean OR only protocol state files modified |
| 4 | No unresolved blockers in `handoff.md` |
| 5 | `checkpoint.last_commit` matches HEAD or HEAD~1 |

### Side Effects

| Aspect | Behavior |
|---|---|
| Files modified | May modify source code (if auto-executing); updates `next-phase-plan.md` status |
| Git commit | **YES** — creates normal commits during auto-execution |
| Git push | **NO** |
| Plan status | Updates loop status to `completed` or `skipped` |

### Outputs

**Auto-execution path:**
```
**Continue Loop**: Auto-executing Loop N — [name]

**Derived Scope**: <summary>
**Execution Result**: <implementation summary>

**Workflow Status**:
- Loop N completed
- Workflow completed
- No remaining protocol tasks pending
- Run /dev-save to persist state
```

**Scope document path:**
```
**Continue Loop**: Loop N — [name]

**Derived Scope**: <full scope document>
**Auto-execution**: Criteria NOT met. Separate /goal required.

**Workflow Status**:
- Scope derived from plan
- Workflow completed
- No remaining protocol tasks pending
- Review scope above, then run /goal to implement
```

### Execution Sequence

```text
continue loop
  → 1. verify preconditions
  → 2. read next-phase-plan.md
  → 3. identify next uncompleted loop (tolerant parsing)
  → 4. evaluate loop clarity (detect ambiguity)
  → 5. derive scope from plan + handoff + recent commits
  → 6. apply semantic validation equivalence to criteria
  → 7. evaluate auto-execution criteria (same as /dev-scope)
  → 8. if auto-execute: execute immediately, apply semantic completion check, update plan status
     else: output scope document, STOP, wait for /goal
```

### Semantic Validation in Continue Loop

Before evaluating auto-execution, interpret validation criteria semantically:

- **Same domain + direction**: "tests pass" ≈ "all regression cases pass"
- **Git reality confirms intent**: commit messages and changed files satisfy plan criteria
- **Test outcomes match criteria**: test results validate criteria even with different wording
- **Commit intent matches goal**: conventional commit subjects align with plan objectives

**Non-equivalence signals**: "started" vs "completed", "partial" vs "fully resolved"

After auto-execution, apply **semantic completion check**: verify git reality, test results, or commit intent satisfy the loop's validation criteria using semantic equivalence rules.

### DO

- Verify ALL preconditions first
- Use tolerant parsing for loop detection
- Derive scope from plan context
- Apply auto-execution criteria strictly
- Update plan status after completion
- STOP on ambiguity, drift, or dirty workspace

### DO NOT

- Proceed without `next-phase-plan.md`
- Auto-execute ambiguous or architectural loops
- Ignore dirty workspace or checkpoint drift
- Invent requirements not implied by the plan
- Modify source code if auto-execution criteria are NOT met

### Success Signals

- Next incomplete loop identified
- Scope derived with clear boundaries
- Either: auto-execution completes with normal commits, OR scope document produced for `/goal`
- Plan status updated

### Failure Modes

| Mode | Cause | Recovery |
|---|---|---|
| Missing plan | `next-phase-plan.md` does not exist | Run `/dev-scope` to declare a goal |
| Empty plan | `next-phase-plan.md` exists but is empty | Update plan or run `/dev-scope` |
| Dirty workspace | Uncommitted non-protocol changes | Commit or stash before continuing |
| Blockers | Unresolved issues in `handoff.md` | Resolve blockers first |
| Ambiguity | Next loop lacks files or validation | Clarify `next-phase-plan.md` or run `/dev-scope` |
| Drift | `checkpoint.last_commit` does not match HEAD | Run `/dev-status` to review |
| All complete | No incomplete loops remain | "All planned loops completed." |
| Unrecognizable format | Plan does not match any loop pattern | Reformat `next-phase-plan.md` |

### Examples

**Normal -- plan exists, auto-executes**
```
continue loop
→ reads next-phase-plan.md
→ finds Loop 3: "Update command contracts for /dev-save"
→ derives scope: files=docs/command-contracts.md
→ auto-executes (1 file, no API changes)
→ produces commit: docs(contracts): add dirty workspace behavior
→ updates Loop 3 status to completed
→ prompts: "/dev-save to persist state"
```

**Boundary -- plan exists, requires /goal**
```
continue loop
→ reads next-phase-plan.md
→ finds Loop 4: "Refactor auth across all modules"
→ derives scope: files=src/auth/*, tests/*, docs/*
→ criteria NOT met (>3 files, cross-cutting)
→ outputs scope document
→ STOPs
→ user reviews, then runs /goal
```

**Error -- no plan**
```
continue loop
→ next-phase-plan.md not found
→ STOP
→ "No plan found. Run /dev-scope to declare a goal."
```

**Error -- all completed**
```
continue loop
→ reads next-phase-plan.md
→ all loops have status: completed
→ STOP
→ "All planned loops completed."
```

---

## generate plan

### Purpose

Convert a high-level goal into a structured `next-phase-plan.md` draft, reducing manual planning friction before `continue loop` execution.

### When to use

- After `/dev-scope` or `/goal` has produced a high-level objective
- Before `continue loop`, when no `next-phase-plan.md` exists yet
- When a goal is complex enough to benefit from decomposition into loops
- After reviewing roadmap or deferred items that suggest multi-step work

### When NOT to use

- A `next-phase-plan.md` already exists (use `continue loop` instead)
- The goal is simple enough for single-loop auto-execution (use `/dev-scope` directly)
- You want to inspect state (use `/dev-status` instead)
- You want to save progress (use `/dev-save` instead)

### Inputs

Goal (optional if inferable from context): brief description of the objective.

If no goal provided and none inferable from context, prompt for one.

### Preconditions

- Git repository is initialized
- `.agents/dev-protocol/` exists with valid state files
- Goal is provided or inferable from context

### Side Effects

| Aspect | Behavior |
|---|---|
| Files modified | Creates or updates `.agents/dev-protocol/next-phase-plan.md` |
| Git commit | **NO** — does not auto-commit |
| Git push | **NO** |
| Workflow state | **NO** — does not modify protocol state files |

### Outputs

```
## generate plan Complete

**Goal Inferred**: <goal summary>
**Loops Generated**: <N>
**Plan File**: `.agents/dev-protocol/next-phase-plan.md`

**Loop Summary**:
- Loop 1: <name> — <files> — <auto-execution status>
- ...

**Context Used**:
- Phase: <phase>
- Focus: <focus>
- Roadmap items: <list>
- Deferred items: <list>

**Next Steps**:
1. Review `.agents/dev-protocol/next-phase-plan.md`
2. Edit if needed
3. Run continue loop to execute
```

### DO

- Prefer small, focused loops
- Use concrete language
- Include explicit validation criteria
- Reference specific files when possible
- Validate against continue-loop constraints
- Allow user to review plan before execution

### DO NOT

- Execute loops
- Modify source code
- Invent requirements not implied by context
- Create loops larger than 8 files without decomposition note
- Skip context reading
- Overwrite existing `next-phase-plan.md` without confirmation

### Success Signals

- `.agents/dev-protocol/next-phase-plan.md` created with numbered loops
- Each loop has Goal, Files, and Validation sections
- Plan validated against continue-loop constraints
- Output includes plan summary and next steps

### Failure Modes

| Mode | Cause | Recovery |
|---|---|---|
| Missing state | `.agents/dev-protocol/` does not exist | Run `/dev-init` |
| No goal | No goal provided and none inferable | Run `/dev-scope` to declare a goal |
| Ambiguous goal | Cannot determine scope from context | Ask clarifying questions |
| Zero loops | Goal is too vague to decompose | Refine goal or run `/dev-scope` |
| All loops violate constraints | Every loop exceeds auto-execution limits | Warn user; suggest `/goal` for complex work |

### Examples

**Normal — goal inferred from context**
```
generate plan
→ reads workflow-state.yml (phase: p3, focus: stabilization)
→ reads deferred-improvements.md (D03, D04 active)
→ decomposes into 3 loops
→ writes `.agents/dev-protocol/next-phase-plan.md`
→ "Review plan, then run continue loop"
```

**Boundary — goal provided explicitly**
```
generate plan "Refactor auth module"
→ decomposes into 4 loops
→ Loop 1: audit current auth (2 files) — auto-executable
→ Loop 2: extract interface (1 file) — auto-executable
→ Loop 3: migrate consumers (5 files) — requires /goal
→ Loop 4: update docs (2 files) — auto-executable
→ writes `.agents/dev-protocol/next-phase-plan.md` with notes
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
generate plan -- decompose goal into loops (if no plan exists)
   ↓
continue loop -- derive next loop from plan (if exists)
   ↓              ↓ (no plan)
/dev-scope    -- declare goal (auto-executes if simple)
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
- `continue loop` ALWAYS verifies preconditions before reading plan.
- `continue loop` NEVER auto-executes ambiguous or architectural loops.

---

## Semantic Validation Layer

### Purpose

Reduce false negatives from rigid string/criteria matching by interpreting validation signals semantically.

### When it applies

- `continue loop` evaluates whether a loop's validation criteria are satisfied
- `/dev-status` classifies drift and reconstructs active work
- Any command compares planned criteria against actual outcomes

### Semantic Equivalence Rules

Two phrases are equivalent if ANY of the following hold:

1. **Same domain + same action direction**
   - "tests pass" ≈ "all test cases pass" ≈ "regression tests green"
   - "README updated" ≈ "documentation synchronized" ≈ "docs updated"

2. **Git reality confirms intent**
   - Commit `docs(protocol): harden contracts` satisfies "contracts hardened"
   - Changed files in git match the plan's `Files:` list

3. **Test outcomes match criteria**
   - `case-34 PASS` satisfies "case-34 basic workflow"
   - "All required tests pass" satisfies "tests pass"

4. **Commit intent matches goal**
   - Commit `feat(protocol): add generate-plan` satisfies "generate plan implemented"

### Non-equivalence Signals

These are NOT equivalent:
- "started work on" vs "completed"
- "partial fix" vs "fully resolved"
- "investigated" vs "implemented"

### Semantic Drift Classification

Beyond commit counting, classify commits by intent:

| Pattern | Type | Drift |
|---|---|---|
| `chore(checkpoint):*` | Protocol-only | none |
| `docs(*):*` without source changes | Documentation-only | low |
| `test(*):*` without source changes | Test-only | low |
| `feat(*):*` or `fix(*):*` | Source-impacting | high |
| Stabilization-pattern sequence | Stabilization | low |
| Roadmap-aligned commits | Roadmap-aligned | medium |

### Active Work Semantic Inference

Infer themes from commit patterns:

| Pattern | Theme |
|---|---|
| Multiple `docs(*):*` + `fix(tests):*` | Stabilization / documentation hardening |
| Multiple `feat(protocol):*` + `skills/*` | Protocol feature expansion |
| `test(case-NN):*` sequence | Test coverage expansion |
| Mix of `feat:`, `fix:`, `test:` on same component | Active development |

### DO

- Apply semantic equivalence when comparing criteria vs outcomes
- Use git reality as confirming evidence
- Classify drift by semantic intent, not just count
- Infer active work themes from commit patterns

### DO NOT

- Require literal string matches for validation
- Treat documentation-only changes as high drift
- Ignore commit intent when evaluating completion
- Report stabilization-pattern commits as unrecorded work
