# Goal Workflow

## Purpose

Define a minimal and reusable `/goal` execution workflow.

The workflow must:

- stay generic
- avoid business-specific assumptions
- prefer automated validation
- stop safely when ambiguity or risk is detected

---

## Minimal Lifecycle

```text
Set Goal
→ Analyze Scope
→ Implement
→ Validate
→ Stop
→ Write Output Artifact (goal-output.json or goal-output.md)
→ Terminal Summary
→ Wait For Review
```

---

## Goal Requirements

A valid `/goal` should:

- define a concrete outcome
- define observable validation
- define scope boundaries
- avoid unrelated modifications
- keep scope minimal: one clear objective, not a broad initiative

Bad example:

```text
Improve the whole architecture
```

Good example:

```text
Add input validation for user email format
```

---

## Execution Rules

During execution:

- keep changes scoped to the goal
- prefer small iterations
- avoid unrelated refactors
- validate continuously
- stop immediately on unsafe state

---

## Stop Conditions

Execution must stop when:

- goal is completed
- validation succeeds
- user clarification is required
- repeated failures occur
- git state becomes unsafe
- modification scope expands unexpectedly

---

## Repeated Failures

When the same failure occurs more than twice:

- stop attempting the same approach
- document what was tried and why it failed
- flag the blocker in the output summary
- wait for user guidance

Do not retry indefinitely or silently switch strategies.

---

## Validation Priority

Validation order:

1. Existing automated tests
2. Focused new tests
3. Git state checks
4. Manual review

Manual review should happen after automated validation whenever possible.

---

## Safety Rules

Never:

- continue with dirty tracked workspace unexpectedly
- modify unrelated files silently
- expand scope without explicit approval
- bypass validation
- auto-commit unrelated work

---

## Output Expectations

At completion, the workflow should provide:

- changed files summary
- validation results
- remaining risks or blockers
- recommended next step

See `docs/goal-output-contract.md` for the full required output structure.

---

## Continuation Contract

After one goal finishes, the output must support the next goal to start efficiently.

The completing goal should explicitly state:

- **Context to carry forward**: what the next goal needs to know
- **Boundary note**: what was intentionally NOT changed and why
- **Next candidate goal**: one concrete suggestion for follow-up
- **Prompt seed**: a ready-to-use `/goal` prompt the next session can paste directly

This eliminates the translation step between sessions and prevents scope drift.

A goal that completes without a continuation handoff has not fully completed its output contract.