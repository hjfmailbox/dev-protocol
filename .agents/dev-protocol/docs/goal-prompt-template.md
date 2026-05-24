# Goal Prompt Template (v0)

Use this template when running `/goal`.

---

## Goal

<clear objective>

Example:

```text
Add automated validation for checkpoint baseline consistency
```

---

## Scope

Allowed files:

```text
<explicit file list>
```

Forbidden:

- unrelated refactor
- broad architecture changes
- unrelated file modifications

---

## Stop Conditions

Stop immediately when:

- goal is completed
- validation passes
- requirements become ambiguous
- repeated failures occur
- git state becomes unsafe
- scope unexpectedly expands

Do not continue indefinitely.

---

## Validation

Before stopping:

1. Run existing relevant tests
2. Add focused validation if missing
3. Verify git state

Required commands:

```powershell
git status
git diff
git diff --cached
git log --oneline -3
```

---

## Safety Rules

Never:

- modify unrelated files silently
- skip validation
- auto-commit unrelated work
- assume unclear requirements

Ask for clarification when confidence is low.

---

## Required Final Output

Before stopping, MUST perform both:

### A. Write Output Artifact

Write at least one artifact:

- `.agents/dev-protocol/goal-output.json` (preferred when feasible)
- `.agents/dev-protocol/goal-output.md` (fallback when JSON is impractical)

The artifact must contain all required sections per `.agents/dev-protocol/docs/goal-output-contract.md`.
This is mandatory — a completed goal without at least one artifact is incomplete.

**Critical: changed_files generation**

The `changed_files` field MUST be derived from git, not memory:

1. After committing goal changes, run:
   ```bash
   git diff-tree --no-commit-id --name-only -r HEAD
   ```
2. Use the command output verbatim as the `changed_files` value
3. Do NOT manually list files from memory or task tracking
4. Do NOT omit files, even if they seem minor (.gitignore, README.md, docs)

Large goals often touch 15+ files. Only git state is authoritative.
Manual lists will fail case-06 validation.

### B. Terminal Summary

Must include:

```text
Goal Status
Goal Summary
Changed Files
Validation Results
Stop Reason
Risks / Follow-ups
Continuation Handoff
```