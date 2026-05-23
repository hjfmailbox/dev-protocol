# /dev-resume

## Purpose

Recover development context from durable project state.

Goal:

Allow development to continue without prior chat history.

---

## Responsibilities

### 1. Read Recoverable State

State file resolution (MUST follow this order):

1. **Priority**: `.agents/dev-protocol/` (preferred). If not found, fall back to `.agent/dev-protocol/` for legacy sessions.
   - workflow-state.yml
   - handoff.md
   - project-rules.md
   - If found here, use this path exclusively.
   - Output the resolved path in recovery summary.
   - Do NOT scan root for the same files.

2. **Fallback**: repository root
   - workflow-state.yml
   - handoff.md
   - project-rules.md
   - Used only when `.agents/dev-protocol/` does not contain state files.

3. **Missing**: if neither location has state files:
   - Report: "State files not found. Run /dev-bootstrap to initialize."

If available, also inspect:

- CLAUDE.md
- AGENTS.md
- project memory files

---

### 2. Inspect Repository State

Must inspect:

- git status
- uncommitted changes
- recent commits

Must warn if repository is dirty.

---

### 3. Validate State Freshness

Check for mismatch between:

- workflow state
- repository reality

If `checkpoint.last_commit` is empty, absent, or null:

- Output: "No previous checkpoint baseline"
- Do NOT reference "since last checkpoint xxx" phrasing
- Skip diff-based drift comparison

Examples:

- task marked completed but unfinished
- docs contradict code
- handoff appears outdated

Must warn on inconsistency.

---

### 4. Generate Recovery Summary

Must summarize:

- current phase
- active focus
- completed progress
- blockers
- recommended next actions

Summary should be concise and action-oriented.

---

## Failure Rules

Resume fails if:

- recoverable state is missing
- repository is corrupted
- state inconsistency is too severe

Must recommend:

/dev-bootstrap
if recoverable state does not exist.
