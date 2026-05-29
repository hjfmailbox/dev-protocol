# v1.0 Freeze Preparation

> **Date**: 2026-05-29
> **Status**: Freeze candidate
> **Rule**: No new features. No redesign. No protocol expansion.

---

## 1. Protocol Scope

What dev-protocol v1.0 officially supports.

### Core Commands

| Command | Status | Guarantee |
|---|---|---|
| `/dev-init` | v1.0 | Stable — initializes state, never auto-commits |
| `/dev-status` | v1.0 | Stable — read-only, semantic drift classification, phase/focus inference |
| `/dev-scope` | v1.0 | Stable — scope declaration, auto-execution for simple scopes |
| `/dev-save` | v1.0 | Stable — protocol-only checkpoint commits, no-op save support |
| `/goal` | v1.0 | Stable — implementation phase, goal-output artifact production |
| `generate plan` | v1.0 | Stable — decomposes goals into numbered loops |
| `continue loop` | v1.0 | Stable — plan-aware execution with semantic validation |

### Workflow Patterns

| Pattern | Status | Guarantee |
|---|---|---|
| Canonical workflow | v1.0 | `goal → generate plan → continue loop → /dev-save` is path-unambiguous |
| Auto-execution | v1.0 | Deterministic 7-criteria evaluation |
| Semantic validation | v1.0 | Equivalence rules, drift classification, active-work inference |
| Checkpoint safety | v1.0 | Protocol commits never include source changes |
| No-op validation | v1.0 | Clean workspace produces valid checkpoint |

### State Model

| File | Status | Guarantee |
|---|---|---|
| `workflow-state.yml` | v1.0 | Format frozen |
| `handoff.md` | v1.0 | Format frozen |
| `project-rules.md` | v1.0 | Format frozen |
| `next-phase-plan.md` | v1.0 | Continue-loop compatible loop format |
| `goal-output.md` / `goal-output.json` | v1.0 | Artifact format frozen |

### Test Coverage

- **42 machine-testable cases** defined in `docs/test-matrix.md`
- **All active cases PASS**: case-05 through case-44
- **Test infrastructure**: `tests/run-tests.ps1` validates static contracts and prompt keywords

---

## 2. Explicit Non-Goals

What v1.0 intentionally does NOT solve.

| Non-Goal | Rationale |
|---|---|
| **Automatic plan generation from arbitrary intent** | `generate plan` requires context and inferable goals. Vague intent still needs `/dev-scope` clarification. |
| **Full autonomous orchestration** | Human confirmation required for architectural scopes, ambiguous plans, and dirty workspaces. |
| **Perfect semantic understanding** | Semantic validation reduces false negatives but still relies on LLM judgment. Deterministic rules are the floor, not the ceiling. |
| **Multi-agent coordination** | Protocol assumes single-agent execution. Concurrent agents may corrupt state. |
| **Runtime-specific guarantees** | Hook lifecycle, task termination, and session compaction behavior vary across Claude Code, Cursor, Trae, Roo. Protocol core is runtime-agnostic; edge cases are runtime-specific. |
| **External project validation automation** | Real-project validation is manual. No CI integration for protocol behavior. |

---

## 3. Stable Guarantees

### Canonical Workflow Stability

The canonical workflow path is frozen:

```
/dev-init → /dev-status → generate plan → continue loop → /dev-save
                     ↓
               /dev-scope → /goal (when no plan exists)
```

- Path unification verified: `generate plan` and `continue loop` both use `.agents/dev-protocol/next-phase-plan.md` (case-41 PASS)
- No command may bypass `/dev-scope` or `/dev-save` semantics

### Checkpoint Safety

- `/dev-save` stages ONLY `.agents/dev-protocol/*` files
- Protocol commits (`chore(checkpoint):`) NEVER contain source code
- Mixed staged files (protocol + source) are rejected (case-13 PASS)
- No-op saves on clean workspace produce valid checkpoint commits (case-08 PASS, case-23 PASS)

