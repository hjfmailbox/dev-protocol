param(
    [Parameter(Mandatory = $true)]
    [string]$Case,

    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

# ── Case directory mapping ──────────────────────────────────────────

function Get-CaseDirName {
    param([string]$Case)
    switch ($Case) {
        '05' { return 'case-05-first-checkpoint' }
        '06' { return 'case-06-goal-workflow' }
        default { return "case-$Case" }
    }
}

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

$CaseDirName = Get-CaseDirName -Case $Case
$CaseDir = Join-Path $PSScriptRoot $CaseDirName
$TestPlan = Join-Path $CaseDir "test-plan.md"

if (-not (Test-Path $TestPlan)) {
    Fail "test-plan.md not found at $TestPlan"
}
Pass-Check "test-plan.md exists"

# ── C. State files exist (case-05 only) ─────────────────────────────

if ($Case -eq '05') {
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

    # ── D. last_commit is a valid hash ──────────────────────────────

    $StateFile = Join-Path $StateRoot "workflow-state.yml"
    $Content = Get-Content $StateFile -Raw

    $Match = [regex]::Match($Content, 'last_commit:\s*"([a-f0-9]{7,40})"')

    if (-not $Match.Success) {
        Fail "last_commit does not match valid hash pattern [a-f0-9]{7,40}"
    }
    Pass-Check "last_commit matches valid hash: $($Match.Groups[1].Value)"

    # ── F. last_commit matches HEAD~1 ───────────────────────────────

    $HeadParent = & git -C $Root rev-parse --short HEAD~1 2>$null
    if ($LASTEXITCODE -ne 0) {
        Fail "Cannot resolve HEAD~1 in project root ($ProjectRoot)"
    }

    if ($Match.Groups[1].Value -ne $HeadParent) {
        Fail "last_commit ($($Match.Groups[1].Value)) does not match HEAD~1 ($HeadParent)"
    }
    Pass-Check "last_commit matches HEAD~1: $HeadParent"

    # ── G. Project workspace clean ──────────────────────────────────

    & git -C $Root diff --quiet
    if ($LASTEXITCODE -ne 0) {
        Fail "Project workspace has uncommitted tracked changes"
    }

    & git -C $Root diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        Fail "Project workspace has staged changes"
    }
    Pass-Check "Project workspace clean"
}

# ── D. Case-05 specific checks (HEAD commit) ─────────────────────────

if ($Case -eq '05') {
    $HeadCommit = & git -C $Root log --format=%s -1
    if ($HeadCommit -match "dev-checkpoint.*baseline") {
        Pass-Check "HEAD commit indicates checkpoint baseline"
    }
    else {
        Fail "HEAD commit does not indicate a checkpoint baseline"
    }
}

# ── E. Case-06 specific checks ──────────────────────────────────────

if ($Case -eq '06') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-06 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-06 test-plan.md exists"

    # git diff checks already done in section A; re-assert for clarity
    & git diff --quiet
    if ($LASTEXITCODE -ne 0) {
        Fail "case-06: workspace has uncommitted tracked changes"
    }

    & git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        Fail "case-06: workspace has staged changes"
    }
    Pass-Check "case-06: git diff and git diff --cached are empty"

    $LogCount = (& git log --oneline -3 | Measure-Object).Count
    if ($LogCount -eq 0) {
        Fail "case-06: no recent commit history available"
    }
    Pass-Check "case-06: recent commit history available"

    # Verify workspace is in a valid post-goal state (not mid-checkpoint)
    $HeadCommit = & git log --format=%s -1
    if ($HeadCommit -match "dev-checkpoint.*baseline") {
        Fail "case-06: HEAD is a checkpoint commit, not a goal workflow commit"
    }
    Pass-Check "case-06: HEAD is not a checkpoint commit"
}

# ── K. Final result ──────────────────────────────────────────────────

Write-Host ""
Write-Host "RESULT: PASS"
