# Case 12 — Protocol Commit Classification

## Purpose

Verify that `/dev-status` correctly classifies protocol commits vs source commits.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- Git history contains a mix of protocol and source commits

## Steps

1. Create a `chore(checkpoint):` commit (protocol commit)
2. Create a `feat:` commit (source commit)
3. Update `checkpoint.last_commit` to point before both commits
4. Run `/dev-status`
5. Inspect drift classification

## Expected Results

- `chore(checkpoint):` commit → classified as protocol commit → drift = none (if all intermediate are protocol)
- `feat:` commit → classified as source commit → drift = high
- `chore(protocol):` commit → classified as protocol commit → drift = none
- `chore(state):` commit → classified as protocol commit → drift = none
- Semantic protocol commit ("sync state" + only .agents/ changes) → drift = none

## Failure Criteria

- `chore(checkpoint):` classified as source commit (false high drift)
- `feat:` classified as protocol commit (false no drift)
- `chore(protocol):` not recognized as protocol commit
- Semantic protocol commits not detected
