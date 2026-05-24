# Workflow Rules

## Purpose

Define the recommended development lifecycle for projects using this protocol.

It replaces "figure out what to do next" with "follow a fixed sequence."

---

## Development Lifecycle

1. **Bootstrap** — recover or reconstruct project state on a fresh session (Claude Code: `/dev-bootstrap`)
2. **Develop** — write code, test, iterate within a scoped goal
3. **Goal** — declare a focused objective with explicit scope boundaries (Claude Code: `/goal`)
4. **Checkpoint** — persist state, validate consistency, commit (Claude Code: `/dev-checkpoint`)
5. **Resume** — restore context in the next session without chat history (Claude Code: `/dev-resume`)

This sequence ensures every session can start, work, save, and resume
predictably, regardless of time gaps or session boundaries.

---

## Work Categories

| Category | Definition | When to Do |
|---|---|---|
| **Goal work** | Implementing a scoped feature, fix, or document change | After declaring a goal with clear scope (Claude Code: `/goal`) |
| **Checkpoint work** | Updating state files, validating, committing current progress | After goal work completes or at natural breakpoints (Claude Code: `/dev-checkpoint`) |
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

4. **Resume after session reset.** When returning to work, always resume
   (Claude Code: `/dev-resume`) before writing code. Never assume you remember the exact state correctly.

---

## Example Workflow

```
Session 1: Bootstrap → Goal "fill workflow-rules.md" → write content → Checkpoint
Session 2: Resume → Goal "run case-01 test" → execute tests → Checkpoint
Session 3: Resume → Goal "fix case-01 failure" → patch → Checkpoint

In Claude Code: Bootstrap = `/dev-bootstrap`, Goal = `/goal`, Checkpoint = `/dev-checkpoint`, Resume = `/dev-resume`.
```

Each session starts with state recovery, declares a focused goal, works
within that scope, and checkpoints before ending. No chat history needed.
