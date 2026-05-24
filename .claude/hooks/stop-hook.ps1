# Stop Hook with Pre-Validation Normalization
# Eliminates timing race by normalizing artifact BEFORE validation.
# Guarantees validation never sees an invalid intermediate state.

$ErrorActionPreference = 'Stop'

$JsonPath = ".agents/dev-protocol/goal-output.json"
$MdPath   = ".agents/dev-protocol/goal-output.md"

# ── Step 1: Normalization ──────────────────────────────────────────
# If artifacts exist, run fix-goal-output.ps1 to normalize changed_files
# and schema BEFORE any validation occurs.

$artifactsExist = (Test-Path $JsonPath) -or (Test-Path $MdPath)

if ($artifactsExist) {
    $fixScript = "scripts/fix-goal-output.ps1"
    if (Test-Path $fixScript) {
        try {
            & pwsh $fixScript 2>&1 | ForEach-Object { Write-Host $_ }
        } catch {
            Write-Error "Normalization failed: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Error "Normalization script not found: $fixScript"
        exit 1
    }
}

# ── Step 2: Validation ─────────────────────────────────────────────
# Validate the NORMALIZED artifact. If normalization succeeded,
# this should always pass unless git state is inconsistent.

$errors = @()

# Prefer JSON; fall back to MD if JSON absent
if (Test-Path $JsonPath) {
    try {
        $json = Get-Content $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

        # Required top-level fields
        $requiredFields = @('goal_status', 'goal_summary', 'changed_files', 'validation_results', 'stop_reason', 'risks_followups', 'continuation_handoff')
        foreach ($field in $requiredFields) {
            if ($null -eq $json.$field) {
                $errors += "Missing required field: $field"
            }
        }

        # goal_status enum
        $validStatuses = @('COMPLETED', 'PARTIALLY_COMPLETED', 'BLOCKED', 'FAILED', 'ABORTED')
        if ($json.goal_status -notin $validStatuses) {
            $errors += "Invalid goal_status: $($json.goal_status)"
        }

        # Type checks
        if ($json.changed_files -isnot [array]) {
            $errors += "changed_files must be an array"
        }
        if ($json.validation_results -isnot [array]) {
            $errors += "validation_results must be an array"
        }
        if ($json.risks_followups -isnot [array]) {
            $errors += "risks_followups must be an array"
        }

        # continuation_handoff sub-fields
        $handoffFields = @('context', 'boundary', 'next_candidate_goal', 'prompt_seed')
        if ($json.continuation_handoff -isnot [pscustomobject]) {
            $errors += "continuation_handoff must be an object"
        } else {
            foreach ($field in $handoffFields) {
                if ($null -eq $json.continuation_handoff.$field) {
                    $errors += "Missing continuation_handoff sub-field: $field"
                }
            }
        }

        # Integrity: changed_files must match git diff-tree HEAD
        $gitFiles = @(git diff-tree --no-commit-id --name-only -r HEAD | Sort-Object)
        if ($json.changed_files -is [array]) {
            $jsonFiles = @($json.changed_files) | Sort-Object
            if (($gitFiles -join "`n") -ne ($jsonFiles -join "`n")) {
                $errors += "changed_files mismatch with git diff-tree HEAD"
                $errors += "  Git:   $($gitFiles -join ', ')"
                $errors += "  JSON:  $($jsonFiles -join ', ')"
            }
        }
    } catch {
        $errors += "JSON parsing failed: $($_.Exception.Message)"
    }
} elseif (Test-Path $MdPath) {
    # Markdown fallback: check required section headers
    $content = Get-Content $MdPath -Raw
    $requiredSections = @('Goal Status', 'Goal Summary', 'Changed Files', 'Validation Results', 'Stop Reason', 'Risks / Follow-ups', 'Continuation Handoff')
    foreach ($section in $requiredSections) {
        $pattern = "(?m)^##\s+$([regex]::Escape($section))\s*$"
        if ($content -notmatch $pattern) {
            $errors += "MD missing section: $section"
        }
    }

    # Check goal_status enum in MD
    if ($content -match '(?m)^## Goal Status\r?\n\s*(COMPLETED|PARTIALLY_COMPLETED|BLOCKED|FAILED|ABORTED)\s*$') {
        # valid
    } else {
        $errors += "MD Goal Status missing or invalid"
    }
} else {
    # No artifacts found — this is fine if no goal is active.
    # Exit silently so non-goal sessions are not blocked.
    exit 0
}

# ── Step 3: Result ─────────────────────────────────────────────────
if ($errors.Count -gt 0) {
    Write-Error "STOP HOOK VALIDATION FAILED:"
    foreach ($err in $errors) {
        Write-Error "  - $err"
    }
    exit 1
}

Write-Host "Stop hook: normalization + validation PASSED"
exit 0
