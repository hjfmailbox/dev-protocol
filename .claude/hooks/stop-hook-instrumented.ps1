# Instrumented Stop Hook for Diagnosing JSON Validation Issues
# This hook logs detailed execution information to help identify root cause

$ErrorActionPreference = 'Continue'
$LogFile = ".claude/hooks/stop-hook-log.txt"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

# Initialize log entry
$LogEntry = @"

================================================================================
STOP HOOK EXECUTION - $Timestamp
================================================================================
Working Directory: $(Get-Location)
PowerShell Version: $($PSVersionTable.PSVersion)

"@

# Function to log messages
function Write-Log {
    param([string]$Message)
    $script:LogEntry += "[$(Get-Date -Format 'HH:mm:ss.fff')] $Message`n"
}

Write-Log "Hook execution started"

# Check for goal-output.json
$JsonPath = ".agents/dev-protocol/goal-output.json"
$MdPath = ".agents/dev-protocol/goal-output.md"

Write-Log "Checking for artifacts..."
Write-Log "  JSON path: $JsonPath"
Write-Log "  MD path: $MdPath"

$JsonExists = Test-Path $JsonPath
$MdExists = Test-Path $MdPath

Write-Log "  JSON exists: $JsonExists"
Write-Log "  MD exists: $MdExists"

if ($JsonExists) {
    Write-Log "Reading JSON file..."

    try {
        # Get file metadata
        $JsonFile = Get-Item $JsonPath
        $LastWriteTime = $JsonFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fff")
        $FileSize = $JsonFile.Length

        Write-Log "  File last modified: $LastWriteTime"
        Write-Log "  File size: $FileSize bytes"

        # Read raw content
        $RawContent = Get-Content $JsonPath -Raw
        Write-Log "  Raw content length: $($RawContent.Length) characters"

        # Log first 500 chars of raw content for inspection
        $Preview = if ($RawContent.Length -gt 500) {
            $RawContent.Substring(0, 500) + "..."
        } else {
            $RawContent
        }
        Write-Log "  Raw content preview:"
        $LogEntry += "$Preview`n"

        # Attempt to parse JSON
        Write-Log "Attempting to parse JSON..."
        $Json = $RawContent | ConvertFrom-Json -ErrorAction Stop
        Write-Log "  JSON parsing: SUCCESS"

        # Validate required fields
        Write-Log "Validating schema..."
        $RequiredFields = @('goal_status', 'goal_summary', 'changed_files', 'validation_results', 'stop_reason', 'risks_followups', 'continuation_handoff')
        $MissingFields = @()

        foreach ($field in $RequiredFields) {
            $exists = $null -ne $Json.$field
            Write-Log "  Field '$field': $(if ($exists) { 'PRESENT' } else { 'MISSING' })"
            if (-not $exists) {
                $MissingFields += $field
            }
        }

        # Check field types
        Write-Log "Checking field types..."

        # changed_files should be array
        $ChangedFilesType = if ($null -eq $Json.changed_files) { 'null' } else { $Json.changed_files.GetType().Name }
        Write-Log "  changed_files type: $ChangedFilesType"
        if ($ChangedFilesType -eq 'Object[]' -or $ChangedFilesType -eq 'ArrayList') {
            Write-Log "  changed_files count: $($Json.changed_files.Count)"
        }

        # validation_results should be array
        $ValidationResultsType = if ($null -eq $Json.validation_results) { 'null' } else { $Json.validation_results.GetType().Name }
        Write-Log "  validation_results type: $ValidationResultsType"
        if ($ValidationResultsType -eq 'Object[]' -or $ValidationResultsType -eq 'ArrayList') {
            Write-Log "  validation_results count: $($Json.validation_results.Count)"
        }

        # risks_followups should be array
        $RisksType = if ($null -eq $Json.risks_followups) { 'null' } else { $Json.risks_followups.GetType().Name }
        Write-Log "  risks_followups type: $RisksType"
        if ($RisksType -eq 'Object[]' -or $RisksType -eq 'ArrayList') {
            Write-Log "  risks_followups count: $($Json.risks_followups.Count)"
        }

        # continuation_handoff should be object
        $HandoffType = if ($null -eq $Json.continuation_handoff) { 'null' } else { $Json.continuation_handoff.GetType().Name }
        Write-Log "  continuation_handoff type: $HandoffType"

        # goal_status should be string and valid enum
        $StatusType = if ($null -eq $Json.goal_status) { 'null' } else { $Json.goal_status.GetType().Name }
        Write-Log "  goal_status type: $StatusType"
        if ($StatusType -eq 'String') {
            Write-Log "  goal_status value: $($Json.goal_status)"
            $ValidStatuses = @('COMPLETED', 'PARTIALLY_COMPLETED', 'BLOCKED', 'FAILED', 'ABORTED')
            if ($Json.goal_status -in $ValidStatuses) {
                Write-Log "  goal_status: VALID"
            } else {
                Write-Log "  goal_status: INVALID (must be one of: $($ValidStatuses -join ', '))"
            }
        }

        # Check git state
        Write-Log "Checking git state..."
        $HeadHash = git rev-parse HEAD 2>$null
        $HeadCommitMsg = git log --format=%s -1 2>$null
        Write-Log "  HEAD: $HeadHash"
        Write-Log "  HEAD message: $HeadCommitMsg"

        # Get actual changed files from git
        $ActualFiles = @(git diff-tree --no-commit-id --name-only -r HEAD 2>$null) | Sort-Object
        Write-Log "  Actual changed files (from git): $($ActualFiles.Count)"
        $ActualFiles | ForEach-Object { Write-Log "    - $_" }

        # Compare with declared files
        if ($ChangedFilesType -eq 'Object[]' -or $ChangedFilesType -eq 'ArrayList') {
            $DeclaredFiles = @($Json.changed_files) | Sort-Object
            Write-Log "  Declared changed files (from JSON): $($DeclaredFiles.Count)"
            $DeclaredFiles | ForEach-Object { Write-Log "    - $_" }

            # Check for mismatch
            $Missing = @()
            $Extra = @()
            foreach ($f in $DeclaredFiles) { if ($f -notin $ActualFiles) { $Missing += $f } }
            foreach ($f in $ActualFiles) { if ($f -notin $DeclaredFiles) { $Extra += $f } }

            if ($Missing.Count -gt 0 -or $Extra.Count -gt 0) {
                Write-Log "  FILES MISMATCH DETECTED:"
                if ($Missing.Count -gt 0) {
                    Write-Log "    Missing from JSON:"
                    $Missing | ForEach-Object { Write-Log "      - $_" }
                }
                if ($Extra.Count -gt 0) {
                    Write-Log "    Extra in JSON:"
                    $Extra | ForEach-Object { Write-Log "      - $_" }
                }
            } else {
                Write-Log "  Files match: YES"
            }
        }

        Write-Log "Validation result: SUCCESS"
        $ValidationResult = "SUCCESS"

    } catch {
        Write-Log "  JSON parsing: FAILED"
        Write-Log "  Error: $($_.Exception.Message)"
        Write-Log "Validation result: FAILED"
        $ValidationResult = "FAILED"
    }
} else {
    Write-Log "JSON file not found, checking for MD fallback..."
    if ($MdExists) {
        Write-Log "  MD file exists (fallback available)"
    } else {
        Write-Log "  MD file also missing"
    }
    Write-Log "Validation result: SKIPPED (no JSON)"
    $ValidationResult = "SKIPPED"
}

