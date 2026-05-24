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
        $json.changed_files = $changedFiles
        $json | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
        $fixed = $true
        Write-Host "[JSON] Fixed changed_files in $jsonPath"
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
