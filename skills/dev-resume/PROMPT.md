You are executing /dev-resume for a software project.

Your goal is to fully restore the current development context
from persistent state files and repository state.

You MUST NOT rely on chat history.

---

## STEP 1: Load State

Read and interpret:

- workflow-state.yml
- handoff.md
- project-rules.md (if exists)

If missing, note degradation risk.

---

## STEP 2: Inspect Repository

Run a full lightweight inspection:

- git status
- git log (recent 20 commits)
- uncommitted changes
- project structure overview

Detect divergence between state and reality.

---

## STEP 3: Validate State Freshness

Check whether:

- workflow-state matches code reality
- handoff is outdated
- tasks marked complete are actually complete
- blockers still exist or resolved

Classify drift:

- none
- minor
- major

---

## STEP 4: Reconstruct Execution Context

Rebuild:

- current phase
- active focus
- in-progress tasks
- blockers
- next actions

Must prioritize:
code reality > workflow-state > handoff > rules

---

## STEP 5: Output Recovery Summary

Output:

- current state summary
- detected drift
- confidence level
- recommended next actions

Keep concise and actionable.

---

## RULES

- NEVER modify files
- NEVER commit
- NEVER assume missing state
- NEVER proceed if state is inconsistent without warning
- ALWAYS favor correctness over completeness
---

## REPOSITORY INSPECTION (MANDATORY)

Before generating recovery summary:

You MUST inspect repository reality.

Required checks:

1. git status
- branch
- working tree clean/dirty
- modified/untracked files

2. git log -1
- latest commit hash
- latest commit message

3. drift detection
Compare:
- workflow-state.yml
- handoff.md
- git reality

Classify drift severity:
- NONE
- LOW
- HIGH

Recovery summary MUST include:

- current phase
- latest commit
- working tree state
- drift severity
- blockers
- recommended next action