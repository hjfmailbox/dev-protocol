# Comprehensive Stop Hook Diagnostic Script
# Captures all possible failure modes for JSON validation

$ErrorActionPreference = 'Continue'
$LogFile = ".claude/hooks/diagnosis-log.txt"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

$LogEntry = @"

================================================================================
COMPREHENSIVE STOP HOOK DIAGNOSTIC - $Timestamp
================================================================================
PID: $PID
Working Directory: $(Get-Location)
PowerShell Version: $($PSVersionTable.PSVersion)

"@

function Write-Log {
    param([string]$Message)
    $script:LogEntry += "[$(Get-Date -Format 'HH:mm:ss.fff')] $Message`n"
}

Write-Log "Diagnostic started"

# 1. Check multiple possible file paths
Write-Log "=== FILE PATH ANALYSIS ==="
$PossiblePaths = @(
    ".agents/dev-protocol/goal-output.json",
    "goal-output.json",
    "./.agents/dev-protocol/goal-output.json",
    "$(Get-Location)/.agents/dev-protocol/goal-output.json",
    "$(Get-Location)/goal-output.json",
    "$env:USERPROFILE/.claude/goal-output.json"
)

foreach ($path in $PossiblePaths) {
    $exists = Test-Path $path
    Write-Log "  Path: $path"
    Write-Log "    Exists: $exists"
    if ($exists) {
        $file = Get-Item $path
        Write-Log "    Size: $($file.Length) bytes"
        Write-Log "    LastWrite: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss.fff'))"
    }
}

# 2. Validate JSON using multiple methods
Write-Log "`n=== JSON VALIDATION USING MULTIPLE METHODS ==="
$JsonPath = ".agents/dev-protocol/goal-output.json"

if (Test-Path $JsonPath) {
    $RawContent = Get-Content $JsonPath -Raw
    Write-Log "Raw content length: $($RawContent.Length)"
    Write-Log "Raw content (first 500 chars):"
    $preview = if ($RawContent.Length -gt 500) { $RawContent.Substring(0, 500) + "..." } else { $RawContent }
    $LogEntry += "  $preview`n"

    # Check encoding
    $bytes = [System.IO.File]::ReadAllBytes($JsonPath)
    Write-Log "File size in bytes: $($bytes.Length)"
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Log "WARNING: File has UTF-8 BOM"
    } else {
        Write-Log "No BOM detected"
    }

    # Method 1: PowerShell ConvertFrom-Json
    Write-Log "`nMethod 1: PowerShell ConvertFrom-Json"
    try {
        $psJson = $RawContent | ConvertFrom-Json -ErrorAction Stop
        Write-Log "  Result: SUCCESS"
        Write-Log "  Type: $($psJson.GetType().Name)"
    } catch {
        Write-Log "  Result: FAILED"
        Write-Log "  Error: $($_.Exception.Message)"
    }

    # Method 2: .NET JsonDocument
    Write-Log "`nMethod 2: .NET System.Text.Json"
    try {
        $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($RawContent)
        $doc = [System.Text.Json.JsonDocument]::Parse($utf8Bytes)
        Write-Log "  Result: SUCCESS"
        Write-Log "  Root element kind: $($doc.RootElement.ValueKind)"
        $doc.Dispose()
    } catch {
        Write-Log "  Result: FAILED"
        Write-Log "  Error: $($_.Exception.Message)"
    }

    # Method 3: Python json module (if available)
    Write-Log "`nMethod 3: Python json module"
    try {
        $pythonResult = python -c "import json; data=json.load(open('$JsonPath')); print('SUCCESS')" 2>&1
        Write-Log "  Result: $pythonResult"
    } catch {
        Write-Log "  Result: UNAVAILABLE or FAILED"
        Write-Log "  Error: $($_.Exception.Message)"
    }

    # Method 4: Check for trailing commas (common JSON error)
    Write-Log "`nMethod 4: Trailing comma check"
    $hasTrailingComma = $RawContent -match ',\s*[}\]]'
    if ($hasTrailingComma) {
        Write-Log "  WARNING: Trailing commas detected"
        $matches = [regex]::Matches($RawContent, ',\s*[}\]]')
        foreach ($match in $matches) {
            Write-Log "    Position $($match.Index): $($match.Value)"
        }
    } else {
        Write-Log "  No trailing commas found"
    }

    # Method 5: Check for comments (not valid in standard JSON)
    Write-Log "`nMethod 5: Comment check"
    $hasComments = $RawContent -match '(?m)^\s*//|^\s*/\*'
    if ($hasComments) {
        Write-Log "  WARNING: Comments detected in JSON"
    } else {
        Write-Log "  No comments found"
    }

} else {
    Write-Log "JSON file not found at expected path"
}

# 3. Check if there are multiple goal-output.json files
Write-Log "`n=== SEARCH FOR ALL goal-output.json FILES ==="
$allJsonFiles = Get-ChildItem -Recurse -Filter "goal-output.json" -ErrorAction SilentlyContinue
if ($allJsonFiles) {
    foreach ($file in $allJsonFiles) {
        Write-Log "  Found: $($file.FullName)"
        Write-Log "    Size: $($file.Length) bytes"
        Write-Log "    LastWrite: $($file.LastWriteTime)"
    }
} else {
    Write-Log "  No goal-output.json files found anywhere"
}

# 4. Check git state at hook execution time
Write-Log "`n=== GIT STATE ==="
$headCommit = git log --format=%H -1 2>$null
$headMessage = git log --format=%s -1 2>$null
Write-Log "HEAD commit: $headCommit"
Write-Log "HEAD message: $headMessage"

$gitFiles = git diff-tree --no-commit-id --name-only -r HEAD 2>$null
Write-Log "Files in HEAD commit:"
$gitFiles | ForEach-Object { Write-Log "  - $_" }

# 5. Check for environment variables that might affect paths
Write-Log "`n=== ENVIRONMENT VARIABLES ==="
Write-Log "PWD: $env:PWD"
Write-Log "USERPROFILE: $env:USERPROFILE"
Write-Log "HOME: $env:HOME"
Write-Log "CLAUDE_CONFIG_DIR: $env:CLAUDE_CONFIG_DIR"

# Summary
$LogEntry += "`n================================================================================`n"
$LogEntry += "DIAGNOSTIC COMPLETE`n"
$LogEntry += "================================================================================`n"

# Write to log
$LogEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8
Write-Error "DIAGNOSTIC LOG: See $LogFile for details"

exit 0
