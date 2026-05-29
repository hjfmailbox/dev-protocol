#requires -Version 5.1
<#
.SYNOPSIS
    Passive runtime telemetry event recorder for dev-protocol.
.DESCRIPTION
    Appends a single JSONL event to the current session log.
    Reads config.json for enablement settings.
    Silently exits if telemetry is disabled.
.PARAMETER EventType
    Required. One of: command_invoked, command_result, workflow_transition, drift_snapshot, loop_execution.
.PARAMETER Command
    Command name (e.g. '/dev-status').
.PARAMETER Status
    Result status: success or failure.
.PARAMETER Reason
    Failure reason or additional context.
.PARAMETER From
    Workflow transition source step.
.PARAMETER To
    Workflow transition destination step.
.PARAMETER LoopId
    Loop identifier.
.PARAMETER AutoExecuted
    Switch. Indicates loop was auto-executed.
.PARAMETER Scope
    Scope description for loop_execution.
.PARAMETER Drift
    Drift level: none, low, high.
.PARAMETER Phase
    Current project phase.
.PARAMETER Focus
    Current focus string.
.PARAMETER CheckpointOutdatedCommits
    Number of commits since last checkpoint.
.PARAMETER DurationMs
    Command duration in milliseconds.
.PARAMETER Args
    Command arguments string.
.PARAMETER Project
    Project name override.
.PARAMETER RepoRoot
    Repository root path override.
.PARAMETER GitBranch
    Git branch override.
.PARAMETER WorkspaceClean
    Switch. Indicates workspace is clean.
.PARAMETER SessionFile
    Explicit session file path. If omitted, derives from current session or creates new.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('command_invoked', 'command_result', 'workflow_transition', 'drift_snapshot', 'loop_execution', 'session_context_snapshot')]
    [string]$EventType,

    [string]$Command,
    [string]$Status,
    [string]$Reason,
    [string]$From,
    [string]$To,
    [string]$LoopId,
    [switch]$AutoExecuted,
    [string]$Scope,
    [string]$Drift,
    [string]$Phase,
    [string]$Focus,
    [int]$CheckpointOutdatedCommits,
    [int]$DurationMs,
    [string]$Args,
    [string]$Project,
    [string]$RepoRoot,
    [string]$GitBranch,
    [switch]$WorkspaceClean,
    [string]$SessionFile,
    [string]$ActiveWork,
    [string]$CheckpointCommit,
    [string]$HeadCommit,
    [string]$Freshness
)

$ErrorActionPreference = 'Stop'

# ── Resolve repository root ──────────────────────────────────────────

function Get-RepoRoot {
    $start = if ($RepoRoot) { $RepoRoot } else { $PWD.Path }
    $current = $start
    while ($current -and $current -ne (Split-Path $current -Parent)) {
        if (Test-Path (Join-Path $current '.git')) {
            return $current
        }
        $current = Split-Path $current -Parent
    }
    return $start
}

$Root = Get-RepoRoot

# ── Load config ──────────────────────────────────────────────────────

$TelemetryDir = Join-Path $Root '.agents/dev-protocol/runtime-telemetry'
$ConfigPath = Join-Path $TelemetryDir 'config.json'

$Config = @{
    enabled             = $true
    record_command_args = $true
    record_git_context  = $true
}

if (Test-Path $ConfigPath) {
    try {
        $Loaded = Get-Content $ConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop
        if ($null -ne $Loaded.enabled) { $Config.enabled = [bool]$Loaded.enabled }
        if ($null -ne $Loaded.record_command_args) { $Config.record_command_args = [bool]$Loaded.record_command_args }
        if ($null -ne $Loaded.record_git_context) { $Config.record_git_context = [bool]$Loaded.record_git_context }
    }
    catch {
        # Config corrupt: default to enabled, but don't emit errors
    }
}

if (-not $Config.enabled) {
    exit 0
}

# ── Derive git context ───────────────────────────────────────────────