### Git Reality Precedence

When state and git reality conflict, git reality wins:

- Focus inference: git-derived focus > workflow-state focus when checkpoint is stale (case-16 PASS)
- Phase inference: git reality > workflow-state > handoff > roadmap > unknown (case-14 PASS)
- Active work reconstruction: derived from recent conventional commits, not stale state (case-18 PASS)

### Semantic Completion Behavior

- Validation criteria are interpreted semantically, not literally (case-37 PASS)
- Loop completion detected via git reality, test outcomes, and commit intent (case-38 PASS)
- Non-equivalence signals respected: "started" ≠ "completed", "partial" ≠ "fully resolved"

### Continue Loop Deterministic Constraints

- Preconditions verified before execution (plan exists, workspace clean, no blockers, no drift)
- Auto-execution criteria identical to `/dev-scope` (7 rules, ALL must be true)
- Ambiguous or architectural loops NEVER auto-execute (case-32 PASS, case-33 PASS)
- Plan status updated after completion

### Drift Classification Guarantees

| Classification | Rule | Test |
|---|---|---|
| Protocol-only commits → drift = none | `chore(checkpoint):`, `chore(protocol):`, `chore(state):` | case-12 PASS |
| Source-impacting commits → drift = high | `feat:`, `fix:` with source changes | case-12 PASS |
| Documentation-only → drift = low | `docs(*):` without source changes | case-39 PASS |
| Stabilization-pattern → drift = low | docs + test fixes in sequence | case-39 PASS |

---

## 4. Deferred Boundary

Review of all deferred items. Classification: **post-v1.0**, **reconsider later**, or **remove entirely**.

| ID | Item | Classification | Rationale |
|---|---|---|---|
| **D03** | `/dev-save` optional arguments | post-v1.0 | UX improvement. Current auto-behavior works. No correctness impact. |
| **D04** | `/dev-status` phase recovery weak | post-v1.0 | Quality of life. Phase inference already has 5-step priority; "unknown" is rare. |
| **D05** | `/dev-save` should fully close workflow task state | reconsider later | Claude Code-specific runtime behavior. Protocol cannot control agent task lifecycle. May never be actionable. |
| **D06** | Constants coverage audit | post-v1.0 | Maintenance tooling. No duplicated constants currently exist; future protection only. |
| **D07** | Planning workflow should support "verification loops" | post-v1.0 | Semantic cleanup. No-op saves already work operationally; planning language just needs updated conventions. |
| **D08** | Protocol documentation split needs clarification | reconsider later | Current usage works. `.agents/dev-protocol/docs/` and `docs/` have de facto boundaries. No active bugs. |
| **D09** | Workflow checkpoint semantics should become explicit | post-v1.0 | Structural improvement. Convention-dependent detection works correctly (case-12 PASS). Metadata markers would be nice but not blocking. |
| **D10** | Cross-runtime hook lifecycle compatibility | reconsider later | Blocked on external runtime validation. Claude Code is the reference runtime. No immediate breakage risk. |
| **D11** | Formalize `/goal` as first-class skill or deprecate into `/dev-scope` | post-v1.0 | Architectural cleanup. `/goal` is documented in `command-contracts.md` and functions correctly. Inconsistent directory structure is cosmetic. |
| **F2** | `goal-output` script uses HEAD-only, not working tree | post-v1.0 | Tooling friction, not protocol correctness. Agents can derive `changed_files` via `git status` or manual inspection. |
| **F3** | Drift detection skips on first run (empty `checkpoint.last_commit`) | post-v1.0 | First-run edge case. `/dev-init` output instructs user to run `/dev-save` after initialization. Gap is one workflow cycle. |

**Summary**:
- **post-v1.0**: 9 items
- **reconsider later**: 3 items
- **remove entirely**: 0 items

No deferred item blocks v1.0 correctness or core workflow viability.

---

## 5. Breaking Change Policy

