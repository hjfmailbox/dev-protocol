# Case 37 -- Semantic Validation Equivalence

## Purpose

Verify that continue-loop PROMPT.md defines semantic equivalence rules for validation criteria interpretation.

## Preconditions

- `skills/continue-loop/PROMPT.md` exists

## Steps

1. Read `skills/continue-loop/PROMPT.md`
2. Verify it contains "Semantic Validation Equivalence" section
3. Verify it defines equivalence rules (same domain + action direction, git reality confirms intent, test outcomes match, commit intent matches goal)
4. Verify it provides examples of equivalence
5. Verify it defines non-equivalence signals (started vs completed, partial vs fully resolved)
6. Verify the section is positioned between scope derivation and auto-execution evaluation

## Expected Results

- Semantic equivalence section exists
- At least 4 equivalence rules defined
- Examples show "tests pass" ≈ "all regression cases pass"
- Non-equivalence signals prevent false positives

## Failure Criteria

- Missing semantic equivalence section
- No equivalence examples
- No non-equivalence signals
- Literal string matching only
