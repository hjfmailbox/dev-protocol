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
→ Wait For Review
```

---

## Goal Requirements

A valid `/goal` should:

- define a concrete outcome
- define observable validation
- define scope boundaries
- avoid unrelated modifications

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