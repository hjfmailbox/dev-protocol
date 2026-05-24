# fix-goal-output.ps1
# Deterministically set changed_files in goal-output.md from git state
# This script eliminates LLM involvement in changed_files generation

param(
    [string]$Artifact = ".agents/dev-protocol/goal-output.md"
)

# Verify artifact exists
if (-not (Test-Path $Artifact)) {
    Write-Error "Artifact not found: $Artifact"
    Write-Error "Run this script after creating goal-output.md"
    exit 1
}

# Get authoritative file list from git (sorted for determinism)
$changedFiles = git diff-tree --no-commit-id --name-only -r HEAD | Sort-Object

if (-not $changedFiles -or $changedFiles.Count -eq 0) {
    Write-Warning "No files changed in HEAD commit"
    Write-Warning "Cannot fix changed_files section"
    exit 0
}

# Read the artifact file
$content = Get-Content $Artifact -Raw -Encoding UTF8

# Regex to match the Changed Files section
# Matches from "## Changed Files" to the next "## " heading or end of file
$pattern = '(?ms)^## Changed Files\r?\n.*?(?=\r?\n## |\z)'

# Build the replacement section
$replacement = @"
## Changed Files

$($changedFiles | ForEach-Object { "- $_" } | Join-String -Separator "`r`n")
"@

# Replace the section
$newContent = $content -replace $pattern, $replacement

if ($newContent -eq $content) {
    Write-Warning "No '## Changed Files' section found in $Artifact"
    Write-Warning "File unchanged"
    exit 1
}

# Write back (preserve UTF-8 encoding)
Set-Content $Artifact $newContent -Encoding UTF8 -NoNewline

Write-Host "Fixed changed_files in $Artifact"
Write-Host "Files included: $($changedFiles.Count)"
Write-Host ""
Write-Host "Changed files:"
$changedFiles | ForEach-Object { Write-Host "  - $_" }