# Check for fix-goal-output scripts
Write-Log "Checking for fix scripts..."
$FixScriptPs = "scripts/fix-goal-output.ps1"
$FixScriptSh = "scripts/fix-goal-output.sh"
Write-Log "  $FixScriptPs exists: $(Test-Path $FixScriptPs)"
Write-Log "  $FixScriptSh exists: $(Test-Path $FixScriptSh)"

# Log recent file modifications
Write-Log "Recent file modifications (last 5 minutes):"
$RecentFiles = @(
    $JsonPath,
    $MdPath,
    $FixScriptPs,
    $FixScriptSh
) | Where-Object { Test-Path $_ } | ForEach-Object {
    $f = Get-Item $_
    $age = (Get-Date) - $f.LastWriteTime
    if ($age.TotalMinutes -lt 5) {
        Write-Log "  $($f.Name): modified $($age.TotalSeconds.ToString('F2'))s ago"
    }
}

# Summary
$LogEntry += "`n================================================================================`n"
$LogEntry += "SUMMARY: $ValidationResult`n"
$LogEntry += "================================================================================`n"

# Write to log file
$LogEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8

# Also write to stderr so it's visible in Claude's output
Write-Error "STOP HOOK LOG: See .claude/hooks/stop-hook-log.txt for details"

# Exit successfully (don't block stopping)
exit 0
