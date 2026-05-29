# v1.0 Readiness Re-check — After Patch Set 1

> **Date**: 2026-05-29
> **Scope**: Re-evaluate protocol maturity after critical workflow fixes
> **Rule**: Lightweight reassessment only. No new features. No large refactors.

---

## 1. What Improved Since Hard Review

### Resolved Findings

| Finding | Status | Evidence |
|---|---|---|
| **F1** — Path mismatch between `generate plan` and `continue loop` | **resolved** | Both now use `.agents/dev-protocol/next-phase-plan.md`. command-contracts.md updated. Case-41 PASS. |
| **F8** — Test matrix out of sync | **resolved** | docs/test-matrix.md completely rewritten. All case IDs match `tests/case-*` directories. Case-42 PASS. |
| **D3** — command-contracts.md omits semantic validation | **resolved** | continue-loop execution sequence now includes STEP 6 (semantic validation). Semantic drift and active-work sections added to /dev-status contract. |
| **D2** (partial) — dev-status SKILL.md duplicate numbering | **resolved** | Section "5. Output Summary" appearing after "8. Reconstruct Context" corrected to "9. Output Summary" during dogfood. |

### Architectural Strengths Confirmed

- **Canonical workflow is now viable**: `goal → generate plan → continue loop → /dev-save` executes without path ambiguity
- **Semantic validation layer is solid**: case-37~40 all PASS; equivalence rules, drift classification, and active-work inference are documented and tested
- **Test infrastructure is complete**: 42 cases mapped, 40 PASS, 2 pending (case-41/42 now PASS after Patch Set 1)
- **No HIGH severity friction remains open**: F1 was the only HIGH finding; it is fixed

---

## 2. Remaining Real Friction

### P0 — Must Fix Before v1.0

| ID | Finding | Why P0 | Effort |
|---|---|---|---|
| **F7** | `project-rules.md` contains false statements | New agents read this as source of truth. "No git history on master branch yet" and "/dev-save ... no git operations" are objectively false. Misleading rules erode trust in the state system. | Small |
| **F6** | Legacy alias skills carry stale complexity | `dev-checkpoint/PROMPT.md` still claims "NEVER stage files, NEVER auto-commit" (contradicts v2 `/dev-save`). `dev-resume/PROMPT.md` uses deprecated drift terms "none/minor/major". `dev-bootstrap/PROMPT.md` references legacy `.agent/` path. These files could be loaded accidentally and produce wrong behavior. | Small-Medium |
| **F9** | `/goal` has no skill definition | Inconsistent skill structure. `/goal` is documented in command-contracts but has no `skills/goal/` directory. Either create it or officially merge `/goal` into `/dev-scope`. | Small |

### P1 — Should Fix

| ID | Finding | Why P1 | Effort |
|---|---|---|---|
| **F2** | `goal-output` generation requires manual script execution | `fix-goal-output.ps1` derives `changed_files` from `git diff-tree HEAD`, not from working tree. During dogfood, the script reported `docs/test-matrix.md` (previous commit) instead of `skills/dev-status/SKILL.md` (current uncommitted change). This is real friction in the autonomous workflow promise. | Small |
| **F3** | Drift detection fails on first run | After `/dev-init`, `checkpoint.last_commit` is empty. First `/dev-status` skips diff-based drift comparison. User must run `/dev-save` before drift detection works. Observed during dogfood: checkpoint was `de259b8` but HEAD was `ae05536`; this would have been caught if init set baseline. | Small |
| **D2** (residual) | `dev-status` SKILL.md missing semantic sections | SKILL.md lacks explicit "Semantic drift classification" and "Semantic theme inference" headings that exist in PROMPT.md. The content is partially present (commit-type drift check, active work reconstruction) but not labeled consistently. | Small |

### P2 — Can Defer Post-v1.0

| ID | Finding | Why P2 |
|---|---|---|
| **F4** | Command overlap (`/dev-scope`, `/goal`, `continue loop`) | Auto-execution overlap is documented and predictable. Not a bug; a design choice. Consolidation is desirable but not blocking. |
| **F5** | Semantic classification relies on LLM judgment | Mitigated by deterministic rules added in Patch Set 1. Core semantic layer is intentionally LLM-driven. Acceptable for v1.0. |
| **F10** | Two `docs` directories create ownership ambiguity | No actual bugs caused by this. Boundary can be documented later. |
| **D1** | State file duplication | Four files track overlapping context. High maintenance burden, but no active failures. Merge is architectural cleanup, not bugfix. |
| **D4** | Incident logging only in deprecated skills | Not carried to v2, but also not causing failures. Can be removed or migrated post-v1.0. |
| **D5** | `goal-output` dual format (JSON + Markdown) | Doubles test complexity, but tests pass. Removing JSON is breaking cleanup, not critical. |
| **S1-S5** | Simplification opportunities | All are "nice to have" surface-area reductions. None block correctness. |

---

## 3. Problems No Longer Worth Fixing