$GitCtx = @{}
if ($Config.record_git_context) {
    try {
        $GitCtx.branch = & git -C $Root rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -ne 0) { $GitCtx.branch = $null }
    }
    catch { $GitCtx.branch = $null }

    try {
        $diffExit = 0
        & git -C $Root diff --quiet 2>$null
        $diffExit = $LASTEXITCODE
        & git -C $Root diff --cached --quiet 2>$null
        $GitCtx.workspace_clean = ($diffExit -eq 0 -and $LASTEXITCODE -eq 0)
    }
    catch {
        $GitCtx.workspace_clean = $null
    }
}

# ── Resolve project name ─────────────────────────────────────────────

$ProjectName = if ($Project) {
    $Project
}
else {
    $wf = Join-Path $Root '.agents/dev-protocol/workflow-state.yml'
    if (Test-Path $wf) {
        $content = Get-Content $wf -Raw
        $m = [regex]::Match($content, 'name:\s*(.+)')
        if ($m.Success) { $m.Groups[1].Value.Trim() }
        else { Split-Path $Root -Leaf }
    }
    else {
        Split-Path $Root -Leaf
    }
}

# ── Build event ──────────────────────────────────────────────────────

$Event = [ordered]@{
    timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    event_type = $EventType
}

if ($Command) { $Event.command = $Command }
if ($Config.record_command_args -and $Args) { $Event.args = $Args }
if ($Status) { $Event.status = $Status }
if ($Reason) { $Event.reason = $Reason }
if ($From) { $Event.from = $From }
if ($To) { $Event.to = $To }
if ($LoopId) { $Event.loop_id = $LoopId }
if ($PSBoundParameters.ContainsKey('AutoExecuted')) { $Event.auto_executed = [bool]$AutoExecuted }
if ($Scope) { $Event.scope = $Scope }
if ($Drift) { $Event.drift = $Drift }
if ($Phase) { $Event.phase = $Phase }
if ($Focus) { $Event.focus = $Focus }
if ($PSBoundParameters.ContainsKey('CheckpointOutdatedCommits')) { $Event.checkpoint_outdated_commits = $CheckpointOutdatedCommits }
if ($PSBoundParameters.ContainsKey('DurationMs')) { $Event.duration_ms = $DurationMs }
if ($ActiveWork) { $Event.active_work = $ActiveWork }
if ($CheckpointCommit) { $Event.checkpoint_commit = $CheckpointCommit }
if ($HeadCommit) { $Event.head_commit = $HeadCommit }
if ($Freshness) { $Event.freshness = $Freshness }

$Event.project = $ProjectName
$Event.repo_root = $Root
if ($GitCtx.branch) { $Event.git_branch = $GitCtx.branch }
if ($PSBoundParameters.ContainsKey('WorkspaceClean')) {
    $Event.workspace_clean = [bool]$WorkspaceClean
}
elseif ($null -ne $GitCtx.workspace_clean) {
    $Event.workspace_clean = $GitCtx.workspace_clean
}

# ── Resolve session file ─────────────────────────────────────────────

$Today = Get-Date -Format 'yyyy-MM-dd'
$SessionsDir = Join-Path $TelemetryDir "sessions/$Today"

if (-not $SessionFile) {
    # Look for an existing session file created in the last hour
    if (Test-Path $SessionsDir) {
        $cutoff = (Get-Date).AddHours(-1)
        $existing = Get-ChildItem -File $SessionsDir -Filter '*.jsonl' -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -gt $cutoff } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($existing) {
            $SessionFile = $existing.FullName
        }
    }
}

if (-not $SessionFile) {
    if (-not (Test-Path $SessionsDir)) {
        New-Item -ItemType Directory -Path $SessionsDir -Force | Out-Null
    }
    $rnd = -join ((1..4) | ForEach-Object { 'abcdef0123456789'[(Get-Random -Maximum 16)] })
    $ts = Get-Date -Format 'yyyy-MM-ddTHH-mm-ss'
    $SessionFile = Join-Path $SessionsDir "$($ts)_$rnd.jsonl"
}

# ── Write event ──────────────────────────────────────────────────────

$Line = ($Event | ConvertTo-Json -Compress)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::AppendAllText($SessionFile, $Line + [System.Environment]::NewLine, $Utf8NoBom)

exit 0
