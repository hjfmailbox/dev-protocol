# Session Output Capture Recommendation

## Context

Case-06 validates git state (cleanliness, commit integrity, scope) but cannot assert on the goal output contract sections (Goal Status, Summary, Stop Reason, etc.) because they exist only as session terminal text. Manual review is the sole validation path.

This document compares three artifact formats and recommends a minimal path.

---

## Format Comparison

### 1. `goal-output.json`

**Pros:**
- Native machine-parseable (`ConvertFrom-Json`)
- Field-level assertions are exact (no regex ambiguity)
- Cross-check `changed_files` against `git diff --name-only` is trivial

**Cons:**
- JSON escaping edge cases: prompt seeds contain multi-line text, quotes, backslashes
- Human review is less pleasant (raw JSON vs formatted text)
- Claude must serialize structured output correctly — one malformed quote breaks `ConvertFrom-Json`

### 2. `goal-output.md`

**Pros:**
- Human-readable by default — matches how Claude already produces the output contract
- No serialization edge cases — just emit the same markdown sections
- Regex validation is simple: match section headers like `### Goal Status`, `### Stop Reason`
- Low risk of malformed output (Claude natively writes markdown)

**Cons:**
- Regex-based parsing is inherently less robust than JSON field access
- Section header formatting could drift (e.g., `##` vs `###` vs `**`)

### 3. `goal-output.json` with temporary lifecycle

Same as option 1, but with explicit create → validate → cleanup semantics:
- Claude writes the file at goal completion
- `run-tests.ps1` validates it during case-06
- File is `.gitignore`'d so it never enters git history

---

## Git History Pollution

The core problem: if the artifact is tracked by git, every goal commit includes it as "changed file," which:
1. Pollutes the `Changed Files` section noise
2. Inflates the file-count scope check (10-file threshold)
3. Creates a growing chain of identical files in git history

**Solution: `.gitignore` entry**

```
# Session output artifacts — validated by case-06, not versioned
.agents/dev-protocol/goal-output.*
```

This means:
- Claude writes `.agents/dev-protocol/goal-output.json` or `.goal-output.md` at goal completion
- File exists on disk for case-06 to validate
- File is untracked — `git diff --name-only` does not include it
- File does not count toward the 10-file scope threshold
- File persists only on disk until next goal overwrites or deletes it

---

## Changed-Files Noise

Because the artifact is `.gitignore`'d, `git diff --name-only HEAD~1..HEAD` returns only the actual goal files. The artifact never appears in:
- Scope threshold counting
- Changed Files listing
- Commit diff statistics

This is the key advantage over a tracked artifact — it is a **scratch file** that exists purely for validation, not for versioning.

---

## How Case-06 Validates the Output Contract

### For `.md` format:
```powershell
$Artifact = Join-Path $StateRoot "goal-output.md"
if (-not (Test-Path $Artifact)) { Fail "goal-output.md missing" }
$Content = Get-Content $Artifact -Raw

$Sections = @(
    'Goal Status',
    'Goal Summary',
    'Changed Files',
    'Validation Results',
    'Stop Reason',
    'Risks',
    'Continuation Handoff'
)
foreach ($section in $Sections) {
    if ($Content -notmatch $section) { Fail "Missing output section: $section" }
}
```

### For `.json` format:
```powershell
$Artifact = Join-Path $StateRoot "goal-output.json"
if (-not (Test-Path $Artifact)) { Fail "goal-output.json missing" }
$Json = Get-Content $Artifact -Raw | ConvertFrom-Json

$Fields = @('goal_status', 'summary', 'stop_reason')
foreach ($field in $Fields) {
    if (-not $Json.$field) { Fail "Missing output field: $field" }
}
```

Both approaches are ~15 lines. The `.md` version is simpler because it avoids JSON parsing failure modes.

---

## How Continuation Handoff Becomes Automatable

The continuation handoff section has 4 required sub-fields:
1. Context to carry forward
2. Boundary note
3. Next candidate goal
4. Prompt seed

### `.md` validation:
Regex-match the section header, then verify the 4 bullet points appear within the section body:

```powershell
if ($Content -notmatch 'Continuation Handoff[\s\S]*Context') { Fail "Missing handoff context" }
if ($Content -notmatch 'Continuation Handoff[\s\S]*Boundary') { Fail "Missing handoff boundary" }
if ($Content -notmatch 'Continuation Handoff[\s\S]*Next candidate') { Fail "Missing handoff next candidate" }
if ($Content -notmatch 'Continuation Handoff[\s\S]*Prompt seed') { Fail "Missing handoff prompt seed" }
```

### `.json` validation:
Direct field access:

```powershell
$handoff = $Json.continuation_handoff
foreach ($field in @('context', 'boundary', 'next_candidate', 'prompt_seed')) {
    if (-not $handoff.$field) { Fail "Missing handoff field: $field" }
}
```

JSON is cleaner for nested structure. Markdown requires multi-line regex which is more fragile.

---

## Failure Modes

| Failure | `.md` | `.json` | Mitigation |
|---|---|---|---|
| Claude forgets to write artifact | Test FAILs (correct behavior) | Test FAILs (correct behavior) | None needed — this is a valid failure |
| Claude writes malformed JSON | N/A | `ConvertFrom-Json` throws, test FAILs | Use `.md` to eliminate parsing |
| Section header formatting drift | Regex may miss section | N/A (structured fields) | Define exact header format in contract |
| Stale artifact from previous goal | Test validates wrong output | Test validates wrong output | Claude overwrites on every goal completion |
| Artifact exists but content is wrong | Test passes (only checks presence) | Test passes (only checks presence) | Cross-check `changed_files` vs `git diff` |
| `.gitignore` missing | Artifact enters git history | Artifact enters git history | Must be part of the same commit that introduces the feature |

