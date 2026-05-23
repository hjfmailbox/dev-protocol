# v1 Retrospective

Post-MVP retrospective after real-project validation (DesignDocMCP) and protocol self-dogfooding.

---

## 1. What Worked

**Bootstrap / Checkpoint / Resume Lifecycle**

The three core commands (`/dev-bootstrap`, `/dev-checkpoint`, `/dev-resume`) functioned as a complete recovery cycle. Cold-start resume successfully reconstructed development context from state files alone, without chat history. State file resolution (`.agents/dev-protocol/` preferred, root fallback preserved) worked correctly.

**Goal Artifact Contract**

`goal-output.json` and `goal-output.md` provided machine-readable and human-readable goal completion records. Case-06 validation (17 checks) consistently caught deviations in file scope, commit messages, and artifact presence.

**Case-05 / Case-06 Validation**

Both test scripts proved effective:
- case-05 validated checkpoint idempotency and commit message contract
- case-06 validated goal workflow compliance (changed file count, forbidden files, artifact presence, commit message quality)
- 17/17 checks passed on final validation run

**Real-Project Validation Success**

The protocol was validated end-to-end against a real project (DesignDocMCP) and then applied to itself (dogfooding). Full structure was established: state files, skills, references, tests, and documentation. All v1 scope items (single-agent only, three core commands, three state files) delivered.

---

## 2. What Failed or Caused Friction

**`.agent` → `.agents` Migration Issue**

Runtime directory was renamed from `.agent/dev-protocol/` to `.agents/dev-protocol/` mid-development to align with multi-agent ecosystem conventions. This caused:
- Skill path references needing updates
- Temporary duplicate state files (resolved by removing root copies)
- Resume fallback logic preserving dead `.agent/` code path

**Windows Artifact Emission Reliability Issue**

Bash heredoc syntax (`cat > file << 'EOF'`) silently failed to create files on Windows agent shell. PowerShell-native file creation (`Write-Host` / `Out-File`) succeeded immediately. This caused goal-output artifacts to be reported as created but not actually written to disk, triggering case-06 failures.

**Rebase Affecting last_commit**

After a git rebase, the `checkpoint.last_commit` pointer in `workflow-state.yml` became stale — pointing to commits that no longer existed in the rewritten history. The checkpoint sync step caught this but required manual intervention to update the SHA.

**Confusion Between Checkpoint Commit vs Checkpoint Baseline**

During real-project validation, `/dev-checkpoint` occasionally reused the previous goal commit message instead of creating a distinct checkpoint-style commit. This caused case-05 to fail with "HEAD commit does not indicate a checkpoint baseline." The distinction between "a commit that records checkpoint state" and "the baseline commit that checkpoint points to" was not consistently enforced.

---

## 3. Deferred Improvements Worth Revisiting

**High Priority:**
- **Session output capture** — goal output contract validation currently relies on manual review. Automated validation requires capturing session terminal output to a file.
- **Case-05 / case-06 execution order** — documented ambiguity: `case-06` must run before `/dev-checkpoint` (which changes HEAD), but `case-05` must run after. Order should be `goal → case-06 → checkpoint → case-05`.
- **Checkpoint commit message contract** — commit message format not consistently enforced, causing case-05 false failures.
- **Phase drift on resume** — `/dev-resume` occasionally restored stale phase (p1) despite project having progressed beyond p2. Suggests checkpoint does not always persist phase changes.

**Low Priority:**
- **10-file scope threshold** (case-06) — arbitrary, no empirical calibration data.
- **Redundant git diff checks** in case-06 — intentional for documentation clarity but adds redundancy.
- **Test numbering gaps** (case-01 through case-04) — historical placeholders, no functional impact.
- **Real-project validation checklist** — exists only in chat history, not formalized.

**Medium Priority (depends on above):**
- **Continuation handoff validation** — blocked on session output capture.
- **NO_OP goals without artifacts** — goals that produce no file changes should not require goal-output files.
- **Repository status freshness** — resume occasionally reports stale git status from persisted metadata.

---

## 4. Decisions Made

**`.agents/dev-protocol/` Chosen as Runtime Location**

Selected over `.agent/dev-protocol/` to align with multi-agent ecosystem conventions and enable shared skill discovery. Backward compatibility fallback to `.agent/` preserved in `/dev-resume` as dead code.

**Markdown Fallback Retained**

State files use YAML (`workflow-state.yml`) and Markdown (`handoff.md`, `project-rules.md`) formats. No JSON-only or binary formats introduced. Markdown chosen for human readability and LLM comprehension.

**Protocol Frozen After MVP Validation**

After successful validation against a real project and self-dogfooding, v1 scope is considered complete. No further changes to workflow behavior, checkpoint logic, or state file structure within v1. Deferred items catalogued for potential future work.

---

## 5. Exit Criteria for v1

MVP is considered complete because:

1. All three core commands (bootstrap, checkpoint, resume) are defined, implemented as skills, and validated against real project usage.
2. State file structure (workflow-state.yml, handoff.md, project-rules.md) is complete and functional.
3. Validation tests (case-05, case-06) pass consistently (17/17 checks).
4. Protocol successfully dogfooded on itself — the dev-protocol project was built using its own workflow.
5. Deferred improvements are catalogued with priority and revisit triggers, providing a clear backlog without blocking v1 freeze.

No speculative v2 features, no multi-agent support, no auto-repair, no advanced hooks — all explicitly out of scope for v1 and not delivered.
