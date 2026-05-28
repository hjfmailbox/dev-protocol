# Workflow Compression Design

Reduce repetitive steps in the dev-protocol workflow without losing clarity.

Current friction:

```text
/dev-status
/dev-scope
/goal
implement
/dev-save
```

Even simple, deterministic work requires `/dev-scope` followed by `/goal`.

---

## Part 1 — /dev-scope → /goal Compression

### Problem

`/dev-scope` and `/goal` both express intent.

- `/dev-scope` produces a structured scope document
- `/goal` consumes that document and executes

For simple work, this is unnecessary duplication.

### Decision Rules

| Condition | Action | Example |
|-----------|--------|---------|
| Scope affects ≤ 3 files | `/dev-scope` auto-executes. No separate `/goal` needed. | "Fix typo in README" |
| Scope is a single, well-defined change | `/dev-scope` auto-executes. | "Add missing import to auth.py" |
| Scope is purely documentation and ≤ 1 section | `/dev-scope` auto-executes. | "Update command table in README" |
| Scope affects > 3 files | Require separate `/goal` after `/dev-scope`. | "Refactor error handling across all endpoints" |
| Scope requires multi-step orchestration | Require separate `/goal` after `/dev-scope`. | "Add OAuth flow: register, login, token refresh" |
| Scope is ambiguous or requires exploration | Require separate `/goal` after `/dev-scope`. | "Improve performance" |
| Scope modifies public API contracts | Require separate `/goal` after `/dev-scope`. | "Change authentication response format" |
| Scope involves cross-cutting concerns | Require separate `/goal` after `/dev-scope`. | "Migrate from callbacks to async/await" |

### Auto-execution Criteria

`/dev-scope` auto-executes (no separate `/goal`) when ALL of the following are true:

1. File count ≤ 3
2. No public API changes
3. No cross-module dependencies
4. Validation criteria are single-step
5. No ambiguous language in the scope description

If ANY criterion is false, `/dev-scope` produces a scope document and STOPs. User must then run `/goal` separately.

### Examples

**Auto-execute (no `/goal` needed)**:

```text
User: "/dev-scope fix typo in README installation section"
→ detects: 1 file, no API changes, single-step validation
→ auto-executes
→ produces commit: docs(readme): fix typo in installation section
→ prompts for /dev-save
```

**Require `/goal` (complex)**:

```text
User: "/dev-scope add user authentication"
→ detects: multiple files, API changes, multi-step validation
→ produces scope document
→ STOPs
→ User reviews scope, then runs /goal
```

**Require `/goal` (ambiguous)**:

```text
User: "/dev-scope improve performance"
→ detects: vague verb, no files specified, no validation criteria
→ asks clarifying questions
→ produces scope document after clarification
→ STOPs
→ User runs /goal after confirming scope
```

### Backward Compatibility

`/dev-scope` always produces a scope document. In auto-execution mode, it also executes immediately. The scope document is still available for review.

`/goal` remains unchanged. It always consumes a scope document and executes.

---

## Part 2 — Continue Loop Design

### Purpose

Reduce manual orchestration for planned execution.

When `next-phase-plan.md` exists, automatically derive and execute the next loop.

### Trigger

```text
continue loop
```

or

```text
/dev-continue
```

### Preconditions

ALL must be true:

1. `next-phase-plan.md` exists in `.agents/dev-protocol/`
2. `next-phase-plan.md` is not empty
3. Current workspace is clean OR only protocol state files are modified
4. No unresolved blockers in `handoff.md`
5. `workflow-state.yml` `checkpoint.last_commit` matches HEAD or HEAD~1

### Execution Sequence

```text
continue loop
  → 1. read next-phase-plan.md
  → 2. identify next uncompleted loop
  → 3. derive scope from plan + handoff + recent commits
  → 4. run /dev-scope with derived scope
  → 5. if auto-execute criteria met: execute immediately
     else: produce scope document, STOP, wait for /goal
  → 6. after execution: prompt for /dev-save
```

### Failure Behavior

| Failure | Behavior |
|---------|----------|
| `next-phase-plan.md` missing | STOP. Output: "No plan found. Run /dev-scope to declare a goal." |
| `next-phase-plan.md` empty | STOP. Output: "Plan exists but is empty. Update next-phase-plan.md or run /dev-scope." |
| Workspace dirty (non-protocol files) | STOP. Output: "Workspace has uncommitted changes. Commit or stash before continuing." |
| Unresolved blockers | STOP. Output: "Blockers detected: [list]. Resolve before continuing." |
| Plan ambiguity | STOP. Output: "Next loop is ambiguous: [description]. Clarify next-phase-plan.md or run /dev-scope." |
| Checkpoint drift | STOP. Output: "State drift detected. Run /dev-status to review." |

### Ambiguity Handling

If the next loop in `next-phase-plan.md` is ambiguous:

1. STOP execution
2. Output the ambiguous item
3. Ask user to clarify `next-phase-plan.md` or run `/dev-scope` manually
4. Never proceed with ambiguous scope

Ambiguity signals:

- Vague description
- No file references
- No validation criteria
- Dependencies on uncompleted previous loops

### Human Override

User can override `continue loop` at any point:

| Override | Behavior |
|----------|----------|
| Interrupt during execution | Stop at current step, preserve state |
| Reject derived scope | Output scope for review, ask user to confirm or refine |
| Skip current loop | Mark loop as skipped in `next-phase-plan.md`, proceed to next |
| Add new loop mid-execution | Append to `next-phase-plan.md`, update handoff, continue |
| Force manual `/dev-scope` | Ignore `next-phase-plan.md`, run `/dev-scope` as usual |

### Plan Format

`next-phase-plan.md` must follow this structure for `continue loop` to work:

```md
# Next Phase Plan

## Loop 1 — [short name]

- Files: [file1, file2]
- Goal: [one-sentence objective]
- Validation: [how to verify]
- Status: pending | in_progress | completed | skipped

## Loop 2 — [short name]

...
```

`continue loop` scans for the first loop with `Status: pending`.

### Example

```text
# Plan exists
User: "continue loop"
→ reads next-phase-plan.md
→ finds Loop 3: "Update command contracts for /dev-save"
→ derives scope: files=docs/command-contracts.md, goal=add dirty workspace behavior
→ auto-executes (1 file, no API changes)
→ produces commit
→ prompts: "/dev-save to persist state"

# No plan
User: "continue loop"
→ next-phase-plan.md not found
→ STOP
→ "No plan found. Run /dev-scope to declare a goal."

# Ambiguous plan
User: "continue loop"
→ next loop: "Improve performance"
→ STOP
→ "Next loop is ambiguous: 'Improve performance' has no files or validation criteria."
→ "Clarify next-phase-plan.md or run /dev-scope."
```
