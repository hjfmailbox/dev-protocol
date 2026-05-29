# Case 34 -- Generate-Plan Basic Workflow

## Purpose

Verify that `generate plan` skill exists, reads context, and produces a structured `next-phase-plan.md`.

## Preconditions

- `skills/generate-plan/PROMPT.md` exists
- `skills/generate-plan/SKILL.md` exists
- `.claude/skills/generate-plan` symlink exists

## Steps

1. Read `skills/generate-plan/SKILL.md`
2. Verify it contains "Purpose", "When to Use", "When NOT to Use", "Execution Sequence"
3. Read `skills/generate-plan/PROMPT.md`
4. Verify it contains STEP 1 (Read Context), STEP 3 (Decompose Goal), STEP 4 (Write Plan)
5. Verify PROMPT.md specifies output path as `.agents/dev-protocol/next-phase-plan.md`
6. Verify SKILL.md and PROMPT.md both contain "DO NOT" with "NEVER execute loops"
7. Verify loop format uses `## Loop N — [Name]`
8. Verify each loop requires Goal, Files, Validation sections

## Expected Results

- SKILL.md defines command semantics and boundaries
- PROMPT.md defines execution steps
- Output path is `.agents/dev-protocol/next-phase-plan.md`
- Loop format is compatible with continue-loop tolerant parsing
- Explicit prohibition on execution

## Failure Criteria

- Missing skill files
- Output path not defined
- Loop format incompatible with continue loop
- No execution prohibition
