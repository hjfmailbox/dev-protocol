# Failure Policy

## Principle

Fail over partial success.

A failed protocol execution is safer than an incorrect checkpoint.

Never pretend recovery is safe when confidence is low.

---

## Severity Levels

### Warning

Execution may continue.

Examples:

- optional docs outdated
- incomplete notes
- minor inconsistency

Must explicitly report.

---

### Soft Failure

Execution pauses for review.

Examples:

- workflow confidence is medium
- project state unclear
- likely document drift

Must request confirmation.

No auto commit.

---

### Hard Failure

Execution must stop.

Examples:

- repository unreadable
- workflow state corrupted
- major inconsistency
- recovery confidence too low
- required synchronization missing

No commit allowed.

---

## Init Rules

/dev-init

May continue with warnings.

Must stop if:

- project cannot be reconstructed
- confidence too low

Never auto commit.

---

## Status Rules

/dev-status

Must stop if:

- recoverable state missing
- severe drift detected

Must recommend:

/dev-init

---

## Save Rules

/dev-save

Must fail if:

- workflow-state.yml missing
- handoff.md missing
- synchronization incomplete
- state contradicts repository
- recovery confidence low

Never partially succeed.

No state write on failure.

---

## Confidence Levels

high:
Reliable recovery expected.

medium:
Recovery possible but review recommended.

low:
Recovery unsafe.

Protocol execution should fail.