After v1.0, the following changes are considered **breaking** and require a new major version:

### Command Contract Changes

- Adding new required arguments to `/dev-init`, `/dev-status`, `/dev-save`, `/dev-scope`
- Changing auto-execution criteria (7 rules)
- Changing precondition requirements for `continue loop`
- Removing or renaming any canonical command

### Workflow Changes

- Changing the canonical workflow path
- Removing auto-execution from `/dev-scope`
- Changing semantic equivalence rules
- Changing drift classification rules or thresholds

### State Model Changes

- Adding new required fields to `workflow-state.yml`
- Changing the meaning of existing fields (e.g., `checkpoint.last_commit`)
- Moving state file locations (`.agents/dev-protocol/` path is frozen)
- Changing goal-output artifact format requirements

### Checkpoint Semantics

- Allowing `/dev-save` to commit source files
- Changing protocol commit prefixes (`chore(checkpoint):`, etc.)
- Removing no-op save support
- Changing mixed-staged-files rejection behavior

### Non-Breaking Changes (Allowed in Patch Releases)

- Documentation updates
- Alias skill redirects (deprecated commands)
- Test matrix expansion
- Semantic section additions to PROMPT.md/SKILL.md (as long as behavior is unchanged)
- New test cases
- README updates

---

## 6. Release Checklist

### Pre-Release Verification

| # | Check | Status | Evidence |
|---|---|---|---|
| 1 | Test matrix all PASS | **PASS** | case-05 through case-44 all PASS |
| 2 | Dogfood completed | **PASS** | Re-check executed 2026-05-29. Canonical workflow verified. |
| 3 | Onboarding clean | **PASS** | Patch Set 2 completed. project-rules.md corrected. Alias skills cleaned. |
| 4 | No HIGH findings open | **PASS** | F1 resolved. No new HIGH findings. |
| 5 | Roadmap stabilized | **PASS** | This document defines freeze boundary. v2-redesign-roadmap.md updated. |
| 6 | Deferred finalized | **PASS** | All defer items classified. None block release. |
| 7 | Canonical workflow verified | **PASS** | case-34, case-41 PASS. Path unification confirmed. |
| 8 | Command contracts current | **PASS** | `docs/command-contracts.md` covers all canonical commands + semantic validation. |
| 9 | No v1 references in docs | **PASS** | case-43, case-44 PASS. All alias skills redirect correctly. |
| 10 | Semantic validation layer solid | **PASS** | case-37 through case-40 PASS. |

### Known Limitations (Non-Blocking)

| ID | Limitation | Impact | Mitigation |
|---|---|---|---|
| F2 | `goal-output` derivation script reads HEAD only, not working tree | Agents using the helper script may report wrong changed_files | Derive manually via `git status --short` or `git diff --cached --name-only` |
| F3 | First `/dev-status` after `/dev-init` skips drift comparison | One-cycle gap before drift detection is active | Run `/dev-save` immediately after init to establish baseline |
| D11 | `/goal` has no `skills/goal/` directory | Inconsistent skill structure | `/goal` behavior is fully documented in `command-contracts.md` |
| D10 | Hook lifecycle only verified on Claude Code | Other runtimes may have different cleanup behavior | Protocol core does not depend on hooks |

### Post-Release Monitoring

- [ ] External project validation on 2+ non-protocol repositories
- [ ] Watch for drift detection edge cases on first-run
- [ ] Monitor alias skill redirect effectiveness
- [ ] Collect feedback on semantic validation accuracy

---

## Assessment

**Is dev-protocol v1.0 ready?**

Yes. All P0 findings are resolved. All active tests pass. The core workflow is functionally complete, tested, and documented. Remaining items are quality-of-life improvements, tooling friction, or architectural cleanup — none of which block correctness or core workflow viability.

**Recommendation**: Tag `v1.0-rc1`. Run external validation. Fix only regressions or critical bugs found during validation. No new features, no refactors, no command changes.
