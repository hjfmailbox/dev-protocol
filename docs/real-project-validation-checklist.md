# Real Project Validation Checklist

End-to-end validation of dev-protocol v2 on a real project before external adoption.

Run this checklist against a real repository to verify the protocol works outside the dev-protocol self-hosting context.

---

## How to Use This Checklist

1. Select a real project (not dev-protocol itself).
2. Work through each scenario in order.
3. Mark each check `[ ]` as `[x]` when verified.
4. Record observations in the Notes column.
5. At the end, classify findings and make a go/no-go decision.

---

## Scenario 1: First-Contact Onboarding

**Setup**: Fresh clone of a real project with no `.agents/` directory.

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 1.1 | Run `/dev-init` on first contact | Protocol inspects repository, creates `.agents/dev-protocol/` with state files | |
| 1.2 | Review generated `workflow-state.yml` | `phase: unknown`, `focus: onboarding`, no inferred maturity | |
| 1.3 | Review generated `handoff.md` | Contains Current Focus, Completed, In Progress, Blockers, Next Actions | |
| 1.4 | Review generated `project-rules.md` | Contains project-specific constraints derived from repo inspection | |
| 1.5 | Verify `.agents/` is not gitignored | `git check-ignore .agents/dev-protocol/` returns empty | |
| 1.6 | Stage and commit state files | `git add .agents/`, `git commit -m "chore(protocol): initialize dev-protocol"` succeeds | |
| 1.7 | Run `/dev-status` immediately after init | Reports current state, confirms recoverability, no drift warnings | |

**Pass criteria**: All checks 1.1–1.7 succeed within 10 minutes.

---

## Scenario 2: Dirty Workspace Behavior

**Setup**: Real project with uncommitted changes.

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 2.1 | Run `/dev-init` with dirty workspace | Protocol detects dirty state, asks for confirmation before generating files | |
| 2.2 | Confirm dirty init | State files generated; `handoff.md` notes dirty workspace as "in progress" | |
| 2.3 | Attempt `/dev-save` on dirty workspace | Protocol warns or fails; does not persist state until workspace is clean | |
| 2.4 | Clean workspace (commit or stash), then `/dev-save` | `/dev-save` succeeds, updates state files | |

**Pass criteria**: Dirty workspace is handled safely; no auto-commit, no silent persistence of ambiguous state.

---

## Scenario 3: Clean Workspace Behavior

**Setup**: Real project with clean working tree and committed state files.

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 3.1 | Run `/dev-status` on clean workspace | Reports "workspace clean", no drift, accurate phase and focus | |
| 3.2 | Run `/dev-save` with no changes since last save | Early exit: "No meaningful changes detected" | |
| 3.3 | Run `/dev-scope` to declare a goal | Generates standardized scope with In-scope, Out-of-scope, Validation Criteria | |
| 3.4 | Implement scoped work, commit normally | One or more conventional commits during work | |
| 3.5 | Run `case-06` after goal work | PASS: goal commit format, changed_files, artifact presence all valid | |
| 3.6 | Run `/dev-save` after case-06 | Updates state files, validates consistency | |
| 3.7 | Commit state files after `/dev-save` | Checkpoint-style commit: `chore(checkpoint): sync state after ...` | |
| 3.8 | Run `case-05` after committing state | PASS: state files consistent, `last_commit` matches `HEAD~1` | |

**Pass criteria**: All checks 3.1–3.8 succeed. Validation order is respected (case-06 before save, case-05 after save).

---

## Scenario 4: Repo with Existing State

**Setup**: Real project that already has `.agents/dev-protocol/` from a prior session.

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 4.1 | Run `/dev-init` on project with existing state | Protocol warns that state exists; recommends `/dev-status` instead | |
| 4.2 | Run `/dev-status` instead | Reads existing state, validates freshness, reports phase and focus | |
| 4.3 | Verify `/dev-status` does not modify files | `git diff` empty before and after `/dev-status` | |

