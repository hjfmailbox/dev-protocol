param(
    [Parameter(Mandatory = $true)]
    [string]$Case,

    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

function Fail {
    param([string]$Msg)
    Write-Host "[FAIL] $Msg"
    Write-Host ""
    Write-Host "RESULT: FAIL"
    exit 1
}

function Pass-Check {
    param([string]$Msg)
    Write-Host "[PASS] $Msg"
}

# ── A. Workspace clean ──────────────────────────────────────────────

git diff --quiet
if ($LASTEXITCODE -ne 0) {
    Fail "Working tree is dirty (git diff is not quiet)"
}
Pass-Check "Workspace clean"

git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    Fail "Staged changes detected"
}
Pass-Check "No staged changes"

# ── B. Test plan exists ─────────────────────────────────────────────

$CaseDir = Join-Path $PSScriptRoot "case-$Case-first-checkpoint"
$TestPlan = Join-Path $CaseDir "test-plan.md"

if (-not (Test-Path $TestPlan)) {
    Fail "test-plan.md not found at $TestPlan"
}
Pass-Check "test-plan.md exists"

# ── C. State files exist ────────────────────────────────────────────

if ($ProjectRoot) {
    $Root = $ProjectRoot
} else {
    $Root = $PWD.Path
}
$StateRoot = Join-Path $Root ".agent/dev-protocol"

$Files = @(
    "workflow-state.yml",
    "handoff.md",
    "project-rules.md"
)

foreach ($f in $Files) {
    $Path = Join-Path $StateRoot $f
    if (-not (Test-Path $Path)) {
        Fail "Required file missing: $f"
    }
}
Pass-Check "All required state files exist"

# ── D. last_commit is a valid hash ──────────────────────────────────

$StateFile = Join-Path $StateRoot "workflow-state.yml"
$Content = Get-Content $StateFile -Raw

$Match = [regex]::Match($Content, 'last_commit:\s*"([a-f0-9]{7,40})"')

if (-not $Match.Success) {
    Fail "last_commit does not match valid hash pattern [a-f0-9]{7,40}"
}
Pass-Check "last_commit matches valid hash: $($Match.Groups[1].Value)"

# ── E. Final result ─────────────────────────────────────────────────

Write-Host ""
Write-Host "RESULT: PASS"
