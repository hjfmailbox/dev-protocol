# Commands Overview

Quick index of all dev-protocol commands.

For detailed contracts (preconditions, failure modes, recovery), see [`command-contracts.md`](command-contracts.md).

---

## Canonical v2 Commands

| Command | Purpose | One-line Usage |
|---------|---------|----------------|
| `/dev-init` | Initialize protocol state on a project | `/dev-init` → review generated files → commit |
| `/dev-status` | Inspect current state and reconstruct context | `/dev-status` → review summary → decide next action |
| `/dev-scope` | Declare a focused goal with validation criteria | `/dev-scope <description>` → review scope → confirm |
| `/dev-save` | Persist protocol state and create checkpoint commit | `/dev-save` → verify output → continue or end session |

## Workflow Sequences

### Standard loop

```text
/dev-status → /dev-scope → /goal → implement → /dev-save
```

### Verification loop (no source changes)

```text
/dev-status → verify → /dev-save
```

### Fresh project onboarding

```text
/dev-init → review state → git add .agents/ → git commit → /dev-save
```

### Recovery (corrupted or stale state)

```text
/dev-status → (detects drift) → /dev-init → /dev-save
```

## Legacy Aliases

| Legacy Command | Replacement | Behavior |
|----------------|-------------|----------|
| `/dev-bootstrap` | `/dev-init` | Prints redirect notice |
| `/dev-checkpoint` | `/dev-save` | Prints redirect notice |
| `/dev-resume` | `/dev-status` | Prints redirect notice |
| `/dev-doctor` | `/dev-status --diagnose` | Prints redirect notice |
| `/dev-help` | `/dev-status --help` | Prints redirect notice |
| `/dev-goal-template` | `/dev-scope` | Prints redirect notice |
| `/goal` | `/dev-scope` | Prints redirect notice |

## Command Boundaries

| Command | Writes Files? | Commits? | Read-only? |
|---------|:-------------:|:--------:|:----------:|
| `/dev-init` | Yes | No | No |
| `/dev-status` | No | No | Yes |
| `/dev-scope` | No | No | No |
| `/dev-save` | Yes | Yes | No |
| `/goal` | Yes | Yes | No |
