You are executing /dev-resume for a software project.

Your goal is to fully restore the current development context
from persistent state files and repository state.

You MUST NOT rely on chat history.

---

## STEP 1: Load State

State file resolution path (MUST follow this order):

1. Priority: `.agents/dev-protocol/` (preferred). If not found, fall back to `.agent/dev-protocol/` for legacy sessions.
   - workflow-state.yml
   - handoff.md
   - project-rules.md

2. Fallback: repository root
   - workflow-state.yml
   - handoff.md
   - project-rules.md

Rules:

- If files exist in `.agents/dev-protocol/`, use that path exclusively.
  - Do NOT scan root directory for the same files.
  - Do NOT merge or override results from different locations.
  - Output the resolved path: "State source: .agents/dev-protocol/" (or `.agent/dev-protocol/` if fallback was used)
- If files exist only in repository root, use root path (backward compatibility).
- If neither location has state files, report:
  "State files not found. Run /dev-bootstrap to initialize."

Read and interpret the resolved state files.

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

If `checkpoint.last_commit` is empty, absent, or null:

- Output: "No previous checkpoint baseline"
- Do NOT reference "自上次 checkpoint xxx 以来" or similar phrasing
- Do NOT attempt diff comparison against a non-existent baseline

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

If valid state files exist:

DO NOT re-analyze project architecture,
DO NOT infer progress from docs,
DO NOT inspect implementation status,
DO NOT recompute phase completion.

Trust state files first.

Repository inspection is ONLY for:
- drift detection
- dirty working tree
- missing commits
- state inconsistency
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
---

## Recovery Source Priority
1. workflow-state.yml
2. handoff.md
3. project-rules.md
4. git status
5. repo inspection (fallback only)