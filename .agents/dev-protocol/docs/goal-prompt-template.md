# Goal Prompt Template (v0)

Use this template when declaring a Goal.

In Claude Code, this maps to the `/goal` command. Other runtimes may use function calls, chat prompts, or structured API requests with equivalent fields.

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

**Critical: changed_files generation (deterministic script required)**

After writing the artifact, you MUST run the fix script to set changed_files:

```powershell
# Windows
pwsh scripts/fix-goal-output.ps1
```

```bash
# Unix/Linux/Mac
./scripts/fix-goal-output.sh
```

**Why this is mandatory:**

The LLM is not trusted to generate file lists. Even with explicit instructions,
the LLM omits or rewrites files. The script uses `git diff-tree` to extract the
authoritative file list and overwrites the `## Changed Files` section.

**Workflow:**

1. Commit goal changes
2. Write goal-output.md (with any placeholder for changed_files)
3. Run the fix script
4. Verify script output shows correct file count
5. Proceed to terminal summary

The script is deterministic and makes changed_files drift impossible.

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