# Deferred Improvements

Items explicitly postponed during dev-protocol development.
Only consciously deferred items — no brainstormed ideas.

---

## 1. Session output capture for output contract automation

**Why deferred:** The goal output contract (Goal Status, Goal Summary, Stop Reason, etc.) exists only as session terminal text. `run-tests.ps1` cannot validate these sections without capturing session output to a file. This requires logging infrastructure outside the current architecture scope.

**Suggested revisit trigger:** Output contract violations slip through manual review twice in a row.

**Priority:** High

---

## 2. Duplicate state files (root + `.agent/dev-protocol/`)

**Status:** Completed

Root duplicate state files (`workflow-state.yml`, `handoff.md`, `project-rules.md`) were removed from git tracking. `.agent/dev-protocol/` is now the sole authoritative state location. Skills already read/write exclusively to `.agent/dev-protocol/`; dev-resume fallback to root is preserved as dead code but never triggered since `.agent/dev-protocol/` always exists.

---

## 3. 10-file scope threshold has no empirical basis

**Why deferred:** The case-06 threshold (`HEAD changed ≤10 files`) was chosen arbitrarily. No data exists on typical goal commit sizes in real usage. The threshold may be too loose (misses broad changes) or too tight (false-FAILs legitimate goals).

**Suggested revisit trigger:** Legitimate goals consistently trigger or bypass this threshold, indicating it is mis-calibrated.

**Priority:** Low

---

## 4. Continuation handoff not validated

**Why deferred:** The continuation handoff (context, boundary, prompt seed) is documented as required in the output contract but has no automated validation. Same limitation as item 1 — it is session text, not a file artifact. Cannot be automated without session output capture.

**Suggested revisit trigger:** Item 1 (session output capture) is implemented.

**Priority:** Medium (depends on item 1)

---

## 5. Redundant git diff checks in case-06

**Why deferred:** Section E of `run-tests.ps1` re-asserts `git diff --quiet` and `git diff --cached --quiet` which are already checked in section A for all cases. This is intentional for explicit documentation but adds redundancy.

**Suggested revisit trigger:** The file grows large enough that reducing redundancy becomes a readability concern.

**Priority:** Low

---

## 6. Continuation handoff prompt hardening

**Why deferred:** Cold-start recovery worked only after explicitly forbidding repository scanning and prior assumptions. The original continuation prompt was too weak and allowed the agent to expand scope, recovering global repo context instead of the current development phase.

**Suggested revisit trigger:** Cold-start recovery fails again or agents repeatedly expand beyond documented continuation boundaries.

**Priority:** Medium

---

## 7. NO_OP goals do not generate goal-output artifacts

**Why deferred:** A goal that completes without changing any files (NO_OP — e.g., "add documentation that already exists", "refactor that is already clean") may not produce `goal-output.json` or `goal-output.md`. Case-06 will FAIL on artifact absence even though the goal completed legitimately. This creates false FAILs for valid no-change goals.

**Suggested revisit trigger:** A legitimate NO_OP goal consistently triggers case-06 FAIL, indicating the artifact requirement is too strict for goals that produce no file changes.

**Priority:** Medium

## 8. Bash heredoc artifact emission may silently fail on Windows

**Why deferred:** During /goal validation, Claude reported successful
creation of `.agent/dev-protocol/goal-output.json` using bash heredoc
syntax (`cat > file <<EOF`) but no file was actually written.
PowerShell-native file creation succeeded immediately.

This appears to be an agent shell reliability issue rather than a
protocol design problem.

**Suggested revisit trigger:** Repeated missing artifact incidents
despite case-06 contract enforcement.

**Priority:** Medium