**Pass criteria**: Existing state is respected; `/dev-init` does not overwrite without warning.

---

## Scenario 5: Repo without State

**Setup**: Real project with no `.agents/` directory, no design documents.

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 5.1 | Run `/dev-init` on bare repo | Protocol creates state files with `phase: unknown`, `focus: onboarding` | |
| 5.2 | Verify no phase guessing | `workflow-state.yml` does not claim `p1`, `p2`, etc. without evidence | |
| 5.3 | Verify `/dev-init` does not modify source code | `git diff` outside `.agents/` is empty | |

**Pass criteria**: Safe onboarding with no assumptions; no source code mutation.

---

## Scenario 6: Branch Drift

**Setup**: Real project where user switched branches after last `/dev-save`.

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 6.1 | Save state on `main` | `/dev-save` succeeds, `last_commit` updated | |
| 6.2 | Switch to feature branch with different history | `git checkout feature-branch` | |
| 6.3 | Run `/dev-status` on feature branch | Detects `last_commit` not in current branch history; reports drift | |
| 6.4 | Follow `/dev-status` recommendation | Protocol recommends re-running `/dev-init` or returning to `main` | |

**Pass criteria**: Branch switch is detected as drift; user is not misled by stale baseline.

---

## Scenario 7: State Drift

**Setup**: Real project where state files were manually edited or got out of sync.

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 7.1 | Manually edit `workflow-state.yml` to wrong phase | e.g., set `phase: p99` | |
| 7.2 | Run `/dev-status` | Detects phase mismatch against git history; reports drift warning | |
| 7.3 | Run `/dev-save` with inconsistent state | Fails validation: state contradicts repository reality | |
| 7.4 | Fix state manually, re-run `/dev-save` | Succeeds after consistency is restored | |

**Pass criteria**: Drift is detected, not silently accepted. `/dev-save` fails on inconsistency.

---

## Scenario 8: Interrupted Session Recovery

**Setup**: Simulate a session that ended without `/dev-save` (e.g., crash, timeout, forgotten save).

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 8.1 | Complete goal work, commit changes, do NOT run `/dev-save` | Workspace clean, state files reflect prior save | |
| 8.2 | Start new session, run `/dev-status` | Detects new commits since `last_commit`; reports `HEAD is N commits ahead` | |
| 8.3 | Review `/dev-status` recovery summary | Reports correct phase, describes un-saved work, recommends `/dev-save` | |
| 8.4 | Run `/dev-save` to catch up | Updates state to reflect the committed work | |

**Pass criteria**: Recovery is possible even when save was skipped; no data loss.

---

## Scenario 9: Large Repo Behavior

**Setup**: Real project with >1000 files or deep git history.

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 9.1 | Run `/dev-init` on large repo | Completes in <30 seconds; does not hang | |
| 9.2 | Verify `/dev-init` does not read every file | Uses git history and top-level structure only | |
| 9.3 | Run `/dev-status` on large repo | Completes in <10 seconds; no excessive git operations | |
| 9.4 | Verify scope threshold is reasonable | `case-06` does not false-FAIL on large but legitimate goal commits | |

**Pass criteria**: Performance acceptable; no O(n) scanning of entire repository.

---

## Scenario 10: Ambiguous Project Behavior

**Setup**: Real project with unusual structure (monorepo, mixed languages, no README).

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 10.1 | Run `/dev-init` on ambiguous repo | Does not crash; generates safe `phase: unknown` state | |
| 10.2 | Review `handoff.md` for ambiguity notes | Documents detected ambiguity (e.g., "multiple package managers detected") | |
| 10.3 | Run `/dev-scope` with ambiguous requirements | Protocol detects ambiguity, asks for clarification before proceeding | |
| 10.4 | Verify no false confidence | `workflow-state.yml` does not claim certainty where none exists | |

**Pass criteria**: Ambiguity is acknowledged, not hidden. Safe defaults prevail.

---

