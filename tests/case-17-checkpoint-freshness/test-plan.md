# Case 17 -- Checkpoint Freshness Levels

## Purpose

Verify that `/dev-status` correctly classifies checkpoint freshness as fresh, stale, or outdated based on source commits since last checkpoint.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- `workflow-state.yml` contains `checkpoint.last_commit`
- Git repository is initialized

## Steps

### Scenario A: Fresh checkpoint

1. Ensure `checkpoint.last_commit` matches HEAD or HEAD~1
2. Run `/dev-status`
3. Inspect output

### Scenario B: Stale checkpoint

1. Ensure 2-5 source commits exist since `checkpoint.last_commit`
2. Run `/dev-status`
3. Inspect output

### Scenario C: Outdated checkpoint

1. Ensure >5 source commits exist since `checkpoint.last_commit`
2. Run `/dev-status`
3. Inspect output

## Expected Results

### Scenario A

- Checkpoint reported as: `checkpoint: fresh`
- Confidence is `high`
- Workflow-state focus is used with high confidence

### Scenario B

- Checkpoint reported as: `checkpoint: stale`
- Confidence is `medium`
- Workflow-state focus is downgraded to low-confidence signal

### Scenario C

- Checkpoint reported as: `checkpoint: outdated`
- Confidence is `low`
- Git reality takes precedence over workflow-state focus

## Failure Criteria

- Freshness level is incorrect for commit count
- No freshness classification in output
- Stale/outdated checkpoint still treated as high confidence
- Freshness thresholds do not match contract (fresh: 0-1, stale: 2-5, outdated: >5)
