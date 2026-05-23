# Workflow Rules

## Purpose

Define the recommended development lifecycle for projects using this protocol.

It replaces "figure out what to do next" with "follow a fixed sequence."

---

## Development Lifecycle

1. `/dev-bootstrap` — recover or reconstruct project state on a fresh session
2. develop — write code, test, iterate within a scoped goal
3. `/goal` — declare a focused objective with explicit scope boundaries
4. `/dev-checkpoint` — persist state, validate consistency, commit
5. `/dev-resume` — restore context in the next session without chat history

This sequence ensures every session can start, work, save, and resume
predictably, regardless of time gaps or session boundaries.

---

## Work Categories

| Category | Definition | When to Do |
|---|---|---|
| **Goal work** | Implementing a scoped feature, fix, or document change | After declaring `/goal` with clear scope |
| **Checkpoint work** | Updating state files, validating, committing current progress | After goal work completes or at natural breakpoints |
| **Maintenance edits** | Fixing typos, updating docs, adjusting rules without changing behavior | Between goals, when state is stable |

**Example:** Filling `references/workflow-rules.md` with content is goal work.
Updating `workflow-state.yml` to mark it completed is checkpoint work.
Fixing a typo in `project-rules.md` is a maintenance edit.

---

## Validation Order

1. **After goal work**: run case-06 (document consistency check) to verify
   the changed document aligns with existing conventions and references.
2. **After checkpoint**: run case-05 (checkpoint idempotency) to verify
   the committed state is self-consistent and reproducible.

Do not run case-05 before case-06 — checkpoint validation assumes
documents are already consistent.

---

## Rules for Safe Iteration

1. **One scoped goal at a time.** Do not combine unrelated changes in a
   single goal. Smaller goals = easier review = faster checkpoints.

2. **Avoid unrelated refactors.** If the goal is "fill placeholder," do not
   restructure the document format or rename sections. Refactors are their
   own goals.

3. **Checkpoint frequently.** A checkpoint after every completed goal is
   the minimum. Longer gaps between checkpoints increase drift risk.

4. **Resume after clear.** When returning to work, always run `/dev-resume`
   before writing code. Never assume you remember the exact state correctly.

---

## Example Workflow

```
Session 1: /dev-bootstrap → /goal "fill workflow-rules.md" → write content → /dev-checkpoint
Session 2: /dev-resume → /goal "run case-01 test" → execute tests → /dev-checkpoint
Session 3: /dev-resume → /goal "fix case-01 failure" → patch → /dev-checkpoint
```

Each session starts with state recovery, declares a focused goal, works
within that scope, and checkpoints before ending. No chat history needed.