## Scenario 11: Low-Confidence Onboarding

**Setup**: Real project where `/dev-init` cannot determine basic facts (empty repo, no commits, corrupted git).

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 11.1 | Run `/dev-init` on empty repo (no commits) | Reports "no git history"; recommends `git init` + first commit | |
| 11.2 | Run `/dev-init` outside git repo | Fails gracefully; reports "not a git repository" | |
| 11.3 | Verify no state files created on failure | `.agents/` does not exist after failed init | |
| 11.4 | Verify failure is hard, not soft | No partial state, no "best guess" recovery | |

**Pass criteria**: Low-confidence scenarios fail safely; no misleading state generation.

---

## Scenario 12: Alias Behavior Verification

**Setup**: Real project with v2 protocol active.

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| 12.1 | Run `/dev-bootstrap` | Prints deprecation notice: "Use `/dev-init` instead"; redirects to `/dev-init` semantics | |
| 12.2 | Run `/dev-checkpoint` | Prints deprecation notice: "Use `/dev-save` instead"; redirects to `/dev-save` semantics | |
| 12.3 | Run `/dev-resume` | Prints deprecation notice: "Use `/dev-status` instead"; redirects to `/dev-status` semantics | |
| 12.4 | Run `/dev-goal-template` | Prints deprecation notice: "Use `/dev-scope` instead"; redirects to `/dev-scope` semantics | |
| 12.5 | Verify alias behavior matches v2 semantics | Aliased commands do not execute v1 behavior that conflicts with v2 | |
| 12.6 | Verify state files unchanged by aliases | `git diff` empty after running deprecated commands | |

**Pass criteria**: All deprecated commands redirect to v2 equivalents with no breaking changes.

---

## Full Workflow Sequence Validation

Execute this exact sequence once on a real project and verify coherence:

```
/dev-init
  -> /dev-status
  -> /dev-scope
  -> [implementation work + normal git commits]
  -> /dev-save
  -> /clear  [simulated new session]
  -> /dev-status
```

| # | Check | Expected Result | Notes |
|---|-------|-----------------|-------|
| W.1 | After `/dev-init` | State files created, committed, workspace clean | |
| W.2 | After `/dev-status` (post-init) | Reports recoverable state, no drift | |
| W.3 | After `/dev-scope` | Scope document generated with clear boundaries | |
| W.4 | After implementation work | Normal commits exist, goal commit follows convention | |
| W.5 | After `/dev-save` | State files updated, consistency validated | |
| W.6 | After simulated new session + `/dev-status` | Phase, focus, and next actions match pre-save state | |

**Pass criteria**: W.1–W.6 all succeed; workflow is internally coherent end-to-end.

---

## Friction Log

Pre-populated friction identified during dev-protocol self-dogfooding and dry-run validation. Record additional findings during real-project execution.

| Scenario | Friction Description | Severity | Workaround |
|----------|----------------------|----------|------------|
| General | `/dev-save` name implies it saves code changes, but it only saves protocol state files | medium | Documentation clarifies this repeatedly; onboarding guide has a dedicated "Normal Commits vs Protocol Saves" section |
| General | Validation order is easy to forget: `case-06` before save, `case-05` after save | medium | Documented in `references/workflow-rules.md` and `docs/onboarding.md`; skill prompts reference it |
| 3 (Clean) | `fix-goal-output.ps1` must be run manually between goal commit and `case-06` | low | Script is deterministic; could be automated via hook in future |
| 3 (Clean) | User must manually stage and commit state files after `/dev-save` | low | Intentional design choice to separate protocol state from source code commits |
| 5 (No state) | `.agents/dev-protocol/` is a nested path; easy to create files in wrong location | low | Documented in onboarding; `run-tests.ps1` checks file existence at correct path |
| 12 (Alias) | `/dev-checkpoint` no longer commits, which differs from v1 behavior | low | Deprecation banner and documentation explain the semantic shift |
| 8 (Interrupt) | `/dev-status` may report stale phase if `workflow-state.yml` was not updated during last save | high | **Requires R3 fix**: `/dev-status` must cross-check phase against git history |
| 8 (Interrupt) | `/dev-status` may report stale workspace status from `handoff.md` instead of live `git status` | high | **Requires R3 fix**: `/dev-status` must always run `git status` at invocation time |
| 3 (Clean) | `case-06` fails on NO_OP goals (zero file changes) because artifact is absent | medium | **Requires R4 fix**: `run-tests.ps1` should tolerate absent artifact when HEAD changed 0 files |
| 3 (Clean) | Bash heredoc artifact emission silently fails on Windows | medium | **Requires R4 fix**: Use PowerShell-native file creation on Windows |
| 9 (Large) | `case-06` file-change threshold (50 files) has no empirical basis | low | Deferred; needs real-project data to calibrate |
| 12 (Alias) | Test numbering gaps (case-01 through case-04 missing) cause confusion | low | Deferred; renumbering is breaking change to muscle memory |