---

## Cleanup Strategy

**No explicit cleanup needed.** The artifact lifecycle is:

1. **Create:** Claude writes `.agents/dev-protocol/goal-output.*` at goal completion
2. **Validate:** `run-tests.ps1` reads it during case-06 execution
3. **Overwrite:** Next goal completion overwrites the file automatically
4. **Ignore:** `.gitignore` prevents tracking

No temp directory management, no cleanup hooks, no file rotation. The file is self-managing through overwrite semantics.

If Claude crashes before writing the artifact: test FAILs with "missing artifact" — correct behavior for an incomplete goal.

---

## Recommendation: `goal-output.json` with `.gitignore`

**Winner: `.json` format**, despite the escaping edge cases, because:

1. **Nested structure maps cleanly** — continuation handoff has 4 sub-fields. JSON handles this natively; markdown requires multi-line regex parsing.
2. **Cross-check is exact** — `changed_files` array can be compared against `git diff --name-only` with set operations. No regex needed.
3. **Field-level failure is specific** — test reports "missing `stop_reason`" not "section header not found." Debugging is faster.
4. **Validation completeness** — can assert `goal_status` is one of the 5 allowed values (`COMPLETED`, `PARTIALLY_COMPLETED`, etc.), which markdown regex cannot do without additional logic.

**Escaping risk is manageable:** The prompt seed is the only field likely to cause JSON issues. Mitigation: define in the contract that prompt seeds should use `~`-quoted strings or be escaped. Claude is capable of producing valid JSON.

### Required Changes (all within allowed scope)

**1. `.gitignore` — add entry:**
```
# Session output artifacts — validated by case-06, not versioned
.agents/dev-protocol/goal-output.json
```

**2. `.agents/dev-protocol/docs/goal-output-contract.md` — add under Hard Rules:**
```
At goal completion, write `.agents/dev-protocol/goal-output.json` containing all
required sections as structured data. This file is untracked (gitignored) and
exists solely for automated validation.
```

Add a JSON schema appendix showing the exact expected structure.

**3. `tests/case-06-goal-workflow/test-plan.md` — move output contract from Manual to Automated:**
```
Automated assertions (additional):
- goal-output.json exists in .agents/dev-protocol/
- contains goal_status field with valid value
- contains stop_reason field with non-empty value
- contains continuation_handoff with all 4 sub-fields
- changed_files matches git diff --name-only HEAD~1..HEAD
```

**4. `docs/deferred-improvements.md` — update item 1:**
Change status from "Why deferred" to "Recommended approach: JSON artifact emission with .gitignore." Update item 4 to "Unblocked — continuation handoff fields are validated from the same JSON artifact."

### Phase Boundary: Design vs. Implementation

This document is a design recommendation. It deliberately does **not** modify `run-tests.ps1`.

However, the **implementation phase WILL extend** case-06 validation in `run-tests.ps1` to:
- assert `goal-output.json` existence
- validate required fields (`goal_status`, `summary`, `stop_reason`)
- assert `continuation_handoff` sub-fields
- cross-check `changed_files` against `git diff --name-only`

The constraint "do not modify `run-tests.ps1`" applies only to this design goal. Implementation will require extending the case-06 block.

### What This Does NOT Change (Beyond run-tests.ps1)

- Claude's session output text (it still produces the same terminal summary)
- Any skill definitions
- Any workflow behavior

The JSON artifact is **additional** output, not a replacement for the terminal summary. It is a validation scratch file that lives on disk, never enters git, and gets overwritten on each goal completion.

---

## Validation Gap: Untracked Files Are Invisible to Case-06

### The Problem

Case-06 validates workspace cleanliness via `git diff --quiet` and `git diff --cached --quiet`. These commands only detect **tracked** file changes. Untracked files are completely invisible.

This means case-06 will **PASS** even if:
- Dozens of untracked files litter the workspace
- The `goal-output.json` artifact exists or is missing — neither affects the test
- Any other untracked artifact accumulates over time

### Why This Is Dangerous

Without `.gitignore`, the session-output artifact has two failure modes:

1. **Accidentally tracked:** If Claude adds the file to git (e.g., via `git add -A`), it becomes a tracked change, inflates the scope count, and pollutes the commit history with a file that carries no historical value.

2. **Accidentally ignored by the test:** If `.gitignore` is missing, the artifact sits as an untracked file. Case-06 passes regardless of whether it exists. The entire validation benefit of the artifact is lost unless `run-tests.ps1` explicitly asserts its presence.

### Why `.gitignore` Is Non-Negotiable

`.gitignore` serves two purposes simultaneously:

1. **Prevents tracking:** The artifact never enters git, never inflates scope, never pollutes history.
2. **Defines the validation contract:** `.gitignore` is the signal that this file is a scratch artifact. `run-tests.ps1` can then assert "file must exist on disk" with confidence that its absence is a genuine failure, not a git tracking artifact.

### Recommendation for Future Case-06 Enhancement

Add an untracked-file detection assertion to case-06:

```powershell
# Detect unexpected untracked files in .agents/dev-protocol/
$Untracked = & git ls-files --others --exclude-standard -- .agents/dev-protocol/
# Filter out known-safe untracked files (e.g., goal-output.json)
$KnownIgnored = @('.agents/dev-protocol/goal-output.json')
$Unexpected = $Untracked | Where-Object { $_ -notin $KnownIgnored }
if ($Unexpected.Count -gt 0) {
    Fail "case-06: unexpected untracked files: $($Unexpected -join ', ')"
}
```

This ensures case-06 can detect workspace pollution from sources other than the session-output artifact, closing the blind spot without breaking the artifact's untracked status.
