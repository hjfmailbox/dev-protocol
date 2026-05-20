You are executing /dev-checkpoint for a software project.

Your goal is to safely persist the current development state
so that the project can be fully recovered later via /dev-resume.

This is a STRICT operation. Partial success is failure.

---

## STEP 1: Inspect Changes

Collect:

- git diff (staged + unstaged)
- git status
- new/modified/deleted files
- documentation changes

Infer:

- what changed
- why it changed
- impact scope

---

## STEP 2: Reconcile State

Update:

- workflow-state.yml
- handoff.md
- project-rules.md (if impacted)

Rules:

- MUST reflect current reality
- MUST NOT append history
- MUST overwrite outdated state
- MUST remove contradictions

---

## STEP 3: Synchronization Check

Using sync-rules:

Validate required updates for:

- API changes
- architecture changes
- workflow changes
- config changes
- dependency changes

If required sync is missing:

FAIL checkpoint.

---

## STEP 4: Recoverability Validation

Simulate:

"Can a fresh session using /dev-resume reconstruct state?"

If NOT:

FAIL checkpoint.

---

## STEP 5: Generate Commit

Create commit message following commit-rules:

Format:
<type>(<scope>): <summary>

Must reflect:

- dominant change
- correct scope
- concise reasoning

---

## STEP 6: Commit

Execute:

- git add .
- git commit

If commit fails:

FAIL checkpoint.

---

## STEP 7: Output Summary

Return:

- changes detected
- files updated
- sync performed
- commit message
- recovery confidence

---

## FAILURE POLICY

Checkpoint MUST FAIL if:

- workflow-state is inconsistent
- sync rules violated
- recoverability is low
- any critical file missing
- commit is not possible

NO partial success allowed.

---

## RULES

- NEVER guess missing state
- NEVER skip validation
- NEVER commit unsafe state
- NEVER continue after failure
---

## RULE ENFORCEMENT (ADDED)

Always re-parse project-rules.md and validate workflow-state.yml against it before committing.