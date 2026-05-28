# Case 33 -- Large Loop Requires /goal

## Purpose

Verify that `continue loop` produces a scope document (instead of auto-executing) when the next loop is complex and does not meet auto-execution criteria.

## Preconditions

- `skills/continue-loop/PROMPT.md` exists
- `skills/continue-loop/SKILL.md` exists

## Steps

1. Read `skills/continue-loop/PROMPT.md`
2. Verify auto-execution criteria are checked after scope derivation
3. Verify when criteria NOT met, output is scope document + STOP
4. Verify output contains "Separate /goal required" or equivalent
5. Read `skills/continue-loop/SKILL.md`
6. Verify scope document path is defined

## Expected Results

- Auto-execution criteria applied to derived scope
- When ANY criterion fails: scope document produced, STOP, wait for /goal
- Output explicitly states that /goal is required
- No source code modification when auto-execution criteria fail

## Failure Criteria

- Auto-execution criteria not applied
- Complex loops incorrectly auto-executed
- Missing scope document output path
- Source code modified without meeting auto-execution criteria
