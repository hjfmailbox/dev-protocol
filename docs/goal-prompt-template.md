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

Must include:

```text
Goal Status
Goal Summary
Changed Files
Validation Results
Stop Reason
Risks / Follow-ups
```