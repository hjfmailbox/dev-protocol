# Workflow Rules

## Purpose

Define the recommended development lifecycle for projects using this protocol.

It replaces "figure out what to do next" with "follow a fixed sequence."

---

## Development Lifecycle

```
Init → Scope → Work → Save → New Session → Status → Scope → ...
```

1. **Init** — Initialize protocol on a fresh project or after cloning (Claude Code: `/dev-init`)
2. **Scope** — Declare a focused objective with explicit scope boundaries (Claude Code: `/dev-scope`)
3. **Work** — Write code, test, iterate within the scoped objective
4. **Save** — Persist state, validate consistency (Claude Code: `/dev-save`)
5. **New Session** — Reset conversation context. State survives in repository files.
6. **Status** — Restore context in the next session without chat history (Claude Code: `/dev-status`)

This sequence ensures every session can start, work, save, and resume predictably, regardless of time gaps or session boundaries.

---

## Work Categories

| Category | Definition | When to Do |
|---|---|---|
| **Scope work** | Implementing a scoped feature, fix, or document change | After declaring a scope with clear boundaries (Claude Code: `/dev-scope`) |
| **Save work** | Updating state files, validating current progress | After scope work completes or at natural breakpoints (Claude Code: `/dev-save`) |
| **Maintenance edits** | Fixing typos, updating docs, adjusting rules without changing behavior | Between scopes, when state is stable |

**Example:** Filling `references/workflow-rules.md` with content is scope work. Updating `workflow-state.yml` to mark it completed is save work. Fixing a typo in `project-rules.md` is a maintenance edit.

---

## Validation Order

The validation sequence is strict. Running tests out of order produces false failures.

```
Scope → Work → case-06 → Save → commit state files → case-05
```

1. **After scope work**: run `pwsh tests/run-tests.ps1 -Case 06` to verify the goal commit and artifact are valid.
2. **After save and committing state files**: run `pwsh tests/run-tests.ps1 -Case 05` to verify state consistency and baseline correctness.

**Why this order matters:**

- `case-06` checks the goal commit (HEAD at the time). It validates changed_files, commit message format, and artifact presence.
- `/dev-save` updates state files only. Committing those state files changes HEAD.
- `case-05` checks state consistency. It validates that state files are consistent and that `last_commit` matches HEAD~1.
- If you run `case-06` after committing state files, HEAD is now a state-sync commit, not a goal commit, so `case-06` fails on changed_files mismatch and commit format checks.

**Rule**: Always run `case-06` before committing state files. Always run `case-05` after committing state files.

---

## Rules for Safe Iteration

1. **One scoped objective at a time.** Do not combine unrelated changes in a single scope. Smaller scopes = easier review = faster saves.

2. **Avoid unrelated refactors.** If the scope is "fill placeholder," do not restructure the document format or rename sections. Refactors are their own scopes.

3. **Save frequently.** A save after every completed scope is the minimum. Longer gaps between saves increase drift risk.

4. **Status after session reset.** When returning to work, always run `/dev-status` before writing code. Never assume you remember the exact state correctly.

---

## Example Workflow

```
Session 1: Init → Scope "fill workflow-rules.md" → write content → case-06 → Save → case-05
Session 2: Status → Scope "run case-01 test" → execute tests → case-06 → Save → case-05
Session 3: Status → Scope "fix case-01 failure" → patch → case-06 → Save → case-05
```

In Claude Code: Init = `/dev-init`, Scope = `/dev-scope`, Save = `/dev-save`, Status = `/dev-status`.

Each session starts with state recovery, declares a focused scope, works within that scope, validates, saves, and validates again. No chat history needed.
