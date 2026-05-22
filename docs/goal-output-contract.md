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

Include when applicable:

- unresolved concerns
- recommended next step
- suggested future goal

---

### 7. Continuation Handoff

Always include, even if brief.

Provide:

- **Context to carry forward**: what the next goal needs to know about this change
- **Boundary note**: what was intentionally NOT changed and why
- **Next candidate goal**: one concrete suggestion for follow-up work
- **Prompt seed**: one ready-to-use `/goal` prompt the next session can paste as-is

The prompt seed should include:

```text
/goal

## Goal
<one-sentence objective>

## Scope
Allowed files:
<explicit file list>

Forbidden:
<boundaries inherited from this goal + any new constraints>
```

This eliminates the translation step between sessions and prevents scope drift.

---

## Hard Rules

Never stop silently.

Never claim success without validation.

Never continue indefinitely after repeated failure.

Never modify unrelated files without reporting them.

Always provide a reviewable stopping summary.

Never declare completion without confirming the expected file content actually changed.

---

## Validation Gap

The output contract is defined as session text, not a file artifact.

Current automation (`tests/run-tests.ps1` case-06) validates:

- workspace cleanliness
- commit integrity (conventional format, content changes, scope limit)
- workflow correctness (not a checkpoint commit)

It does NOT validate:

- Goal Status section presence
- Goal Summary section presence
- Changed Files section presence
- Validation Results section presence
- Stop Reason section presence
- Risks/Follow-ups section presence

These sections exist only in session output and require manual review.

Output contract automation would require session output capture (e.g., logging to a file), which is outside the current architecture scope.