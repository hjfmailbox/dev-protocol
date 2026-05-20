# MVP Scope

## Goal

Achieve reliable recoverable development sessions.

A developer should be able to:

1. /dev-bootstrap
2. develop
3. /dev-checkpoint
4. clear context
5. /dev-resume
6. continue development

without relying on prior chat history.

---

## Included In v1

### Commands

- /dev-bootstrap
- /dev-resume
- /dev-checkpoint

---

### State Files

- workflow-state.yml
- handoff.md
- project-rules.md

---

### Validation

- workflow consistency
- recoverability check
- document drift detection
- commit format validation

---

### Git

- automatic checkpoint commit

---

## Explicitly Excluded

### Multi-agent support

Not in v1.

---

### Auto repair

No /dev-repair yet.

---

### Complex document inference

Only high-confidence synchronization.

---

### Advanced hook system

Simple enforcement only.

---

### Long historical memory

State over history.

---

## Success Criteria

A new chat can:

1. run /dev-resume
2. understand current state
3. continue work

within 5 minutes.
