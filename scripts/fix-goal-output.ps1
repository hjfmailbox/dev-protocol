# fix-goal-output.ps1
# Deterministically set changed_files in goal-output artifacts from git state.
# Handles both .json and .md formats. Eliminates LLM involvement entirely.

param(
    [string]$Dir = ".agents/dev-protocol"
)

$ErrorActionPreference = 'Stop'

$jsonPath = Join-Path $Dir "goal-output.json"
$mdPath   = Join-Path $Dir "goal-output.md"

# Get authoritative file list from git (sorted for determinism)
$changedFiles = @(git diff-tree --no-commit-id --name-only -r HEAD | Sort-Object)

if ($changedFiles.Count -eq 0) {
    Write-Warning "No files changed in HEAD commit"
    Write-Warning "Cannot fix changed_files"
    exit 0
}

$fixed = $false

# ── Fix JSON artifact ──────────────────────────────────────────────

if (Test-Path $jsonPath) {
    try {
        $json = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $schemaFixed = $false

        # Fix changed_files (deterministic from git)
        $json.changed_files = $changedFiles
        Write-Host "[JSON] Fixed changed_files ($($changedFiles.Count) files)"

        # Validate and fix schema: validation_results must be array
        if ($json.validation_results -is [string]) {
            Write-Host "[JSON] Fixing validation_results: string -> array" -ForegroundColor Yellow
            $json.validation_results = @($json.validation_results)
            $schemaFixed = $true
        } elseif ($json.validation_results -isnot [array]) {
            Write-Host "[JSON] Fixing validation_results: missing/invalid -> empty array" -ForegroundColor Yellow
            $json.validation_results = @()
            $schemaFixed = $true
        }

        # Validate and fix schema: risks_followups must be array
        if ($json.risks_followups -is [string]) {
            Write-Host "[JSON] Fixing risks_followups: string -> array" -ForegroundColor Yellow
            $json.risks_followups = @($json.risks_followups)
            $schemaFixed = $true
        } elseif ($json.risks_followups -isnot [array]) {
            Write-Host "[JSON] Fixing risks_followups: missing/invalid -> empty array" -ForegroundColor Yellow
            $json.risks_followups = @()
            $schemaFixed = $true
        }

        # Validate goal_status enum
        if ($json.goal_status -notin @("COMPLETED", "PARTIALLY_COMPLETED", "BLOCKED", "FAILED", "ABORTED")) {
            Write-Warning "[JSON] Invalid goal_status: $($json.goal_status) (must be COMPLETED/PARTIALLY_COMPLETED/BLOCKED/FAILED/ABORTED)"
        }

        # Ensure continuation_handoff is an object with required fields
        if (-not $json.continuation_handoff -or $json.continuation_handoff -isnot [pscustomobject]) {
            Write-Host "[JSON] Fixing continuation_handoff: missing/invalid -> object" -ForegroundColor Yellow
            $json.continuation_handoff = @{
                context = ""
                boundary = ""
                next_candidate_goal = ""
                prompt_seed = ""
            }
            $schemaFixed = $true
        }

        $json | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
        $fixed = $true

        if ($schemaFixed) {
            Write-Host "[JSON] Schema fixes applied and saved" -ForegroundColor Green
        } else {
            Write-Host "[JSON] Schema valid (no fixes needed)"
        }
    } catch {
        Write-Warning "[JSON] Failed to parse $jsonPath — $($_.Exception.Message)"
        Write-Warning "[JSON] Deleting malformed JSON so test falls back to .md"
        Remove-Item $jsonPath -Force
    }
}

# ── Fix Markdown artifact ──────────────────────────────────────────

if (Test-Path $mdPath) {
    $content = Get-Content $mdPath -Raw -Encoding UTF8

    # Match from "## Changed Files" to the next "## " heading or end of file
    $pattern = '(?ms)^## Changed Files\r?\n.*?(?=\r?\n## |\z)'

    $fileList = ($changedFiles | ForEach-Object { "- $_" }) -join "`r`n"
    $replacement = "## Changed Files`r`n`r`n$fileList"

    $newContent = $content -replace $pattern, $replacement

    if ($newContent -eq $content) {
        Write-Warning "[MD] No '## Changed Files' section found in $mdPath"
    } else {
        Set-Content $mdPath $newContent -Encoding UTF8 -NoNewline
        $fixed = $true
        Write-Host "[MD]   Fixed changed_files in $mdPath"
    }
}

if (-not $fixed) {
    Write-Error "No artifacts found to fix"
    Write-Error "Expected: $jsonPath or $mdPath"
    exit 1
}

Write-Host ""
Write-Host "Files included: $($changedFiles.Count)"
Write-Host ""
Write-Host "Changed files:"
$changedFiles | ForEach-Object { Write-Host "  - $_" }
