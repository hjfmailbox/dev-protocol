# Deferred Improvements

Items explicitly postponed during dev-protocol development.
Only consciously deferred items — no brainstormed ideas.

---

## 1. Session output capture for output contract automation

**Why deferred:** The goal output contract (Goal Status, Goal Summary, Stop Reason, etc.) exists only as session terminal text. `run-tests.ps1` cannot validate these sections without capturing session output to a file. This requires logging infrastructure outside the current architecture scope.

**Suggested revisit trigger:** Output contract violations slip through manual review twice in a row.

**Priority:** High

---

## 2. Duplicate state files (root + `.agents/dev-protocol/`)

**Status:** Completed

Root duplicate state files (`workflow-state.yml`, `handoff.md`, `project-rules.md`) were removed from git tracking. `.agents/dev-protocol/` is now the sole authoritative state location. Skills already read/write exclusively to `.agents/dev-protocol/`; dev-resume fallback to root is preserved as dead code but never triggered since `.agents/dev-protocol/` always exists.

---

## 9. Runtime directory migration: `.agent/` → `.agents/`

**Status:** Completed

The runtime directory was renamed from `.agent/dev-protocol/` to `.agents/dev-protocol/`. Backward compatibility is preserved in `/dev-resume` (prefers `.agents/`, falls back to `.agent/`). The `.agent/` fallback is dead code until a future cleanup removes it entirely.

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
creation of `.agents/dev-protocol/goal-output.json` using bash heredoc
syntax (`cat > file <<EOF`) but no file was actually written.
PowerShell-native file creation succeeded immediately.

This appears to be an agent shell reliability issue rather than a
protocol design problem.

**Suggested revisit trigger:** Repeated missing artifact incidents
despite case-06 contract enforcement.

**Priority:** Medium

## 9. Standardize test numbering and remove placeholder gaps

**Why deferred:** Current test layout contains only active
`case-05-first-checkpoint` and `case-06-goal-workflow`, while
`case-01` through `case-04` were historical placeholders or removed
during iteration. This creates numbering ambiguity and makes the
test suite look incomplete.

Possible future approaches:

- renumber existing cases (`05 → 01`, `06 → 02`)
- restore lightweight placeholder cases
- explicitly document numbering history

No functional impact today.

**Suggested revisit trigger:** Major test-suite cleanup or public
release preparation.

**Priority:** Low

## 10. Clarify `.agents` directory convention

**Why deferred:** Protocol state migrated from `.agent/` to
`.agents/` to align with broader multi-agent ecosystem conventions
and shared skill discovery. However, directory rationale and naming
decision are not yet explicitly documented.

Potential confusion:

- `.agent` vs `.agents`
- relationship with `.claude/skills`
- cross-agent compatibility expectations

**Suggested revisit trigger:** Documentation cleanup or onboarding
friction from new projects.

**Priority:** Medium

## 11. Real-project validation checklist

**Why deferred:** The protocol has now been validated end-to-end
against a real project (DesignDocMCP), but the validation sequence
exists only in chat history and is not formalized.

A reusable checklist would improve confidence when onboarding new
projects.

Suggested scope:

- `/dev-bootstrap`
- `/dev-checkpoint`
- `/dev-resume`
- `/goal`
- `case-05`
- `case-06`

**Suggested revisit trigger:** Second real-project adoption or
public release preparation.

**Priority:** Low

## 12. Clarify case-05 and case-06 execution order

**Why deferred:** Real-project validation revealed ambiguity in
the expected validation sequence.

`case-06` validates a completed `/goal` commit and its associated
goal-output artifact. However, after `/dev-checkpoint`, HEAD changes
to a checkpoint commit, causing `case-06` to fail due to
changed_files mismatch.

`case-05` validates `/dev-checkpoint` behavior and therefore must
run after checkpoint.

Expected order should be explicitly documented:

`/goal → case-06 → /dev-checkpoint → case-05`

**Suggested revisit trigger:** Protocol documentation cleanup or
further real-project validation.

**Priority:** High

## 13. /dev-checkpoint commit message contract may not be enforced

**Why deferred:** During real-project validation, `/dev-checkpoint`
appeared to reuse the previous goal commit message instead of
creating a checkpoint-style commit message expected by `case-05`.

This caused:

`HEAD commit does not indicate a checkpoint baseline`

Potential causes:

- commit reuse behavior
- skipped checkpoint commit path
- prompt ambiguity

**Suggested revisit trigger:** Repeated case-05 failures after
successful checkpoint execution.

**Priority:** High

## 14. /dev-resume may restore outdated project phase

**Why deferred:** During real-project validation, `/dev-resume`
restored the repository as:

`p1 — protocol-definition-and-bootstrap`

despite the project having already completed:

- bootstrap
- checkpoint
- resume
- real-project validation
- runtime migration
- README onboarding
- protocol hardening

This suggests either:

- workflow-state phase progression is not being updated
- `/dev-checkpoint` does not persist phase changes
- `/dev-resume` over-relies on stale persisted state

Recovery context remained usable, but project maturity was
significantly underestimated.

**Suggested revisit trigger:** Repeated phase mismatch after
successful checkpoint/resume cycles.

**Priority:** High

## 15. /dev-resume repository status freshness may drift

**Why deferred:** During real-project validation, `/dev-resume`
reported:

`workspace clean (1 modified file: deferred-improvements.md)`

after a successful `/dev-checkpoint` where the workspace was
already clean.

This suggests resume may rely partially on persisted metadata
instead of fully recomputing current repository state from git.

Potential causes:

- stale handoff/workflow-state synchronization
- cached repository status
- insufficient runtime git refresh during resume

Context reconstruction remained functional, but repository
freshness reporting was inaccurate.

**Suggested revisit trigger:** Repeated resume outputs that
contradict `git status`.

**Priority:** Medium