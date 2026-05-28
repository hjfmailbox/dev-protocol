# Case 15 — Scope Misuse Detection

## Purpose

Verify that `/dev-scope` correctly identifies when `/goal` is unnecessary and when it is required.

## Preconditions

- `.agents/dev-protocol/` exists with valid state files
- Git repository is initialized

## Steps

### Scenario A: Simple task (should not force /goal)

1. Request a trivial change: "Fix typo in README"
2. Run `/dev-scope`
3. Inspect output

### Scenario B: Complex task (should require /goal)

1. Request a complex change: "Refactor authentication system"
2. Run `/dev-scope`
3. Inspect output

## Expected Results

### Scenario A

- `/dev-scope` recognizes the task as trivial (1 file, obvious scope)
- `/dev-scope` may suggest: "This is a simple single-file change. You may proceed directly without formal /goal."
- Or produces minimal scope without requiring explicit /goal confirmation

### Scenario B

- `/dev-scope` produces full structured scope
- `/dev-scope` explicitly requires confirmation before implementation
- Scope includes in-scope/out-of-scope, requirements, validation
- Output ends with: "Review the scope above. Confirm or refine before proceeding to implementation."

## Failure Criteria

- Scenario A forces full /goal workflow for a single typo fix
- Scenario B allows proceeding without validation criteria
- `/dev-scope` does not distinguish simple vs complex tasks
- No misuse detection in prompt
