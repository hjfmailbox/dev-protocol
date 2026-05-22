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

**Why deferred:** State files (`workflow-state.yml`, `handoff.md`, `project-rules.md`) exist in both the repository root and `.agent/dev-protocol/`. The skill docs (`dev-bootstrap`, `dev-checkpoint`, `dev-resume`) now all specify `.agent/dev-protocol/` as the canonical path — root copies are legacy compatibility only. However, root copies are still git-tracked and have not been removed or `.gitignore`'d. Content divergence between the two copies exists (e.g. `workflow-state.yml.checkpoint.last_commit` differs).

**Suggested revisit trigger:** A checkpoint or resume behavior writes to the wrong location due to ambiguity, or root copies become an active source of confusion.

**Priority:** Medium

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