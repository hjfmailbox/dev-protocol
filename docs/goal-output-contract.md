# Goal Output Contract

## Purpose

Define the standard stopping output for `/goal`.

A `/goal` execution must stop with a structured summary instead of continuing indefinitely.

The output exists to:

- signal completion
- support fast review
- reduce hidden changes
- surface blockers early

---

## Required Output Sections

Every completed `/goal` should provide:

### 1. Goal Status

One of:

```text
COMPLETED
PARTIALLY_COMPLETED
BLOCKED
FAILED
ABORTED
```

---

### 2. Goal Summary

Short description of:

```text
What changed
```

Keep concise.

---

### 3. Changed Files

List only files modified for the goal.

Example:

```text
docs/goal-workflow.md
tests/case-06-goal-workflow/test-plan.md
```

---

### 4. Validation Results

Show:

- tests executed
- command results
- verification status

Example:

```text
PASS: automated validation
PASS: git workspace consistent
FAIL: integration test missing
```

---

### 5. Stop Reason

Must explicitly explain why execution stopped.

Examples:

```text
Goal completed successfully
```

```text
Blocked by unclear requirements
```

```text
Repeated failures exceeded retry limit
```

---

### 6. Risks / Follow-ups

Optional.

Include:

- unresolved concerns
- recommended next step
- suggested future goal

---

## Hard Rules

Never stop silently.

Never claim success without validation.

Never continue indefinitely after repeated failure.

Never modify unrelated files without reporting them.

Always provide a reviewable stopping summary.