| Problem | Rationale |
|---|---|
| **README.md test table only shows cases up to 26** | README already links to `docs/test-matrix.md` for the full matrix. Duplicating the full 42-case table in README would bloat the entry document. The link is sufficient. |
| **Stabilization-phase commit convention debates** | `chore(checkpoint)`, `chore(protocol)`, `chore(state)` are stable and tested (case-12). No new prefixes have been added for 3+ iterations. Convention is frozen enough. |
| **Multi-agent support, auto-repair, advanced hooks** | Explicitly out of v1.0 scope per roadmap. No reconsideration needed. |

---

## 4. Updated v1.0 Assessment

### Exit Criteria Progress

| Section | Criteria | Status |
|---|---|---|
| 6.1 Command Surface | Paths unified | **PASS** |
| 6.1 Command Surface | `/goal` has skill definition or is merged | **FAIL** (F9) |
| 6.1 Command Surface | Auto-execution deterministic | **PASS** |
| 6.1 Command Surface | No surprise overlaps | **PARTIAL** (F4 documented, not fixed) |
| 6.2 State Model | Only required state files mandatory | **PARTIAL** (goal-output and next-phase-plan still dual-managed) |
| 6.2 State Model | No stale info in project-rules.md | **FAIL** (F7) |
| 6.3 Skills | Consistent structure | **PARTIAL** (alias skills have stale PROMPT.md) |
| 6.3 Skills | SKILL.md and PROMPT.md synchronized | **PARTIAL** (D2 residual) |
| 6.4 Documentation | test-matrix synced | **PASS** |
| 6.4 Documentation | command-contracts current | **PASS** |
| 6.5 Testing | case-05 through case-42 pass | **PASS** |
| 6.6 Validation | No manual script required | **FAIL** (F2) |
| 6.6 Validation | Drift detection works from first use | **FAIL** (F3) |
| 6.7 Stability | No HIGH findings open | **PASS** |
| 6.7 Stability | No MEDIUM findings older than 2 iterations | **PARTIAL** (F2, F3 are older) |

### Scorecard

- **PASS**: 6 criteria
- **PARTIAL**: 5 criteria
- **FAIL**: 4 criteria

### Key Insight

The **core workflow is functionally complete and tested**. What remains is **onboarding hygiene** — removing false information, cleaning stale alias content, and adding a missing skill definition. These are small, bounded tasks with no architectural risk.

The protocol has crossed the threshold from "design gaps" to "organizational debt." Debt is real but does not block correctness.

---

## 5. Recommended Next Step

**B) Do one more focused patch set**

### Scope: "v1.0 Onboarding Hardening — Patch Set 2"

Strictly limited to:

1. **Fix F7** — Audit and correct `project-rules.md` false statements
2. **Fix F6** — Strip alias skill PROMPT.md files to redirect stubs (keep only SKILL.md with redirect note)
3. **Fix F9** — Create `skills/goal/PROMPT.md` and `SKILL.md`, or officially document `/goal` as merged into `/dev-scope`
4. **Fix D2 residual** — Add semantic section headings to `dev-status/SKILL.md` for consistency with PROMPT.md
5. **Fix F2** (optional, if time) — Make `fix-goal-output` script detect working-tree changes instead of HEAD-only

### Excluded

- No command behavior changes
- No state model refactoring
- No removal of auto-execution
- No new features
- No external project validation (can run in parallel or immediately after)

### Success Criteria

- All P0 items resolved
- All active tests still pass
- A new agent reading `project-rules.md` or any alias skill receives only true, current information
- Commit message: `fix(protocol): v1.0 onboarding hardening — remove stale content and false rules`

### After Patch Set 2

If Patch Set 2 succeeds without surprises:

→ **Enter v1.0 freeze preparation**

Freeze preparation means:
- Tag current state as `v1.0-rc1`
- Run external project validation (2 projects)
- Fix only regressions or critical bugs found during validation
- No new features, no refactors, no command changes

---

## Dogfood Workflow Notes

Executed during this re-check:

```
/dev-status → /dev-scope "fix numbering" → implement → /dev-save
```

**Observed friction**:

1. **Checkpoint stale on entry**: `checkpoint.last_commit` was `de259b8`, HEAD was `ae05536`. `/dev-status` would correctly report high drift, but this means every new session starts with a drift warning until `/dev-save` is run.
2. **Goal-output script wrong**: `fix-goal-output.ps1` reported `docs/test-matrix.md` (previous commit) instead of `skills/dev-status/SKILL.md` (current uncommitted change). Script uses `git diff-tree HEAD` instead of `git diff --cached` or `git status --short`.
3. **No ambiguity in simple scope**: Single-file, non-architectural fix was unambiguous. Auto-execution would have worked smoothly.

**Positive observations**:

- Canonical workflow (`goal → generate plan → continue loop → /dev-save`) is now path-unambiguous
- Semantic validation concepts are loaded in both PROMPT.md and SKILL.md
- Test matrix is trustworthy — case IDs match directories exactly
