# Case 42 -- Test Matrix Synchronization Audit

## Purpose

Verify that `docs/test-matrix.md` case IDs match actual test directories in `tests/`, with no orphaned or stale case names.

## Preconditions

- `docs/test-matrix.md` exists
- `tests/` directory exists with case subdirectories

## Steps

1. Read `docs/test-matrix.md`
2. Extract all case IDs referenced in the document
3. List actual `tests/case-*` directories
4. Verify every case ID in test-matrix.md maps to an existing directory
5. Verify every `tests/case-*` directory is referenced in test-matrix.md
6. Verify no stale case names (e.g., `case-11-continue-loop`, `case-11-aborted-goal`) remain

## Expected Results

- test-matrix.md case IDs match actual directory names exactly
- No orphaned case IDs in test-matrix.md
- No missing case IDs from test-matrix.md
- Test inventory table at end of test-matrix.md is complete and accurate

## Failure Criteria

- Case ID in test-matrix.md without matching directory
- Directory exists but not referenced in test-matrix.md
- Stale case names from outdated naming conventions remain
