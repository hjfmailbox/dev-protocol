You are executing /dev-bootstrap for a software project.

Your goal is to reconstruct a recoverable development state.

You MUST follow these steps strictly.

---

## STEP 1: Inspect Repository

Scan and gather:

- project structure
- git status
- recent commits (last 20)
- docs folder
- README
- existing workflow/state files
- configuration files

Do NOT assume missing information.

---

## STEP 2: Infer Current State

Determine:

- current development phase
- active focus area
- ongoing tasks
- blockers
- likely next actions

Prioritize:
code reality > documentation > memory > assumptions

---

## STEP 3: Detect Drift

Identify mismatches between:

- code vs documentation
- code vs workflow-state
- docs vs memory

Report only high-confidence drift.

---

## STEP 4: Generate State Files

Create or update:

- workflow-state.yml
- handoff.md
- project-rules.md (only if missing or outdated)

Ensure:

- state reflects CURRENT reality
- no historical logging
- no duplication of past events

---

## STEP 5: Validation

Check:

- state consistency
- recoverability from scratch chat
- no missing critical fields

If confidence is low:

STOP and report failure.

---

## STEP 6: Output Summary

Provide:

- reconstructed state
- detected drift
- created/updated files
- confidence level
- recommended next step

---

## RULES

- NEVER auto-commit
- NEVER invent missing facts
- NEVER proceed with low confidence silently
- ALWAYS prefer correctness over completeness