---

## Go / No-Go Decision

After completing all scenarios, output exactly one of:

```text
READY_FOR_REAL_PROJECT
```

or

```text
BLOCKED_WITH_REQUIRED_FIXES
```

with reasoning below.

### Decision

```text
BLOCKED_WITH_REQUIRED_FIXES
```

### Reasoning

R2 runtime implementation is complete and all v2 skills exist (`/dev-init`, `/dev-scope`, `/dev-save`, `/dev-status`). v1 aliases are implemented. case-05 and case-06 pass on dev-protocol self-hosting.

However, two Category A deferred items remain unaddressed and break core state reconciliation:

1. **Phase drift (#14)**: `/dev-status` restores the persisted `phase` from `workflow-state.yml` without cross-checking against git history depth and file maturity. In real-project validation, this caused `/dev-status` to report `p1` for a project that had already completed bootstrap, checkpoint, resume, validation, migration, and hardening (effectively `p3`). An agent resuming with stale phase wastes tokens re-discovering completed work and may make incorrect architectural assumptions.

2. **Repository status freshness drift (#15)**: `/dev-status` may report cached workspace status from `handoff.md` instead of running `git status` at invocation time. During real-project validation, `/dev-status` reported `workspace clean (1 modified file: deferred-improvements.md)` after a successful checkpoint where the workspace was already clean. Stale status undermines developer trust in the protocol.

These are not documentation gaps or cosmetic issues. They are core state reconciliation bugs that directly violate the "State Over History" principle. A developer onboarding a real project will encounter them within the first two `/dev-status` invocations.

Additionally, three medium-severity usability blockers should be resolved before external validation to avoid eroding confidence:

- **NO_OP goal false FAILs (#7)**: Legitimate goals that change zero files fail `case-06`.
- **Windows bash heredoc failure (#8)**: Artifact emission is unreliable on Windows.
- **Continuation handoff prompt weakness (#6)**: Cold-start recovery may expand scope beyond documented boundaries.

### Required Fixes

| Fix | Owner Phase | Deferred Item | Impact |
|-----|-------------|---------------|--------|
| `/dev-status` must cross-check phase against git history + file maturity | R3 | #14 | High: prevents phase drift |
| `/dev-status` must always run `git status` at invocation time | R3 | #15 | High: prevents stale workspace status |
| `/dev-save` must derive phase from reality, not copy forward | R3 | #14 | High: prevents phase stagnation |
| `case-06` must tolerate absent artifact when HEAD changed 0 files | R4 | #7 | Medium: prevents false failures |
| Protocol must use PowerShell-native file creation on Windows | R4 | #8 | Medium: Windows reliability |
| Harden continuation handoff to forbid scope expansion | R4 | #6 | Medium: cold-start accuracy |

**Recommendation**: Complete R3 (State Reconciliation) and R4 (Onboarding Hardening) before proceeding to R5 (Real Project Validation).
