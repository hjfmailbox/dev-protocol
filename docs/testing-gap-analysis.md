# Testing Gap Analysis

Analysis of dev-protocol validation coverage as of current state.

Current explicit test cases:

| Case | Coverage | Status |
|------|----------|--------|
| case-05-first-checkpoint | State file existence, last_commit validity, HEAD~1 match, workspace clean, checkpoint commit format | Active |
| case-06-goal-workflow | Workspace clean, untracked files, HEAD not checkpoint, scope threshold, content changes, conventional commit, goal-output artifact, changed_files integrity | Active |

---

## Missing High-Value Tests

### 1. `/dev-init` onboarding path

**Gap**: No automated validation for first-time project initialization.

**Risk**: `/dev-init` is the first contact. Errors here block all subsequent workflow.

**What should be tested**:

- Generates valid `workflow-state.yml`, `handoff.md`, `project-rules.md`
- Defaults `phase` to `unknown`
- Leaves `checkpoint.last_commit` empty
- Does not auto-commit
- Does not modify source code

### 2. `/dev-init` on dirty workspace

**Gap**: No validation for dirty-workspace behavior.

**Risk**: `/dev-init` must detect dirty state and require confirmation. Silent generation on dirty workspace produces incorrect state.

**What should be tested**:

- Detects dirty workspace
- Does not auto-generate without confirmation
- If confirmed, state reflects dirty context accurately

### 3. `/dev-init` on existing `.agents/dev-protocol`

**Gap**: No validation for re-init protection.

**Risk**: Accidental overwrite of existing state destroys context.

**What should be tested**:

- Detects existing state files
- Recommends `/dev-status` instead of overwriting
- Does not modify existing state without explicit reason

### 4. `/dev-status` drift detection

**Gap**: No automated validation for `/dev-status` commit-type drift check.

**Risk**: False-positive drift after checkpoint commits undermines trust.

**What should be tested**:

- `chore(checkpoint):` commits recognized as protocol commits (drift = none)
- `chore(protocol):` commits recognized as protocol commits (drift = none)
- `chore(state):` commits recognized as protocol commits (drift = none)
- Non-protocol commits trigger high drift
- Mixed protocol + non-protocol commits trigger high drift

### 5. `/dev-save` no-op behavior

**Gap**: No validation for save when no meaningful changes exist.

**Risk**: `/dev-save` should early-exit without creating redundant commits.

**What should be tested**:

- Running `/dev-save` with no file changes since last checkpoint
- Running `/dev-save` with only state-file changes (self-drift)
- Correct behavior in both cases (no redundant commit)

### 6. `/dev-scope` ambiguity detection

**Gap**: No validation for scope ambiguity handling.

**Risk**: Ambiguous scopes waste tokens and produce poor outcomes.

**What should be tested**:

- `/dev-scope` detects ambiguous input
- Requires explicit boundary definition
- Generates standardized scope document with validation criteria

### 7. Legacy alias behavior

**Gap**: No validation for deprecated command aliases.

**Risk**: v1 commands must redirect to v2 without executing old behavior.

**What should be tested**:

- `/dev-bootstrap` prints redirect to `/dev-init`
- `/dev-checkpoint` prints redirect to `/dev-save`
- `/dev-resume` prints redirect to `/dev-status`
- All aliases exit cleanly without executing old behavior

### 8. Goal-output changed_files mismatch

**Gap**: No validation for the case where declared changed_files do not match actual commit.

**Risk**: This is the primary case-06 failure mode. No dedicated test for mismatch detection.

**What should be tested**:

- Declared files missing from actual commit
- Actual commit files missing from declaration
- Both conditions detected and reported

### 9. Session recovery after `/clear`

**Gap**: No validation for full session recovery sequence.

**Risk**: The entire protocol value proposition depends on recoverability.

**What should be tested**:

- Fresh session `/dev-status` restores same phase and focus
- Fresh session `/dev-status` reports accurate git status
- Fresh session `/dev-status` recommends correct next action

### 10. Protocol commit format enforcement

**Gap**: No validation that `/dev-save` generates correct commit format.

**Risk**: case-05 checks HEAD format but does not verify `/dev-save` generated it.

**What should be tested**:

- `/dev-save` generates `chore(checkpoint): ...` format
- `/dev-save` does not reuse previous goal commit message
- `/dev-save` stages only `.agents/dev-protocol/*` files
