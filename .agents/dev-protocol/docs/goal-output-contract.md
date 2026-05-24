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
.agents/dev-protocol/docs/goal-workflow.md
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

---

## Artifact Contract (Machine-Validated)

At goal completion, write `.agents/dev-protocol/goal-output.json` containing all
required sections as structured data. This file is untracked (gitignored) and
exists solely for automated validation by case-06.

**The output artifact is mandatory.** A completed goal without either
`goal-output.json` or `goal-output.md` is incomplete and will fail case-06
validation. The goal prompt template (`.agents/dev-protocol/docs/goal-prompt-template.md`) enforces
this requirement by instructing the agent to write the artifact before stopping.

### Markdown Fallback

If `goal-output.json` is malformed or absent, case-06 falls back to
`.agents/dev-protocol/goal-output.md`. The markdown file must contain all seven
required section headers (Goal Status, Goal Summary, Changed Files, Validation
Results, Stop Reason, Risks / Follow-ups, Continuation Handoff) with matching
text. The markdown fallback validates section presence and goal_status enum but
does NOT cross-check `changed_files` against `git diff-tree`.

Prefer JSON when possible; use markdown as a safety net when JSON serialization
fails.

### Required Schema

```json
{
  "goal_status": "COMPLETED",
  "goal_summary": "Short description of what changed",
  "changed_files": ["docs/example.md"],
  "validation_results": ["PASS: automated validation"],
  "stop_reason": "Goal completed successfully",
  "risks_followups": ["Unresolved concern X"],
  "continuation_handoff": {
    "context": "What the next goal needs to know",
    "boundary": "What was intentionally NOT changed",
    "next_candidate_goal": "One concrete follow-up suggestion",
    "prompt_seed": "/goal\n\n## Goal\n<one-sentence objective>"
  }
}
```

### Field Definitions

| Field | Type | Required | Notes |
|---|---|---|---|
| `goal_status` | string | Yes | Must be one of: `COMPLETED`, `PARTIALLY_COMPLETED`, `BLOCKED`, `FAILED`, `ABORTED` |
| `goal_summary` | string | Yes | Short description of what changed |
| `changed_files` | array[string] | Yes | Paths relative to repo root |
| `validation_results` | array[string] | Yes | Result strings from validation |
| `stop_reason` | string | Yes | Explicit explanation of why execution stopped |
| `risks_followups` | array[string] | Yes | May be empty `[]` if none |
| `continuation_handoff` | object | Yes | Must contain all 4 sub-fields |

### Handoff Sub-Fields

| Sub-Field | Type | Required | Notes |
|---|---|---|---|
| `context` | string | Yes | Context to carry forward |
| `boundary` | string | Yes | What was intentionally NOT changed |
| `next_candidate_goal` | string | Yes | Concrete follow-up suggestion |
| `prompt_seed` | string | Yes | Ready-to-use `/goal` prompt text |

### Integrity Rule

`changed_files` must exactly match `git diff-tree --no-commit-id --name-only -r HEAD`.
Any mismatch is a validation failure.

### Mandatory Generation Procedure (Deterministic Script-Based)

`changed_files` MUST be programmatically derived from git state at artifact write time.

**LLM involvement in changed_files generation is prohibited.**

Prompt-level enforcement has proven insufficient. The LLM rewrites or omits files
even when instructed to use git output verbatim. This procedure eliminates LLM
responsibility entirely.

**Required execution order:**

1. Complete all goal implementation work
2. Commit the goal changes (one commit per goal)
3. Write the goal-output artifact (with placeholder or approximate changed_files)
4. **Run the deterministic fix script:**
   ```powershell
   # Windows
   pwsh scripts/fix-goal-output.ps1
   ```
   ```bash
   # Unix/Linux/Mac
   ./scripts/fix-goal-output.sh
   ```
5. The script overwrites the `## Changed Files` section with authoritative git state
6. Verify the script output shows the correct file count

**What the script does:**

1. **changed_files (deterministic):**
   - Runs `git diff-tree --no-commit-id --name-only -r HEAD`
   - Extracts authoritative file list from git state
   - Overwrites `changed_files` field in JSON and `## Changed Files` section in Markdown

2. **Schema validation and auto-fix:**
   - Validates `validation_results` is an array (converts string to single-element array if needed)
   - Validates `risks_followups` is an array (converts string to single-element array if needed)
   - Validates `goal_status` is one of: COMPLETED, PARTIALLY_COMPLETED, BLOCKED, FAILED, ABORTED
   - Validates `continuation_handoff` is an object with required fields (context, boundary, next_candidate_goal, prompt_seed)
   - Reports all schema fixes applied

**Why this works:**

The script is deterministic for changed_files (byte-for-byte equivalent to git state)
and enforces schema compliance (all fields have correct types). The LLM never touches
the file list, and schema violations are automatically corrected before the stop hook
validates the artifact.

This eliminates two failure modes:
1. changed_files drift (LLM omits or rewrites files)
2. Schema violations (LLM uses wrong types for fields)

**Prohibited approaches:**

- Manual file lists from remembered edits
- Inferred file paths from task descriptions
- Partial tracking during implementation
- Session memory of which files were touched
- LLM formatting or paraphrasing of file lists
- Prompt reminders to "use git"

**Validation guarantee:**

case-06 cross-checks `changed_files` against `git diff-tree HEAD`. After running
the script, the check will always pass because both use identical git commands.

**Script location:**

- PowerShell: `scripts/fix-goal-output.ps1`
- Bash: `scripts/fix-goal-output.sh`

Both scripts are committed to the repository and portable across projects.