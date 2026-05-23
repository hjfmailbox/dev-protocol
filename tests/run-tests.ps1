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
    $StateRoot = Join-Path $Root ".agents/dev-protocol"

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
    elseif ($HeadCommit -match "refactor\(state\):.*migrate") {
        Pass-Check "HEAD is a state migration commit (skipping checkpoint baseline check)"
    }
    else {
        Fail "HEAD commit does not indicate a checkpoint baseline or state migration"
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

    # ── Untracked file detection ────────────────────────────────────
    # git diff only sees tracked changes. Untracked + non-ignored files
    # are invisible to diff but can indicate workspace pollution.
    $Untracked = & git ls-files --others --exclude-standard 2>$null
    if ($Untracked -and $Untracked.Count -gt 0) {
        $FileList = $Untracked -join "`n"
        Fail "case-06: untracked files detected:`n$FileList"
    }
    Pass-Check "case-06: no untracked files"

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

    # Verify goal scope was respected (no unexpected broad modifications)
    $DiffFiles = (& git diff --name-only HEAD~1..HEAD 2>$null)
    $DiffCount = ($DiffFiles | Measure-Object).Count
    if ($DiffCount -gt 50) {
        Fail "case-06: HEAD commit changed $DiffCount files, exceeds goal scope threshold (50)"
    }
    Pass-Check "case-06: HEAD commit changed $DiffCount files (within goal scope)"

    # Verify changed files have actual content (not empty or metadata-only changes)
    $DiffStat = (& git diff --shortstat HEAD~1..HEAD 2>$null)
    $Insertions = 0
    $Deletions = 0
    if ($DiffStat -match '(\d+) insertion') { $Insertions = [int]$Matches[1] }
    if ($DiffStat -match '(\d+) deletion') { $Deletions = [int]$Matches[1] }
    $TotalLines = $Insertions + $Deletions
    if ($TotalLines -eq 0 -and $DiffCount -gt 0) {
        Fail "case-06: HEAD commit changed $DiffCount files but zero lines of content (empty or metadata-only)"
    }
    Pass-Check "case-06: HEAD commit has $Insertions insertions, $Deletions deletions (content changes confirmed)"

    # Verify HEAD commit follows conventional commit format (validated implementation)
    $HeadFullMsg = & git log --format=%s -1
    if ($HeadFullMsg -notmatch '^(feat|fix|docs|test|chore|refactor)(\(.+\))?: .+') {
        Fail "case-06: HEAD commit message does not follow conventional commit format: $HeadFullMsg"
    }
    Pass-Check "case-06: HEAD commit follows conventional commit format"

    # ── H. Goal output contract artifact ────────────────────────────
    $Artifact = Join-Path ".agents/dev-protocol" "goal-output.json"
    $FallbackMd = Join-Path ".agents/dev-protocol" "goal-output.md"
    $HasJson = Test-Path $Artifact
    $HasMd = Test-Path $FallbackMd

    if (-not $HasJson -and -not $HasMd) {
        Fail "case-06: goal-output.json and goal-output.md both missing"
    }
    Pass-Check "case-06: output contract artifact present"

    # ── I. Validate JSON or fall back to markdown ───────────────────
    $UseJson = $false
    if ($HasJson) {
        try {
            $OutputJson = Get-Content $Artifact -Raw | ConvertFrom-Json -ErrorAction Stop
            $UseJson = $true
            Pass-Check "case-06: goal-output.json is valid JSON"
        } catch {
            Write-Host "[WARN] case-06: goal-output.json malformed, falling back to goal-output.md"
        }
    }

    if ($UseJson) {
        # ── J. Required top-level fields (JSON) ─────────────────────
        $RequiredFields = @('goal_status', 'goal_summary', 'changed_files', 'validation_results', 'stop_reason', 'risks_followups', 'continuation_handoff')
        foreach ($field in $RequiredFields) {
            if ($null -eq $OutputJson.$field) {
                Fail "case-06: goal-output.json missing required field: $field"
            }
        }
        Pass-Check "case-06: all required top-level fields present (JSON)"

        # ── K. goal_status enum validation ──────────────────────────
        $ValidStatuses = @('COMPLETED', 'PARTIALLY_COMPLETED', 'BLOCKED', 'FAILED', 'ABORTED')
        if ($OutputJson.goal_status -notin $ValidStatuses) {
            Fail "case-06: goal_status '$($OutputJson.goal_status)' is not a valid value (must be one of: $($ValidStatuses -join ', '))"
        }
        Pass-Check "case-06: goal_status is valid: $($OutputJson.goal_status)"

        # ── L. Continuation handoff completeness ────────────────────
        $HandoffFields = @('context', 'boundary', 'next_candidate_goal', 'prompt_seed')
        foreach ($field in $HandoffFields) {
            $value = $OutputJson.continuation_handoff.$field
            if ($null -eq $value -or [string]::IsNullOrWhiteSpace($value)) {
                Fail "case-06: continuation_handoff missing or empty required field: $field"
            }
        }
        Pass-Check "case-06: continuation_handoff all 4 sub-fields present and non-empty (JSON)"

        # ── M. changed_files integrity ──────────────────────────────
        $ActualFiles = @(& git diff-tree --no-commit-id --name-only -r HEAD 2>$null) | Sort-Object
        $DeclaredFiles = @($OutputJson.changed_files) | Sort-Object

        $Missing = @()
        $Extra = @()
        foreach ($f in $DeclaredFiles) { if ($f -notin $ActualFiles) { $Missing += $f } }
        foreach ($f in $ActualFiles) { if ($f -notin $DeclaredFiles) { $Extra += $f } }

        if ($Missing.Count -gt 0 -or $Extra.Count -gt 0) {
            $Msg = "case-06: changed_files mismatch with HEAD commit:"
            if ($Missing.Count -gt 0) { $Msg += "`n  Declared but not in commit: $($Missing -join ', ')" }
            if ($Extra.Count -gt 0) { $Msg += "`n  In commit but not declared: $($Extra -join ', ')" }
            Fail $Msg
        }
        Pass-Check "case-06: changed_files matches HEAD commit (JSON)"
    } else {
        # ── J-alt. Required sections (Markdown fallback) ────────────
        $MdContent = Get-Content $FallbackMd -Raw

        $MdSections = @(
            'Goal Status',
            'Goal Summary',
            'Changed Files',
            'Validation Results',
            'Stop Reason',
            'Risks',
            'Continuation Handoff'
        )
        foreach ($section in $MdSections) {
            if ($MdContent -notmatch [regex]::Escape($section)) {
                Fail "case-06: goal-output.md missing required section: $section"
            }
        }
        Pass-Check "case-06: all required sections present (Markdown)"

        # ── K-alt. goal_status enum validation ──────────────────────
        $ValidStatuses = @('COMPLETED', 'PARTIALLY_COMPLETED', 'BLOCKED', 'FAILED', 'ABORTED')
        $StatusMatch = [regex]::Match($MdContent, '(?:Goal Status|goal_status)[:\s]+(\S+)')
        if (-not $StatusMatch.Success -or $StatusMatch.Groups[1].Value -notin $ValidStatuses) {
            $Found = if ($StatusMatch.Success) { $StatusMatch.Groups[1].Value } else { "not found" }
            Fail "case-06: goal_status '$Found' is not a valid value (must be one of: $($ValidStatuses -join ', '))"
        }
        Pass-Check "case-06: goal_status is valid: $($StatusMatch.Groups[1].Value) (Markdown)"

        # ── L-alt. Continuation handoff completeness ────────────────
        $HandoffLabels = @('Context', 'Boundary', 'Next candidate', 'Prompt seed')
        foreach ($label in $HandoffLabels) {
            if ($MdContent -notmatch [regex]::Escape($label)) {
                Fail "case-06: continuation_handoff missing field: $label"
            }
        }
        Pass-Check "case-06: continuation_handoff all 4 sub-fields present (Markdown)"

        # changed_files cross-check not available in markdown fallback
        Pass-Check "case-06: changed_files cross-check skipped (Markdown fallback)"
    }
}

# ── K. Final result ──────────────────────────────────────────────────

Write-Host ""
Write-Host "RESULT: PASS"
