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
        '07' { return 'case-07-dirty-workspace' }
        '08' { return 'case-08-noop-save' }
        '09' { return 'case-09-history-rewrite' }
        '10' { return 'case-10-compact-resume' }
        '11' { return 'case-11-phase-inference' }
        '12' { return 'case-12-protocol-commit' }
        '13' { return 'case-13-mixed-staged-files' }
        '14' { return 'case-14-phase-inference-precedence' }
        '15' { return 'case-15-scope-misuse' }
        '16' { return 'case-16-stale-focus-contamination' }
        '17' { return 'case-17-checkpoint-freshness' }
        '18' { return 'case-18-active-work-reconstruction' }
        '19' { return 'case-19-real-status-stale-focus' }
        '20' { return 'case-20-checkpoint-freshness-runtime' }
        '21' { return 'case-21-goal-completion-closes-workflow' }
        '22' { return 'case-22-dev-save-completion-semantics' }
        '23' { return 'case-23-no-op-validation-completion' }
        '24' { return 'case-24-phase-inference-extended' }
        '25' { return 'case-25-noop-save-extended' }
        '26' { return 'case-26-focus-migration' }
        '27' { return 'case-27-simple-scope-auto-execution' }
        '28' { return 'case-28-complex-scope-requires-goal' }
        '29' { return 'case-29-ambiguous-scope-clarification' }
        '30' { return 'case-30-continue-loop-normal' }
        '31' { return 'case-31-all-loops-completed' }
        '32' { return 'case-32-ambiguous-next-loop' }
        '33' { return 'case-33-large-loop-requires-goal' }
        '34' { return 'case-34-generate-plan-basic' }
        '35' { return 'case-35-generate-plan-defer-aware' }
        '36' { return 'case-36-generate-plan-continue-loop-constraints' }
        '37' { return 'case-37-semantic-validation-equivalence' }
        '38' { return 'case-38-semantic-loop-completion' }
        '39' { return 'case-39-semantic-drift-classification' }
        '40' { return 'case-40-semantic-active-work' }
        '41' { return 'case-41-canonical-workflow-path-consistency' }
        '42' { return 'case-42-test-matrix-synchronization-audit' }
        '43' { return 'case-43-onboarding-documentation-consistency' }
        '44' { return 'case-44-alias-skill-runtime-consistency' }
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

    $HeadParent = & git -C $Root rev-parse HEAD~1 2>$null
    if ($LASTEXITCODE -ne 0) {
        Fail "Cannot resolve HEAD~1 in project root ($ProjectRoot)"
    }

    # Normalize both to lowercase for comparison
    $LastCommit = $Match.Groups[1].Value.ToLowerInvariant()
    $HeadParent = $HeadParent.Trim().ToLowerInvariant()

    if ($LastCommit -ne $HeadParent) {
        # If full hash mismatch, check if short form matches (tolerate 7-char vs full hash)
        if ($HeadParent.StartsWith($LastCommit) -or $LastCommit.StartsWith($HeadParent.Substring(0, [Math]::Min($LastCommit.Length, 7)))) {
            Pass-Check "last_commit matches HEAD~1 (short/full): $HeadParent"
        } else {
            Fail "last_commit ($($Match.Groups[1].Value)) does not match HEAD~1 ($HeadParent)"
        }
    } else {
        Pass-Check "last_commit matches HEAD~1: $HeadParent"
    }

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
    elseif ($HeadCommit -match "^chore\(checkpoint\):") {
        Pass-Check "HEAD is a /dev-checkpoint generated commit"
    }
    elseif ($HeadCommit -match "chore:.*(/dev-checkpoint|checkpoint)") {
        Pass-Check "HEAD is a /dev-checkpoint generated commit (no-scope format)"
    }
    else {
        Fail "HEAD commit does not indicate a checkpoint baseline, state migration, or checkpoint sync"
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

# ── F. Case-24 specific checks (phase inference extended) ────────────

if ($Case -eq '24') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-24 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-24 test-plan.md exists"

    # Verify workflow-state.yml exists
    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-24: workflow-state.yml not found"
    }
    Pass-Check "case-24: workflow-state.yml exists"

    # Verify phase inference sources exist
    $Roadmap = Join-Path $PWD.Path "docs/v2-redesign-roadmap.md"
    $Handoff = Join-Path $StateRoot "handoff.md"
    if (-not (Test-Path $Roadmap) -and -not (Test-Path $Handoff)) {
        Fail "case-24: no phase inference source found (roadmap or handoff)"
    }
    Pass-Check "case-24: phase inference source exists"

    # Verify current-focus.md does NOT exist (prevention)
    $CurrentFocus = Join-Path $StateRoot "current-focus.md"
    if (Test-Path $CurrentFocus) {
        Fail "case-24: current-focus.md should not exist"
    }
    Pass-Check "case-24: current-focus.md absent (redundancy prevention)"
}

# ── G. Case-25 specific checks (no-op save extended) ─────────────────

if ($Case -eq '25') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-25 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-25 test-plan.md exists"

    # Workspace must be clean
    & git diff --quiet
    if ($LASTEXITCODE -ne 0) {
        Fail "case-25: workspace must be clean for no-op save test"
    }
    Pass-Check "case-25: workspace clean"

    & git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        Fail "case-25: staged changes detected"
    }
    Pass-Check "case-25: no staged changes"

    # Verify state files exist
    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-25: workflow-state.yml not found"
    }
    Pass-Check "case-25: workflow-state.yml exists"

    $Handoff = Join-Path $StateRoot "handoff.md"
    if (-not (Test-Path $Handoff)) {
        Fail "case-25: handoff.md not found"
    }
    Pass-Check "case-25: handoff.md exists"
}

# ── H. Case-26 specific checks (focus migration) ─────────────────────

if ($Case -eq '26') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-26 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-26 test-plan.md exists"

    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"

    # current-focus.md must NOT exist
    $CurrentFocus = Join-Path $StateRoot "current-focus.md"
    if (Test-Path $CurrentFocus) {
        Fail "case-26: current-focus.md should not exist"
    }
    Pass-Check "case-26: current-focus.md absent"

    # handoff.md must contain Current Focus section
    $Handoff = Join-Path $StateRoot "handoff.md"
    if (-not (Test-Path $Handoff)) {
        Fail "case-26: handoff.md not found"
    }
    $HandoffContent = Get-Content $Handoff -Raw
    if ($HandoffContent -notmatch "Current Focus") {
        Fail "case-26: handoff.md missing 'Current Focus' section"
    }
    Pass-Check "case-26: handoff.md contains Current Focus"

    # workflow-state.yml must contain focus field
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-26: workflow-state.yml not found"
    }
    $StateContent = Get-Content $WorkflowState -Raw
    if ($StateContent -notmatch "focus:") {
        Fail "case-26: workflow-state.yml missing focus field"
    }
    Pass-Check "case-26: workflow-state.yml contains focus field"

    # references/workflow-rules.md must contain preventive rule
    $WorkflowRules = Join-Path $PWD.Path "references/workflow-rules.md"
    if (-not (Test-Path $WorkflowRules)) {
        Fail "case-26: references/workflow-rules.md not found"
    }
    $RulesContent = Get-Content $WorkflowRules -Raw
    if ($RulesContent -notmatch "current-focus.md") {
        Fail "case-26: references/workflow-rules.md missing current-focus.md prevention rule"
    }
    Pass-Check "case-26: workflow-rules.md documents current-focus.md prevention"
}

# ── I. Case-07 specific checks (dirty workspace) ─────────────────────

if ($Case -eq '07') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-07 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-07 test-plan.md exists"

    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"

    # State files must exist
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-07: workflow-state.yml not found"
    }
    Pass-Check "case-07: workflow-state.yml exists"

    # Verify /dev-save does not stage source files
    # (This is a protocol contract check, not a runtime execution)
    $DevSavePrompt = Join-Path $PWD.Path "skills/dev-save/PROMPT.md"
    if (-not (Test-Path $DevSavePrompt)) {
        Fail "case-07: skills/dev-save/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevSavePrompt -Raw
    if ($PromptContent -notmatch "NEVER stage (or commit )?non-protocol files") {
        Fail "case-07: /dev-save prompt missing non-protocol file exclusion constraint"
    }
    Pass-Check "case-07: /dev-save prompt enforces non-protocol file exclusion"
}

# ── J. Case-08 specific checks (no-op save) ──────────────────────────

if ($Case -eq '08') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-08 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-08 test-plan.md exists"

    # Workspace must be clean
    & git diff --quiet
    if ($LASTEXITCODE -ne 0) {
        Fail "case-08: workspace must be clean for no-op save test"
    }
    Pass-Check "case-08: workspace clean"

    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-08: workflow-state.yml not found"
    }
    Pass-Check "case-08: workflow-state.yml exists"

    # Verify no-op support in /dev-save prompt
    $DevSavePrompt = Join-Path $PWD.Path "skills/dev-save/PROMPT.md"
    $PromptContent = Get-Content $DevSavePrompt -Raw
    if ($PromptContent -notmatch "no-op") {
        Fail "case-08: /dev-save prompt missing no-op save support"
    }
    Pass-Check "case-08: /dev-save prompt supports no-op saves"
}

# ── K. Case-09 specific checks (history rewrite) ─────────────────────

if ($Case -eq '09') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-09 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-09 test-plan.md exists"

    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-09: workflow-state.yml not found"
    }
    Pass-Check "case-09: workflow-state.yml exists"

    # Verify checkpoint.last_commit is a valid hash
    $Content = Get-Content $WorkflowState -Raw
    $Match = [regex]::Match($Content, 'last_commit:\s*"([a-f0-9]{7,40})"')
    if (-not $Match.Success) {
        Fail "case-09: last_commit does not match valid hash pattern"
    }
    Pass-Check "case-09: last_commit is valid hash"

    # Verify /dev-status handles invalid baseline
    $DevStatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"
    $PromptContent = Get-Content $DevStatusPrompt -Raw
    if ($PromptContent -notmatch "checkpoint.last_commit") {
        Fail "case-09: /dev-status prompt missing checkpoint baseline handling"
    }
    Pass-Check "case-09: /dev-status prompt handles checkpoint baseline"
}

# ── L. Case-10 specific checks (compact resume) ──────────────────────

if ($Case -eq '10') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-10 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-10 test-plan.md exists"

    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"

    # handoff.md must contain all required sections for recovery
    $Handoff = Join-Path $StateRoot "handoff.md"
    if (-not (Test-Path $Handoff)) {
        Fail "case-10: handoff.md not found"
    }
    $HandoffContent = Get-Content $Handoff -Raw
    $RequiredSections = @("Current Focus", "Current Status", "Next Recommended Actions", "Notes For Next Session")
    foreach ($section in $RequiredSections) {
        if ($HandoffContent -notmatch [regex]::Escape($section)) {
            Fail "case-10: handoff.md missing required section: $section"
        }
    }
    Pass-Check "case-10: handoff.md contains all recovery sections"

    # workflow-state.yml must contain recoverable fields
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-10: workflow-state.yml not found"
    }
    $StateContent = Get-Content $WorkflowState -Raw
    $RequiredFields = @("phase:", "focus:", "status:")
    foreach ($field in $RequiredFields) {
        if ($StateContent -notmatch $field) {
            Fail "case-10: workflow-state.yml missing required field: $field"
        }
    }
    Pass-Check "case-10: workflow-state.yml contains recoverable fields"
}

# ── M. Case-11 specific checks (phase inference) ─────────────────────

if ($Case -eq '11') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-11 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-11 test-plan.md exists"

    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"

    # Verify phase inference exists in /dev-status prompt
    $DevStatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"
    if (-not (Test-Path $DevStatusPrompt)) {
        Fail "case-11: skills/dev-status/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevStatusPrompt -Raw
    if ($PromptContent -notmatch "Phase Inference") {
        Fail "case-11: /dev-status prompt missing Phase Inference section"
    }
    Pass-Check "case-11: /dev-status prompt contains phase inference"

    # Verify inference sources documented
    $InferenceSources = @("next-phase-plan", "roadmap", "handoff", "workflow-state")
    foreach ($source in $InferenceSources) {
        if ($PromptContent -notmatch $source) {
            Fail "case-11: /dev-status prompt missing inference source: $source"
        }
    }
    Pass-Check "case-11: /dev-status prompt defines all inference sources"
}

# ── N. Case-12 specific checks (protocol commit classification) ──────

if ($Case -eq '12') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-12 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-12 test-plan.md exists"

    # Verify /dev-status prompt contains protocol commit detection rules
    $DevStatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"
    if (-not (Test-Path $DevStatusPrompt)) {
        Fail "case-12: skills/dev-status/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevStatusPrompt -Raw

    $RequiredPatterns = @(
        "chore\(checkpoint\)",
        "chore\(protocol\)",
        "chore\(state\)",
        "protocol commit"
    )
    foreach ($pattern in $RequiredPatterns) {
        if ($PromptContent -notmatch $pattern) {
            Fail "case-12: /dev-status prompt missing protocol commit pattern: $pattern"
        }
    }
    Pass-Check "case-12: /dev-status prompt defines all protocol commit patterns"

    # Verify drift classification exists
    if ($PromptContent -notmatch "drift = none") {
        Fail "case-12: /dev-status prompt missing 'drift = none' classification"
    }
    Pass-Check "case-12: /dev-status prompt defines drift = none for protocol commits"

    if ($PromptContent -notmatch "drift = high") {
        Fail "case-12: /dev-status prompt missing 'drift = high' classification"
    }
    Pass-Check "case-12: /dev-status prompt defines drift = high for source commits"
}

# ── O. Case-13 specific checks (mixed staged files) ──────────────────

if ($Case -eq '13') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-13 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-13 test-plan.md exists"

    # Verify /dev-save prompt contains mixed staged files rejection
    $DevSavePrompt = Join-Path $PWD.Path "skills/dev-save/PROMPT.md"
    if (-not (Test-Path $DevSavePrompt)) {
        Fail "case-13: skills/dev-save/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevSavePrompt -Raw

    if ($PromptContent -notmatch "mixed commit") {
        Fail "case-13: /dev-save prompt missing mixed commit detection"
    }
    Pass-Check "case-13: /dev-save prompt detects mixed commits"

    if ($PromptContent -notmatch "NEVER proceed if both protocol files AND source files are staged") {
        Fail "case-13: /dev-save prompt missing staged mixed files rejection"
    }
    Pass-Check "case-13: /dev-save prompt rejects mixed staged files"

    if ($PromptContent -notmatch "FAILURE CONDITIONS") {
        Fail "case-13: /dev-save prompt missing FAILURE CONDITIONS block"
    }
    Pass-Check "case-13: /dev-save prompt defines FAILURE CONDITIONS"
}

# ── P. Case-14 specific checks (phase inference precedence) ──────────

if ($Case -eq '14') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-14 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-14 test-plan.md exists"

    $DevStatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"
    if (-not (Test-Path $DevStatusPrompt)) {
        Fail "case-14: skills/dev-status/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevStatusPrompt -Raw

    if ($PromptContent -notmatch "Phase Inference") {
        Fail "case-14: /dev-status prompt missing Phase Inference section"
    }
    Pass-Check "case-14: /dev-status prompt contains phase inference"

    # Verify precedence order: git reality > workflow-state > current-focus > roadmap > fallback
    # Use numbered list items to avoid false matches from prose or table headers
    $GitPos = $PromptContent.IndexOf("1. git reality")
    $WsPos = $PromptContent.IndexOf("2. workflow-state.yml")
    $FocusPos = $PromptContent.IndexOf("3. current-focus")
    $RoadmapPos = $PromptContent.IndexOf("4. roadmap")
    $FallbackPos = $PromptContent.IndexOf("5. fallback")

    if ($GitPos -eq -1 -or $WsPos -eq -1 -or $FocusPos -eq -1 -or $RoadmapPos -eq -1 -or $FallbackPos -eq -1) {
        Fail "case-14: /dev-status prompt missing one or more precedence sources"
    }

    if (-not ($GitPos -lt $WsPos -and $WsPos -lt $FocusPos -and $FocusPos -lt $RoadmapPos -and $RoadmapPos -lt $FallbackPos)) {
        Fail "case-14: phase inference precedence order incorrect (expected: git reality > workflow-state > current-focus > roadmap > fallback)"
    }
    Pass-Check "case-14: /dev-status prompt defines correct phase inference precedence"

    if ($PromptContent -notmatch "DO NOT") {
        Fail "case-14: /dev-status prompt missing DO NOT block"
    }
    Pass-Check "case-14: /dev-status prompt defines DO NOT constraints"
}

# ── Q. Case-15 specific checks (scope misuse detection) ──────────────

if ($Case -eq '15') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-15 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-15 test-plan.md exists"

    $DevScopePrompt = Join-Path $PWD.Path "skills/dev-scope/PROMPT.md"
    if (-not (Test-Path $DevScopePrompt)) {
        Fail "case-15: skills/dev-scope/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevScopePrompt -Raw

    if ($PromptContent -notmatch "DO NOT") {
        Fail "case-15: /dev-scope prompt missing DO NOT block"
    }
    Pass-Check "case-15: /dev-scope prompt defines DO NOT constraints"

    if ($PromptContent -notmatch "PRECONDITIONS") {
        Fail "case-15: /dev-scope prompt missing PRECONDITIONS block"
    }
    Pass-Check "case-15: /dev-scope prompt defines PRECONDITIONS"

    if ($PromptContent -notmatch "FAILURE CONDITIONS") {
        Fail "case-15: /dev-scope prompt missing FAILURE CONDITIONS block"
    }
    Pass-Check "case-15: /dev-scope prompt defines FAILURE CONDITIONS"

    if ($PromptContent -notmatch "NEVER auto-execute when scope is ambiguous") {
        Fail "case-15: /dev-scope prompt missing scope misuse detection (NEVER auto-execute for ambiguous/architectural scopes)"
    }
    Pass-Check "case-15: /dev-scope prompt detects scope misuse (prevents auto-execution of complex work)"
}

# ── R. Case-16 specific checks (stale focus contamination) ───────────

if ($Case -eq '16') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-16 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-16 test-plan.md exists"

    $DevStatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"
    if (-not (Test-Path $DevStatusPrompt)) {
        Fail "case-16: skills/dev-status/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevStatusPrompt -Raw

    if ($PromptContent -notmatch "Focus Inference") {
        Fail "case-16: /dev-status prompt missing Focus Inference section"
    }
    Pass-Check "case-16: /dev-status prompt contains Focus Inference"

    if ($PromptContent -notmatch "Downgrade rule") {
        Fail "case-16: /dev-status prompt missing downgrade rule for stale checkpoints"
    }
    Pass-Check "case-16: /dev-status prompt defines downgrade rule"

    if ($PromptContent -notmatch "NEVER return stale focus") {
        Fail "case-16: /dev-status prompt missing stale focus prevention"
    }
    Pass-Check "case-16: /dev-status prompt prevents stale focus return"
}

# ── S. Case-17 specific checks (checkpoint freshness) ────────────────

if ($Case -eq '17') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-17 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-17 test-plan.md exists"

    $DevStatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"
    if (-not (Test-Path $DevStatusPrompt)) {
        Fail "case-17: skills/dev-status/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevStatusPrompt -Raw

    if ($PromptContent -notmatch "Checkpoint Freshness Model") {
        Fail "case-17: /dev-status prompt missing Checkpoint Freshness Model"
    }
    Pass-Check "case-17: /dev-status prompt defines Checkpoint Freshness Model"

    if ($PromptContent -notmatch "fresh" -or $PromptContent -notmatch "stale" -or $PromptContent -notmatch "outdated") {
        Fail "case-17: /dev-status prompt missing one or more freshness levels"
    }
    Pass-Check "case-17: /dev-status prompt defines all freshness levels"

    # Verify threshold table exists
    $FreshPos = $PromptContent.IndexOf("fresh")
    $StalePos = $PromptContent.IndexOf("stale")
    $OutdatedPos = $PromptContent.IndexOf("outdated")
    if ($FreshPos -eq -1 -or $StalePos -eq -1 -or $OutdatedPos -eq -1) {
        Fail "case-17: freshness level keywords not found"
    }
    Pass-Check "case-17: freshness thresholds present"
}

# ── T. Case-18 specific checks (active work reconstruction) ──────────

if ($Case -eq '18') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-18 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-18 test-plan.md exists"

    $DevStatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"
    if (-not (Test-Path $DevStatusPrompt)) {
        Fail "case-18: skills/dev-status/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevStatusPrompt -Raw

    if ($PromptContent -notmatch "Active Work Reconstruction") {
        Fail "case-18: /dev-status prompt missing Active Work Reconstruction section"
    }
    Pass-Check "case-18: /dev-status prompt contains Active Work Reconstruction"

    if ($PromptContent -notmatch "Aggregation rule") {
        Fail "case-18: /dev-status prompt missing aggregation rule"
    }
    Pass-Check "case-18: /dev-status prompt defines aggregation rule"

    if ($PromptContent -notmatch "recent commits") {
        Fail "case-18: /dev-status prompt missing recent commits reference"
    }
    Pass-Check "case-18: /dev-status prompt references recent commits"
}

# ── U. Case-19 specific checks (real status stale focus validation) ──

if ($Case -eq '19') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-19 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-19 test-plan.md exists"

    $SkillFile = Join-Path $PWD.Path "skills/dev-status/SKILL.md"
    $PromptFile = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"

    if (-not (Test-Path $SkillFile)) {
        Fail "case-19: skills/dev-status/SKILL.md not found"
    }
    $SkillContent = Get-Content $SkillFile -Raw

    if ($SkillContent -notmatch "Focus Inference") {
        Fail "case-19: SKILL.md missing Focus Inference section"
    }
    Pass-Check "case-19: SKILL.md contains Focus Inference"

    if ($SkillContent -notmatch "downgrade" -and $SkillContent -notmatch "low confidence") {
        Fail "case-19: SKILL.md missing downgrade rule for stale checkpoints"
    }
    Pass-Check "case-19: SKILL.md defines downgrade rule"

    if ($SkillContent -notmatch "NEVER return stale focus") {
        Fail "case-19: SKILL.md missing stale focus prevention"
    }
    Pass-Check "case-19: SKILL.md prevents stale focus return"

    # Cross-check with PROMPT.md
    $PromptContent = Get-Content $PromptFile -Raw
    if ($PromptContent -notmatch "Focus Inference") {
        Fail "case-19: PROMPT.md missing Focus Inference (divergence from SKILL.md)"
    }
    Pass-Check "case-19: PROMPT.md also contains Focus Inference (synchronized)"
}

# ── V. Case-20 specific checks (checkpoint freshness runtime) ─────────

if ($Case -eq '20') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-20 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-20 test-plan.md exists"

    $SkillFile = Join-Path $PWD.Path "skills/dev-status/SKILL.md"
    $PromptFile = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"

    if (-not (Test-Path $SkillFile)) {
        Fail "case-20: skills/dev-status/SKILL.md not found"
    }
    $SkillContent = Get-Content $SkillFile -Raw

    if ($SkillContent -notmatch "Checkpoint Freshness") {
        Fail "case-20: SKILL.md missing Checkpoint Freshness Model"
    }
    Pass-Check "case-20: SKILL.md contains Checkpoint Freshness"

    if ($SkillContent -notmatch "fresh" -or $SkillContent -notmatch "stale" -or $SkillContent -notmatch "outdated") {
        Fail "case-20: SKILL.md missing one or more freshness levels"
    }
    Pass-Check "case-20: SKILL.md defines all freshness levels"

    # Cross-check with PROMPT.md
    $PromptContent = Get-Content $PromptFile -Raw
    if ($PromptContent -notmatch "Checkpoint Freshness") {
        Fail "case-20: PROMPT.md missing Checkpoint Freshness (divergence from SKILL.md)"
    }
    Pass-Check "case-20: PROMPT.md also contains Checkpoint Freshness (synchronized)"
}

# ── W. Case-21 specific checks (goal completion closes workflow) ─────

if ($Case -eq '21') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-21 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-21 test-plan.md exists"

    $PromptFile = Join-Path $PWD.Path "skills/dev-scope/PROMPT.md"
    $SkillFile = Join-Path $PWD.Path "skills/dev-scope/SKILL.md"

    if (-not (Test-Path $PromptFile)) {
        Fail "case-21: skills/dev-scope/PROMPT.md not found"
    }
    $PromptContent = Get-Content $PromptFile -Raw

    if ($PromptContent -notmatch "Workflow Status") {
        Fail "case-21: /dev-scope prompt missing Workflow Status block"
    }
    Pass-Check "case-21: /dev-scope prompt contains Workflow Status"

    if ($PromptContent -notmatch "No remaining protocol tasks") {
        Fail "case-21: /dev-scope prompt missing 'No remaining protocol tasks'"
    }
    Pass-Check "case-21: /dev-scope prompt declares no remaining tasks"

    $SkillContent = Get-Content $SkillFile -Raw
    if ($SkillContent -notmatch "Scope declaration complete" -and $SkillContent -notmatch "Workflow completed") {
        Fail "case-21: /dev-scope SKILL.md missing completion declaration"
    }
    Pass-Check "case-21: /dev-scope SKILL.md defines completion reporting"
}

# ── X. Case-22 specific checks (dev-save completion semantics) ───────

if ($Case -eq '22') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-22 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-22 test-plan.md exists"

    $PromptFile = Join-Path $PWD.Path "skills/dev-save/PROMPT.md"
    $SkillFile = Join-Path $PWD.Path "skills/dev-save/SKILL.md"

    if (-not (Test-Path $PromptFile)) {
        Fail "case-22: skills/dev-save/PROMPT.md not found"
    }
    $PromptContent = Get-Content $PromptFile -Raw

    if ($PromptContent -notmatch "Workflow completed") {
        Fail "case-22: /dev-save prompt missing 'Workflow completed'"
    }
    Pass-Check "case-22: /dev-save prompt declares workflow completion"

    if ($PromptContent -notmatch "No remaining protocol tasks") {
        Fail "case-22: /dev-save prompt missing 'No remaining protocol tasks'"
    }
    Pass-Check "case-22: /dev-save prompt declares no remaining tasks"

    $SkillContent = Get-Content $SkillFile -Raw
    if ($SkillContent -notmatch "Workflow completed") {
        Fail "case-22: /dev-save SKILL.md missing completion declaration"
    }
    Pass-Check "case-22: /dev-save SKILL.md defines completion reporting"
}

# ── Y. Case-23 specific checks (no-op validation completion) ─────────

if ($Case -eq '23') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-23 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-23 test-plan.md exists"

    $SavePrompt = Join-Path $PWD.Path "skills/dev-save/PROMPT.md"
    $StatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"

    if (-not (Test-Path $SavePrompt)) {
        Fail "case-23: skills/dev-save/PROMPT.md not found"
    }
    $SaveContent = Get-Content $SavePrompt -Raw

    if ($SaveContent -notmatch "Workflow completed \(no-op\)") {
        Fail "case-23: /dev-save prompt missing no-op completion declaration"
    }
    Pass-Check "case-23: /dev-save prompt defines no-op completion"

    if (-not (Test-Path $StatusPrompt)) {
        Fail "case-23: skills/dev-status/PROMPT.md not found"
    }
    $StatusContent = Get-Content $StatusPrompt -Raw

    if ($StatusContent -notmatch "Protocol Task Status") {
        Fail "case-23: /dev-status prompt missing Protocol Task Status section"
    }
    Pass-Check "case-23: /dev-status prompt contains Protocol Task Status"
}

# ── Z. Case-27 specific checks (simple scope auto-execution) ─────────

if ($Case -eq '27') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-27 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-27 test-plan.md exists"

    $ScopePrompt = Join-Path $PWD.Path "skills/dev-scope/PROMPT.md"
    $ScopeSkill = Join-Path $PWD.Path "skills/dev-scope/SKILL.md"

    if (-not (Test-Path $ScopePrompt)) {
        Fail "case-27: skills/dev-scope/PROMPT.md not found"
    }
    $PromptContent = Get-Content $ScopePrompt -Raw

    # Verify auto-execution criteria exist
    if ($PromptContent -notmatch "Auto-execution criteria") {
        Fail "case-27: /dev-scope prompt missing auto-execution criteria"
    }
    Pass-Check "case-27: /dev-scope prompt defines auto-execution criteria"

    # Verify 7 criteria are present
    $CriteriaPatterns = @(
        "File count",
        "public API",
        "cross-module",
        "Single-step validation",
        "ambiguous",
        "Non-architectural",
        "blast radius"
    )
    foreach ($pattern in $CriteriaPatterns) {
        if ($PromptContent -notmatch $pattern) {
            Fail "case-27: /dev-scope prompt missing auto-execution criterion: $pattern"
        }
    }
    Pass-Check "case-27: /dev-scope prompt defines all 7 auto-execution criteria"

    # Verify simple scope examples
    if ($PromptContent -notmatch "fix typo") {
        Fail "case-27: /dev-scope prompt missing simple scope example"
    }
    Pass-Check "case-27: /dev-scope prompt includes auto-execution examples"

    # Verify auto-execution path produces completion
    if ($PromptContent -notmatch "auto-executes") {
        Fail "case-27: /dev-scope prompt missing auto-execution path"
    }
    Pass-Check "case-27: /dev-scope prompt defines auto-execution path"

    # Verify SKILL.md synchronization
    if (-not (Test-Path $ScopeSkill)) {
        Fail "case-27: skills/dev-scope/SKILL.md not found"
    }
    $SkillContent = Get-Content $ScopeSkill -Raw

    if ($SkillContent -notmatch "auto-execution" -and $SkillContent -notmatch "Auto-execution") {
        Fail "case-27: /dev-scope SKILL.md missing auto-execution logic"
    }
    Pass-Check "case-27: /dev-scope SKILL.md defines auto-execution"
}

# ── AA. Case-28 specific checks (complex scope requires /goal) ───────

if ($Case -eq '28') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-28 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-28 test-plan.md exists"

    $ScopePrompt = Join-Path $PWD.Path "skills/dev-scope/PROMPT.md"
    $ScopeSkill = Join-Path $PWD.Path "skills/dev-scope/SKILL.md"

    if (-not (Test-Path $ScopePrompt)) {
        Fail "case-28: skills/dev-scope/PROMPT.md not found"
    }
    $PromptContent = Get-Content $ScopePrompt -Raw

    # Verify blocked scope examples
    $BlockedExamples = @("architecture redesign", "refactor", "OAuth", "cross-cutting")
    $HasBlocked = $false
    foreach ($example in $BlockedExamples) {
        if ($PromptContent -match $example) {
            $HasBlocked = $true
            break
        }
    }
    if (-not $HasBlocked) {
        Fail "case-28: /dev-scope prompt missing blocked scope examples"
    }
    Pass-Check "case-28: /dev-scope prompt defines blocked scope examples"

    # Verify STOP behavior for non-auto-executable scopes
    if ($PromptContent -notmatch "Separate /goal required") {
        Fail "case-28: /dev-scope prompt missing '/goal required' signal for complex scopes"
    }
    Pass-Check "case-28: /dev-scope prompt requires /goal for complex scopes"

    # Verify DO NOT prevents auto-execution of complex work
    if ($PromptContent -notmatch "NEVER auto-execute when scope is ambiguous") {
        Fail "case-28: /dev-scope prompt missing auto-execution prevention for ambiguous scopes"
    }
    Pass-Check "case-28: /dev-scope prompt prevents auto-execution of ambiguous scopes"

    if ($PromptContent -notmatch "architectural") {
        Fail "case-28: /dev-scope prompt missing architectural scope prevention"
    }
    Pass-Check "case-28: /dev-scope prompt prevents auto-execution of architectural scopes"

    # Verify SKILL.md synchronization
    if (-not (Test-Path $ScopeSkill)) {
        Fail "case-28: skills/dev-scope/SKILL.md not found"
    }
    $SkillContent = Get-Content $ScopeSkill -Raw

    if ($SkillContent -notmatch "NEVER auto-execute") {
        Fail "case-28: /dev-scope SKILL.md missing auto-execution prevention"
    }
    Pass-Check "case-28: /dev-scope SKILL.md prevents auto-execution of complex scopes"
}

# ── AB. Case-29 specific checks (ambiguous scope clarification) ──────

if ($Case -eq '29') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-29 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-29 test-plan.md exists"

    $ScopePrompt = Join-Path $PWD.Path "skills/dev-scope/PROMPT.md"
    $ScopeSkill = Join-Path $PWD.Path "skills/dev-scope/SKILL.md"

    if (-not (Test-Path $ScopePrompt)) {
        Fail "case-29: skills/dev-scope/PROMPT.md not found"
    }
    $PromptContent = Get-Content $ScopePrompt -Raw

    # Verify ambiguity detection exists
    if ($PromptContent -notmatch "Detect Ambiguity") {
        Fail "case-29: /dev-scope prompt missing ambiguity detection section"
    }
    Pass-Check "case-29: /dev-scope prompt defines ambiguity detection"

    # Verify ambiguity precedes auto-execution
    $AmbiguityPos = $PromptContent.IndexOf("Detect Ambiguity")
    $AutoExecPos = $PromptContent.IndexOf("Auto-Execution")
    if ($AmbiguityPos -eq -1 -or $AutoExecPos -eq -1) {
        Fail "case-29: /dev-scope prompt missing ambiguity or auto-execution section"
    }
    if (-not ($AmbiguityPos -lt $AutoExecPos)) {
        Fail "case-29: ambiguity detection must precede auto-execution evaluation"
    }
    Pass-Check "case-29: ambiguity detection precedes auto-execution"

    # Verify "No ambiguous language" is an auto-execution criterion
    if ($PromptContent -notmatch "No ambiguous language") {
        Fail "case-29: /dev-scope prompt missing 'No ambiguous language' criterion"
    }
    Pass-Check "case-29: 'No ambiguous language' is an auto-execution criterion"

    # Verify clarifying questions behavior
    if ($PromptContent -notmatch "clarifying questions") {
        Fail "case-29: /dev-scope prompt missing clarifying questions for ambiguous scopes"
    }
    Pass-Check "case-29: /dev-scope prompt asks clarifying questions for ambiguous scopes"

    # Verify SKILL.md has ambiguity detection
    if (-not (Test-Path $ScopeSkill)) {
        Fail "case-29: skills/dev-scope/SKILL.md not found"
    }
    $SkillContent = Get-Content $ScopeSkill -Raw

    if ($SkillContent -notmatch "Detect Ambiguity") {
        Fail "case-29: /dev-scope SKILL.md missing ambiguity detection"
    }
    Pass-Check "case-29: /dev-scope SKILL.md defines ambiguity detection"
}

# ── AC. Case-30 specific checks (continue loop normal) ───────────────

if ($Case -eq '30') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-30 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-30 test-plan.md exists"

    $ContinuePrompt = Join-Path $PWD.Path "skills/continue-loop/PROMPT.md"
    $ContinueSkill = Join-Path $PWD.Path "skills/continue-loop/SKILL.md"

    if (-not (Test-Path $ContinuePrompt)) {
        Fail "case-30: skills/continue-loop/PROMPT.md not found"
    }
    Pass-Check "case-30: skills/continue-loop/PROMPT.md exists"

    if (-not (Test-Path $ContinueSkill)) {
        Fail "case-30: skills/continue-loop/SKILL.md not found"
    }
    Pass-Check "case-30: skills/continue-loop/SKILL.md exists"

    $PromptContent = Get-Content $ContinuePrompt -Raw

    # Verify preconditions exist
    if ($PromptContent -notmatch "Preconditions") {
        Fail "case-30: continue-loop prompt missing preconditions"
    }
    Pass-Check "case-30: continue-loop prompt defines preconditions"

    # Verify tolerant parsing
    if ($PromptContent -notmatch "tolerant") {
        Fail "case-30: continue-loop prompt missing tolerant parsing"
    }
    Pass-Check "case-30: continue-loop prompt defines tolerant parsing"

    # Verify scope derivation
    if ($PromptContent -notmatch "derive scope" -and $PromptContent -notmatch "Derive Scope") {
        Fail "case-30: continue-loop prompt missing scope derivation"
    }
    Pass-Check "case-30: continue-loop prompt defines scope derivation"

    # Verify auto-execution decision
    if ($PromptContent -notmatch "Auto-Execution") {
        Fail "case-30: continue-loop prompt missing auto-execution decision"
    }
    Pass-Check "case-30: continue-loop prompt defines auto-execution decision"

    # Verify execution sequence in SKILL.md
    $SkillContent = Get-Content $ContinueSkill -Raw
    if ($SkillContent -notmatch "Execution Sequence") {
        Fail "case-30: continue-loop SKILL.md missing execution sequence"
    }
    Pass-Check "case-30: continue-loop SKILL.md defines execution sequence"
}

# ── AD. Case-31 specific checks (all loops completed) ────────────────

if ($Case -eq '31') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-31 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-31 test-plan.md exists"

    $ContinuePrompt = Join-Path $PWD.Path "skills/continue-loop/PROMPT.md"
    $ContinueSkill = Join-Path $PWD.Path "skills/continue-loop/SKILL.md"

    if (-not (Test-Path $ContinuePrompt)) {
        Fail "case-31: skills/continue-loop/PROMPT.md not found"
    }
    $PromptContent = Get-Content $ContinuePrompt -Raw

    # Verify all-completed stop condition
    if ($PromptContent -notmatch "All planned loops completed") {
        Fail "case-31: continue-loop prompt missing all-completed message"
    }
    Pass-Check "case-31: continue-loop prompt defines all-completed stop"

    # Verify no-scope behavior when all done
    if ($PromptContent -notmatch "no incomplete loop") {
        Fail "case-31: continue-loop prompt missing no-incomplete-loop handling"
    }
    Pass-Check "case-31: continue-loop prompt handles no incomplete loops"

    # Verify SKILL.md has failure mode for all completed
    $SkillContent = Get-Content $ContinueSkill -Raw
    if ($SkillContent -notmatch "All complete") {
        Fail "case-31: continue-loop SKILL.md missing all-complete failure mode"
    }
    Pass-Check "case-31: continue-loop SKILL.md defines all-complete failure mode"
}

# ── AE. Case-32 specific checks (ambiguous next loop) ────────────────

if ($Case -eq '32') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-32 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-32 test-plan.md exists"

    $ContinuePrompt = Join-Path $PWD.Path "skills/continue-loop/PROMPT.md"
    $ContinueSkill = Join-Path $PWD.Path "skills/continue-loop/SKILL.md"

    if (-not (Test-Path $ContinuePrompt)) {
        Fail "case-32: skills/continue-loop/PROMPT.md not found"
    }
    $PromptContent = Get-Content $ContinuePrompt -Raw

    # Verify ambiguity detection precedes scope derivation
    $AmbiguityPos = $PromptContent.IndexOf("Evaluate Loop Clarity")
    $ScopePos = $PromptContent.IndexOf("Derive Scope")
    if ($AmbiguityPos -eq -1 -or $ScopePos -eq -1) {
        Fail "case-32: continue-loop prompt missing ambiguity or scope derivation section"
    }
    if (-not ($AmbiguityPos -lt $ScopePos)) {
        Fail "case-32: ambiguity detection must precede scope derivation"
    }
    Pass-Check "case-32: ambiguity detection precedes scope derivation"

    # Verify ambiguity signals
    if ($PromptContent -notmatch "vague") {
        Fail "case-32: continue-loop prompt missing vague description signal"
    }
    Pass-Check "case-32: continue-loop prompt defines ambiguity signals"

    # Verify STOP on ambiguity
    if ($PromptContent -notmatch "Next loop is ambiguous") {
        Fail "case-32: continue-loop prompt missing ambiguous loop STOP message"
    }
    Pass-Check "case-32: continue-loop prompt STOPs on ambiguous loop"

    # Verify SKILL.md has ambiguity handling
    $SkillContent = Get-Content $ContinueSkill -Raw
    if ($SkillContent -notmatch "Ambiguity") {
        Fail "case-32: continue-loop SKILL.md missing ambiguity handling"
    }
    Pass-Check "case-32: continue-loop SKILL.md defines ambiguity handling"
}

# ── AF. Case-33 specific checks (large loop requires /goal) ──────────

if ($Case -eq '33') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-33 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-33 test-plan.md exists"

    $ContinuePrompt = Join-Path $PWD.Path "skills/continue-loop/PROMPT.md"
    $ContinueSkill = Join-Path $PWD.Path "skills/continue-loop/SKILL.md"

    if (-not (Test-Path $ContinuePrompt)) {
        Fail "case-33: skills/continue-loop/PROMPT.md not found"
    }
    $PromptContent = Get-Content $ContinuePrompt -Raw

    # Verify auto-execution criteria applied
    if ($PromptContent -notmatch "Auto-Execution Eligibility") {
        Fail "case-33: continue-loop prompt missing auto-execution evaluation"
    }
    Pass-Check "case-33: continue-loop prompt evaluates auto-execution eligibility"

    # Verify scope document path when criteria fail
    if ($PromptContent -notmatch "Scope document required") {
        Fail "case-33: continue-loop prompt missing scope document path"
    }
    Pass-Check "case-33: continue-loop prompt defines scope document path"

    # Verify /goal required message
    if ($PromptContent -notmatch "Separate /goal required") {
        Fail "case-33: continue-loop prompt missing /goal required signal"
    }
    Pass-Check "case-33: continue-loop prompt requires /goal for complex loops"

    # Verify no source modification when criteria fail
    if ($PromptContent -notmatch "NEVER modify source code if auto-execution criteria are NOT met") {
        Fail "case-33: continue-loop prompt missing source modification prevention"
    }
    Pass-Check "case-33: continue-loop prompt prevents source modification for complex loops"

    # Verify SKILL.md has scope document path
    $SkillContent = Get-Content $ContinueSkill -Raw
    if ($SkillContent -notmatch "scope document" -and $SkillContent -notmatch "Scope document") {
        Fail "case-33: continue-loop SKILL.md missing scope document path"
    }
    Pass-Check "case-33: continue-loop SKILL.md defines scope document path"
}

# ── AG. Case-34 specific checks (generate-plan basic workflow) ───────

if ($Case -eq '34') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-34 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-34 test-plan.md exists"

    $GenPrompt = Join-Path $PWD.Path "skills/generate-plan/PROMPT.md"
    $GenSkill = Join-Path $PWD.Path "skills/generate-plan/SKILL.md"
    $GenSymlink = Join-Path $PWD.Path ".claude/skills/generate-plan"

    if (-not (Test-Path $GenPrompt)) {
        Fail "case-34: skills/generate-plan/PROMPT.md not found"
    }
    Pass-Check "case-34: skills/generate-plan/PROMPT.md exists"

    if (-not (Test-Path $GenSkill)) {
        Fail "case-34: skills/generate-plan/SKILL.md not found"
    }
    Pass-Check "case-34: skills/generate-plan/SKILL.md exists"

    if (-not (Test-Path $GenSymlink)) {
        Fail "case-34: .claude/skills/generate-plan symlink not found"
    }
    Pass-Check "case-34: .claude/skills/generate-plan symlink exists"

    $SkillContent = Get-Content $GenSkill -Raw

    # Verify required sections
    if ($SkillContent -notmatch "Purpose") {
        Fail "case-34: generate-plan SKILL.md missing Purpose"
    }
    Pass-Check "case-34: generate-plan SKILL.md defines Purpose"

    if ($SkillContent -notmatch "When to Use") {
        Fail "case-34: generate-plan SKILL.md missing When to Use"
    }
    Pass-Check "case-34: generate-plan SKILL.md defines When to Use"

    if ($SkillContent -notmatch "When NOT to Use") {
        Fail "case-34: generate-plan SKILL.md missing When NOT to Use"
    }
    Pass-Check "case-34: generate-plan SKILL.md defines When NOT to Use"

    if ($SkillContent -notmatch "Execution Sequence") {
        Fail "case-34: generate-plan SKILL.md missing Execution Sequence"
    }
    Pass-Check "case-34: generate-plan SKILL.md defines Execution Sequence"

    $PromptContent = Get-Content $GenPrompt -Raw

    # Verify STEP 1 (Read Context)
    if ($PromptContent -notmatch "STEP 1") {
        Fail "case-34: generate-plan PROMPT.md missing STEP 1"
    }
    Pass-Check "case-34: generate-plan PROMPT.md defines STEP 1"

    # Verify STEP 3 (Decompose Goal)
    if ($PromptContent -notmatch "STEP 3") {
        Fail "case-34: generate-plan PROMPT.md missing STEP 3"
    }
    Pass-Check "case-34: generate-plan PROMPT.md defines STEP 3"

    # Verify STEP 4 (Write Plan)
    if ($PromptContent -notmatch "STEP 4") {
        Fail "case-34: generate-plan PROMPT.md missing STEP 4"
    }
    Pass-Check "case-34: generate-plan PROMPT.md defines STEP 4"

    # Verify output path
    if ($PromptContent -notmatch "\.agents/dev-protocol/next-phase-plan\.md") {
        Fail "case-34: generate-plan PROMPT.md missing output path .agents/dev-protocol/next-phase-plan.md"
    }
    Pass-Check "case-34: generate-plan PROMPT.md defines output path"

    # Verify execution prohibition
    if ($PromptContent -notmatch "NEVER execute loops") {
        Fail "case-34: generate-plan PROMPT.md missing execution prohibition"
    }
    Pass-Check "case-34: generate-plan PROMPT.md prohibits execution"

    if ($SkillContent -notmatch "NEVER execute loops") {
        Fail "case-34: generate-plan SKILL.md missing execution prohibition"
    }
    Pass-Check "case-34: generate-plan SKILL.md prohibits execution"

    # Verify loop format
    if ($PromptContent -notmatch "## Loop N") {
        Fail "case-34: generate-plan PROMPT.md missing loop format"
    }
    Pass-Check "case-34: generate-plan PROMPT.md defines loop format"

    # Verify loop sections
    if ($PromptContent -notmatch "Goal:") {
        Fail "case-34: generate-plan PROMPT.md missing Goal section"
    }
    Pass-Check "case-34: generate-plan PROMPT.md requires Goal"

    if ($PromptContent -notmatch "Files:") {
        Fail "case-34: generate-plan PROMPT.md missing Files section"
    }
    Pass-Check "case-34: generate-plan PROMPT.md requires Files"

    if ($PromptContent -notmatch "Validation:") {
        Fail "case-34: generate-plan PROMPT.md missing Validation section"
    }
    Pass-Check "case-34: generate-plan PROMPT.md requires Validation"
}

# ── AH. Case-35 specific checks (generate-plan defer-aware planning) ─

if ($Case -eq '35') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-35 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-35 test-plan.md exists"

    $GenPrompt = Join-Path $PWD.Path "skills/generate-plan/PROMPT.md"
    $GenSkill = Join-Path $PWD.Path "skills/generate-plan/SKILL.md"

    if (-not (Test-Path $GenPrompt)) {
        Fail "case-35: skills/generate-plan/PROMPT.md not found"
    }
    $PromptContent = Get-Content $GenPrompt -Raw

    # Verify deferred-improvements.md is read
    if ($PromptContent -notmatch "deferred-improvements") {
        Fail "case-35: generate-plan PROMPT.md does not read deferred-improvements.md"
    }
    Pass-Check "case-35: generate-plan PROMPT.md reads deferred-improvements.md"

    # Verify roadmap is read
    if ($PromptContent -notmatch "v2-redesign-roadmap") {
        Fail "case-35: generate-plan PROMPT.md does not read roadmap"
    }
    Pass-Check "case-35: generate-plan PROMPT.md reads roadmap"

    # Verify SKILL.md requires deferred reading
    $SkillContent = Get-Content $GenSkill -Raw
    if ($SkillContent -notmatch "deferred-improvements") {
        Fail "case-35: generate-plan SKILL.md does not require deferred reading"
    }
    Pass-Check "case-35: generate-plan SKILL.md requires deferred reading"

    # Verify prefer small loops
    if ($PromptContent -notmatch "prefer small loops" -and $PromptContent -notmatch "prefer ≤3 files") {
        Fail "case-35: generate-plan PROMPT.md does not prefer small loops"
    }
    Pass-Check "case-35: generate-plan PROMPT.md prefers small loops"

    # Verify avoid repo-wide refactors
    if ($PromptContent -notmatch "repo-wide" -and $PromptContent -notmatch "avoid.*refactor") {
        Fail "case-35: generate-plan PROMPT.md does not avoid repo-wide refactors"
    }
    Pass-Check "case-35: generate-plan PROMPT.md avoids repo-wide refactors"

    # Verify context output includes deferred/roadmap
    if ($PromptContent -notmatch "Deferred items" -and $PromptContent -notmatch "Roadmap items") {
        Fail "case-35: generate-plan PROMPT.md missing deferred/roadmap in context output"
    }
    Pass-Check "case-35: generate-plan PROMPT.md includes deferred/roadmap in output"
}

# ── AI. Case-36 specific checks (generated loops satisfy constraints) ─

if ($Case -eq '36') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-36 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-36 test-plan.md exists"

    $GenPrompt = Join-Path $PWD.Path "skills/generate-plan/PROMPT.md"
    $GenSkill = Join-Path $PWD.Path "skills/generate-plan/SKILL.md"
    $ContinuePrompt = Join-Path $PWD.Path "skills/continue-loop/PROMPT.md"
    $ContinueSkill = Join-Path $PWD.Path "skills/continue-loop/SKILL.md"

    if (-not (Test-Path $GenPrompt)) {
        Fail "case-36: skills/generate-plan/PROMPT.md not found"
    }
    if (-not (Test-Path $ContinuePrompt)) {
        Fail "case-36: skills/continue-loop/PROMPT.md not found"
    }
    if (-not (Test-Path $ContinueSkill)) {
        Fail "case-36: skills/continue-loop/SKILL.md not found"
    }

    $PromptContent = Get-Content $GenPrompt -Raw

    # Verify STEP 5 validates against continue-loop constraints
    if ($PromptContent -notmatch "STEP 5" -and $PromptContent -notmatch "Validate Plan") {
        Fail "case-36: generate-plan PROMPT.md missing validation step"
    }
    Pass-Check "case-36: generate-plan PROMPT.md defines validation step"

    # Verify file count check
    if ($PromptContent -notmatch "file count" -and $PromptContent -notmatch "≤3") {
        Fail "case-36: generate-plan PROMPT.md missing file count constraint"
    }
    Pass-Check "case-36: generate-plan PROMPT.md checks file count"

    # Verify ambiguous language check
    if ($PromptContent -notmatch "ambiguous" -and $PromptContent -notmatch "improve" -and $PromptContent -notmatch "optimize") {
        Fail "case-36: generate-plan PROMPT.md missing ambiguous language check"
    }
    Pass-Check "case-36: generate-plan PROMPT.md checks ambiguous language"

    # Verify non-architectural check
    if ($PromptContent -notmatch "architectural" -and $PromptContent -notmatch "Non-architectural") {
        Fail "case-36: generate-plan PROMPT.md missing architectural constraint"
    }
    Pass-Check "case-36: generate-plan PROMPT.md checks architectural constraint"

    # Verify SKILL.md has validation section
    $SkillContent = Get-Content $GenSkill -Raw
    if ($SkillContent -notmatch "Validate Plan") {
        Fail "case-36: generate-plan SKILL.md missing Validate Plan section"
    }
    Pass-Check "case-36: generate-plan SKILL.md defines Validate Plan"

    # Verify status format compatible with tolerant parsing
    if ($PromptContent -notmatch "\*{0,2}Status:\*{0,2}\s*pending") {
        Fail "case-36: generate-plan PROMPT.md missing Status: pending format"
    }
    Pass-Check "case-36: generate-plan PROMPT.md uses compatible status format"

    # Verify auto-execution-friendly wording requirement
    if ($SkillContent -notmatch "auto-execution" -and $SkillContent -notmatch "Auto-execution") {
        Fail "case-36: generate-plan SKILL.md missing auto-execution-friendly wording requirement"
    }
    Pass-Check "case-36: generate-plan SKILL.md requires auto-execution-friendly wording"
}

# ── AJ. Case-37 specific checks (semantic validation equivalence) ────

if ($Case -eq '37') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-37 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-37 test-plan.md exists"

    $ContinuePrompt = Join-Path $PWD.Path "skills/continue-loop/PROMPT.md"
    if (-not (Test-Path $ContinuePrompt)) {
        Fail "case-37: skills/continue-loop/PROMPT.md not found"
    }
    $PromptContent = Get-Content $ContinuePrompt -Raw

    # Verify Semantic Validation Equivalence section exists
    if ($PromptContent -notmatch "Semantic Validation Equivalence") {
        Fail "case-37: continue-loop PROMPT.md missing Semantic Validation Equivalence section"
    }
    Pass-Check "case-37: continue-loop PROMPT.md contains Semantic Validation Equivalence"

    # Verify at least 4 equivalence rules
    $EquivalenceRules = @(
        "Same domain",
        "Git reality confirms intent",
        "Test outcomes match",
        "Commit intent matches goal"
    )
    foreach ($rule in $EquivalenceRules) {
        if ($PromptContent -notmatch $rule) {
            Fail "case-37: continue-loop PROMPT.md missing equivalence rule: $rule"
        }
    }
    Pass-Check "case-37: continue-loop PROMPT.md defines all 4 equivalence rules"

    # Verify examples of equivalence
    if ($PromptContent -notmatch "tests pass" -and $PromptContent -notmatch "README updated") {
        Fail "case-37: continue-loop PROMPT.md missing equivalence examples"
    }
    Pass-Check "case-37: continue-loop PROMPT.md provides equivalence examples"

    # Verify non-equivalence signals
    $NonEquivalenceSignals = @("started", "completed", "partial", "fully resolved")
    $HasNonEquivalence = $false
    foreach ($signal in $NonEquivalenceSignals) {
        if ($PromptContent -match $signal) {
            $HasNonEquivalence = $true
            break
        }
    }
    if (-not $HasNonEquivalence) {
        Fail "case-37: continue-loop PROMPT.md missing non-equivalence signals"
    }
    Pass-Check "case-37: continue-loop PROMPT.md defines non-equivalence signals"

    # Verify section is between scope derivation and auto-execution
    $ScopePos = $PromptContent.IndexOf("Derive Scope")
    $SemanticPos = $PromptContent.IndexOf("Semantic Validation Equivalence")
    $AutoExecPos = $PromptContent.IndexOf("Auto-Execution")
    if ($ScopePos -eq -1 -or $SemanticPos -eq -1 -or $AutoExecPos -eq -1) {
        Fail "case-37: continue-loop PROMPT.md missing required sections for position check"
    }
    if (-not ($ScopePos -lt $SemanticPos -and $SemanticPos -lt $AutoExecPos)) {
        Fail "case-37: Semantic Validation Equivalence must be between Derive Scope and Auto-Execution"
    }
    Pass-Check "case-37: Semantic Validation Equivalence is correctly positioned"
}

# ── AK. Case-38 specific checks (semantic loop completion detection) ──

if ($Case -eq '38') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-38 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-38 test-plan.md exists"

    $ContinuePrompt = Join-Path $PWD.Path "skills/continue-loop/PROMPT.md"
    $ContinueSkill = Join-Path $PWD.Path "skills/continue-loop/SKILL.md"

    if (-not (Test-Path $ContinuePrompt)) {
        Fail "case-38: skills/continue-loop/PROMPT.md not found"
    }
    $PromptContent = Get-Content $ContinuePrompt -Raw

    # Verify auto-execution path includes semantic completion check
    $AutoExecPath = $PromptContent.Substring($PromptContent.IndexOf("Path A: Auto-execution"))
    if ($AutoExecPath -notmatch "semantic" -and $AutoExecPath -notmatch "Semantic completion") {
        Fail "case-38: continue-loop auto-execution path missing semantic completion check"
    }
    Pass-Check "case-38: continue-loop auto-execution path includes semantic completion check"

    # Verify git reality is used as confirming evidence
    if ($PromptContent -notmatch "git reality") {
        Fail "case-38: continue-loop PROMPT.md missing git reality confirmation"
    }
    Pass-Check "case-38: continue-loop PROMPT.md uses git reality as confirming evidence"

    # Verify test outcomes are used as confirming evidence
    if ($PromptContent -notmatch "test results" -and $PromptContent -notmatch "Test outcomes") {
        Fail "case-38: continue-loop PROMPT.md missing test outcome validation"
    }
    Pass-Check "case-38: continue-loop PROMPT.md uses test outcomes as confirming evidence"

    # Verify semantic ambiguity handling
    if ($PromptContent -notmatch "Semantic completion ambiguity") {
        Fail "case-38: continue-loop PROMPT.md missing semantic completion ambiguity handling"
    }
    Pass-Check "case-38: continue-loop PROMPT.md defines semantic completion ambiguity handling"

    # Verify SKILL.md contains semantic completion concepts
    if (-not (Test-Path $ContinueSkill)) {
        Fail "case-38: skills/continue-loop/SKILL.md not found"
    }
    $SkillContent = Get-Content $ContinueSkill -Raw
    if ($SkillContent -notmatch "semantic" -and $SkillContent -notmatch "equivalence") {
        Fail "case-38: continue-loop SKILL.md missing semantic completion concepts"
    }
    Pass-Check "case-38: continue-loop SKILL.md contains semantic completion concepts"
}

# ── AL. Case-39 specific checks (semantic drift classification) ──────

if ($Case -eq '39') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-39 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-39 test-plan.md exists"

    $DevStatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"
    $DevStatusSkill = Join-Path $PWD.Path "skills/dev-status/SKILL.md"

    if (-not (Test-Path $DevStatusPrompt)) {
        Fail "case-39: skills/dev-status/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevStatusPrompt -Raw

    # Verify Semantic drift classification section exists
    if ($PromptContent -notmatch "Semantic drift classification") {
        Fail "case-39: dev-status PROMPT.md missing Semantic drift classification section"
    }
    Pass-Check "case-39: dev-status PROMPT.md contains Semantic drift classification"

    # Verify documentation-only changes are low drift
    if ($PromptContent -notmatch "Documentation-only" -or $PromptContent -notmatch "low") {
        Fail "case-39: dev-status PROMPT.md missing documentation-only low drift classification"
    }
    Pass-Check "case-39: dev-status PROMPT.md defines documentation-only as low drift"

    # Verify stabilization-pattern commits are low drift
    if ($PromptContent -notmatch "Stabilization pattern" -or $PromptContent -notmatch "low") {
        Fail "case-39: dev-status PROMPT.md missing stabilization-pattern low drift classification"
    }
    Pass-Check "case-39: dev-status PROMPT.md defines stabilization-pattern as low drift"

    # Verify source-impacting commits are high drift
    if ($PromptContent -notmatch "Source-impacting" -or $PromptContent -notmatch "high") {
        Fail "case-39: dev-status PROMPT.md missing source-impacting high drift classification"
    }
    Pass-Check "case-39: dev-status PROMPT.md defines source-impacting as high drift"

    # Verify roadmap-aligned commits are medium drift
    if ($PromptContent -notmatch "Roadmap-aligned" -or $PromptContent -notmatch "medium") {
        Fail "case-39: dev-status PROMPT.md missing roadmap-aligned medium drift classification"
    }
    Pass-Check "case-39: dev-status PROMPT.md defines roadmap-aligned as medium drift"

    # Verify test-only changes are low drift
    if ($PromptContent -notmatch "Test-only" -or $PromptContent -notmatch "low") {
        Fail "case-39: dev-status PROMPT.md missing test-only low drift classification"
    }
    Pass-Check "case-39: dev-status PROMPT.md defines test-only as low drift"

    # Verify SKILL.md or PROMPT.md includes semantic classification in drift output
    $SkillContent = Get-Content $DevStatusSkill -Raw
    $HasSemanticDriftOutput = ($PromptContent -match "semantic classification") -or ($SkillContent -match "semantic classification") -or ($PromptContent -match "Drift: .* source-impacting")
    if (-not $HasSemanticDriftOutput) {
        Fail "case-39: neither dev-status PROMPT.md nor SKILL.md includes semantic classification in drift output"
    }
    Pass-Check "case-39: dev-status includes semantic classification in drift output"
}

# ── AM. Case-40 specific checks (semantic active-work reconstruction) ─

if ($Case -eq '40') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-40 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-40 test-plan.md exists"

    $DevStatusPrompt = Join-Path $PWD.Path "skills/dev-status/PROMPT.md"

    if (-not (Test-Path $DevStatusPrompt)) {
        Fail "case-40: skills/dev-status/PROMPT.md not found"
    }
    $PromptContent = Get-Content $DevStatusPrompt -Raw

    # Verify Active Work Reconstruction section includes semantic theme inference
    $ActiveWorkPos = $PromptContent.IndexOf("Active Work Reconstruction")
    if ($ActiveWorkPos -eq -1) {
        Fail "case-40: dev-status PROMPT.md missing Active Work Reconstruction section"
    }
    Pass-Check "case-40: dev-status PROMPT.md contains Active Work Reconstruction"

    $ActiveWorkSection = $PromptContent.Substring($ActiveWorkPos)
    if ($ActiveWorkSection -notmatch "Semantic theme inference") {
        Fail "case-40: dev-status PROMPT.md Active Work Reconstruction missing semantic theme inference"
    }
    Pass-Check "case-40: dev-status PROMPT.md defines semantic theme inference"

    # Verify stabilization theme (docs + fix(tests) pattern)
    if ($ActiveWorkSection -notmatch "Stabilization") {
        Fail "case-40: dev-status PROMPT.md missing stabilization theme pattern"
    }
    Pass-Check "case-40: dev-status PROMPT.md defines stabilization theme"

    # Verify protocol feature expansion theme (feat(protocol) + skills additions)
    if ($ActiveWorkSection -notmatch "Protocol feature expansion") {
        Fail "case-40: dev-status PROMPT.md missing protocol feature expansion theme"
    }
    Pass-Check "case-40: dev-status PROMPT.md defines protocol feature expansion theme"

    # Verify test coverage expansion theme (test(case-NN) sequence)
    if ($ActiveWorkSection -notmatch "Test coverage expansion") {
        Fail "case-40: dev-status PROMPT.md missing test coverage expansion theme"
    }
    Pass-Check "case-40: dev-status PROMPT.md defines test coverage expansion theme"

    # Verify active development theme (mix of feat/fix/test on same component)
    if ($ActiveWorkSection -notmatch "Active development") {
        Fail "case-40: dev-status PROMPT.md missing active development theme"
    }
    Pass-Check "case-40: dev-status PROMPT.md defines active development theme"

    # Verify roadmap sections as enrichment source
    if ($ActiveWorkSection -notmatch "roadmap" -or $ActiveWorkSection -notmatch "Roadmap") {
        Fail "case-40: dev-status PROMPT.md missing roadmap as enrichment source"
    }
    Pass-Check "case-40: dev-status PROMPT.md uses roadmap sections as enrichment source"

    # Verify deferred items as enrichment source
    if ($ActiveWorkSection -notmatch "deferred" -or $ActiveWorkSection -notmatch "Deferred") {
        Fail "case-40: dev-status PROMPT.md missing deferred items as enrichment source"
    }
    Pass-Check "case-40: dev-status PROMPT.md uses deferred items as enrichment source"

    # Verify git history remains primary source
    if ($ActiveWorkSection -notmatch "Git history" -or $ActiveWorkSection -notmatch "primary") {
        Fail "case-40: dev-status PROMPT.md missing git history as primary source"
    }
    Pass-Check "case-40: dev-status PROMPT.md keeps git history as primary source"
}

# ── AN. Case-41 specific checks (canonical workflow path consistency) ──

if ($Case -eq '41') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-41 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-41 test-plan.md exists"

    $GenPrompt = Join-Path $PWD.Path "skills/generate-plan/PROMPT.md"
    $GenSkill = Join-Path $PWD.Path "skills/generate-plan/SKILL.md"
    $ContinuePrompt = Join-Path $PWD.Path "skills/continue-loop/PROMPT.md"
    $ContinueSkill = Join-Path $PWD.Path "skills/continue-loop/SKILL.md"
    $Contracts = Join-Path $PWD.Path "docs/command-contracts.md"

    if (-not (Test-Path $GenPrompt)) {
        Fail "case-41: skills/generate-plan/PROMPT.md not found"
    }
    if (-not (Test-Path $ContinuePrompt)) {
        Fail "case-41: skills/continue-loop/PROMPT.md not found"
    }
    if (-not (Test-Path $Contracts)) {
        Fail "case-41: docs/command-contracts.md not found"
    }

    $GenPromptContent = Get-Content $GenPrompt -Raw
    $GenSkillContent = Get-Content $GenSkill -Raw
    $ContinuePromptContent = Get-Content $ContinuePrompt -Raw
    $ContinueSkillContent = Get-Content $ContinueSkill -Raw
    $ContractsContent = Get-Content $Contracts -Raw

    # Verify generate-plan writes to .agents/dev-protocol/
    if ($GenPromptContent -notmatch "\.agents/dev-protocol/next-phase-plan\.md") {
        Fail "case-41: generate-plan PROMPT.md does not write to .agents/dev-protocol/next-phase-plan.md"
    }
    Pass-Check "case-41: generate-plan PROMPT.md writes to .agents/dev-protocol/next-phase-plan.md"

    if ($GenSkillContent -notmatch "\.agents/dev-protocol/next-phase-plan\.md") {
        Fail "case-41: generate-plan SKILL.md does not write to .agents/dev-protocol/next-phase-plan.md"
    }
    Pass-Check "case-41: generate-plan SKILL.md writes to .agents/dev-protocol/next-phase-plan.md"

    # Verify continue-loop reads from .agents/dev-protocol/
    if ($ContinuePromptContent -notmatch "\.agents/dev-protocol/next-phase-plan\.md") {
        Fail "case-41: continue-loop PROMPT.md does not read from .agents/dev-protocol/next-phase-plan.md"
    }
    Pass-Check "case-41: continue-loop PROMPT.md reads from .agents/dev-protocol/next-phase-plan.md"

    if ($ContinueSkillContent -notmatch "\.agents/dev-protocol/next-phase-plan\.md") {
        Fail "case-41: continue-loop SKILL.md does not read from .agents/dev-protocol/next-phase-plan.md"
    }
    Pass-Check "case-41: continue-loop SKILL.md reads from .agents/dev-protocol/next-phase-plan.md"

    # Verify no stale docs/ path in generate-plan or contracts
    if ($GenPromptContent -match "docs/next-phase-plan\.md") {
        Fail "case-41: generate-plan PROMPT.md still references stale docs/next-phase-plan.md"
    }
    Pass-Check "case-41: generate-plan PROMPT.md has no stale docs/next-phase-plan.md reference"

    if ($GenSkillContent -match "docs/next-phase-plan\.md") {
        Fail "case-41: generate-plan SKILL.md still references stale docs/next-phase-plan.md"
    }
    Pass-Check "case-41: generate-plan SKILL.md has no stale docs/next-phase-plan.md reference"

    # Verify command-contracts reflects unified path
    $ContractsGenSection = $ContractsContent.Substring($ContractsContent.IndexOf("## generate plan"))
    if ($ContractsGenSection -match "docs/next-phase-plan\.md") {
        Fail "case-41: command-contracts generate-plan section still references docs/next-phase-plan.md"
    }
    Pass-Check "case-41: command-contracts.md uses unified .agents/dev-protocol/next-phase-plan.md path"
}

# ── AO. Case-42 specific checks (test matrix synchronization audit) ────

if ($Case -eq '42') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-42 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-42 test-plan.md exists"

    $TestMatrix = Join-Path $PWD.Path "docs/test-matrix.md"
    if (-not (Test-Path $TestMatrix)) {
        Fail "case-42: docs/test-matrix.md not found"
    }
    Pass-Check "case-42: docs/test-matrix.md exists"

    $MatrixContent = Get-Content $TestMatrix -Raw

    # Verify no stale case names remain
    $StaleCases = @("case-11-continue-loop", "case-11-aborted-goal", "case-10-handoff-mismatch", "case-10-workflow-state-mismatch")
    foreach ($stale in $StaleCases) {
        if ($MatrixContent -match $stale) {
            Fail "case-42: test-matrix.md contains stale case name: $stale"
        }
    }
    Pass-Check "case-42: test-matrix.md has no stale case names"

    # Verify actual test directories are referenced in inventory
    $TestDirs = Get-ChildItem -Directory (Join-Path $PWD.Path "tests") -Filter "case-*"
    foreach ($dir in $TestDirs) {
        $DirName = $dir.Name
        if ($MatrixContent -notmatch [regex]::Escape($DirName)) {
            Fail "case-42: test directory $DirName not referenced in test-matrix.md"
        }
    }
    Pass-Check "case-42: all test directories referenced in test-matrix.md"

    # Verify test inventory table exists and is complete
    if ($MatrixContent -notmatch "## Test Inventory") {
        Fail "case-42: test-matrix.md missing Test Inventory section"
    }
    Pass-Check "case-42: test-matrix.md contains Test Inventory"

    # Verify case-41 and case-42 are in the inventory
    if ($MatrixContent -notmatch "case-41") {
        Fail "case-42: test-matrix.md missing case-41 from inventory"
    }
    Pass-Check "case-42: test-matrix.md includes case-41"

    if ($MatrixContent -notmatch "case-42") {
        Fail "case-42: test-matrix.md missing case-42 from inventory"
    }
    Pass-Check "case-42: test-matrix.md includes case-42"
}

# ── AP. Case-43 specific checks (onboarding documentation consistency) ─

if ($Case -eq '43') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-43 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-43 test-plan.md exists"

    # Verify README.md lists /goal as canonical command
    $Readme = Join-Path $PWD.Path "README.md"
    if (-not (Test-Path $Readme)) {
        Fail "case-43: README.md not found"
    }
    $ReadmeContent = Get-Content $Readme -Raw

    # Find canonical commands table and legacy aliases table
    $CanonPos = $ReadmeContent.IndexOf("Canonical v2 Commands")
    $LegacyPos = $ReadmeContent.IndexOf("Legacy Aliases")

    if ($CanonPos -eq -1) {
        Fail "case-43: README.md missing Canonical v2 Commands section"
    }
    Pass-Check "case-43: README.md has Canonical v2 Commands section"

    if ($LegacyPos -eq -1) {
        Fail "case-43: README.md missing Legacy Aliases section"
    }
    Pass-Check "case-43: README.md has Legacy Aliases section"

    # /goal must appear in canonical section
    $CanonSection = $ReadmeContent.Substring($CanonPos, $LegacyPos - $CanonPos)
    if ($CanonSection -notmatch '/goal') {
        Fail "case-43: /goal not found in Canonical v2 Commands table"
    }
    Pass-Check "case-43: /goal is listed as canonical v2 command"

    # /goal must NOT appear in legacy section
    $LegacySection = $ReadmeContent.Substring($LegacyPos)
    if ($LegacySection -match '/goal') {
        Fail "case-43: /goal still listed in Legacy Aliases table"
    }
    Pass-Check "case-43: /goal is NOT in Legacy Aliases table"

    # Verify project-rules.md has no false statements
    $ProjectRules = Join-Path $PWD.Path ".agents/dev-protocol/project-rules.md"
    if (-not (Test-Path $ProjectRules)) {
        Fail "case-43: project-rules.md not found"
    }
    $RulesContent = Get-Content $ProjectRules -Raw

    if ($RulesContent -match "No git history on master branch yet") {
        Fail "case-43: project-rules.md contains false statement 'No git history on master branch yet'"
    }
    Pass-Check "case-43: project-rules.md does not claim 'no git history'"

    if ($RulesContent -match "no git operations") {
        Fail "case-43: project-rules.md contains false statement about /dev-save having 'no git operations'"
    }
    Pass-Check "case-43: project-rules.md does not claim /dev-save has no git operations"

    # Verify project-rules.md includes v2 commands
    if ($RulesContent -notmatch "generate plan") {
        Fail "case-43: project-rules.md missing generate plan in command reference"
    }
    Pass-Check "case-43: project-rules.md references generate plan"

    if ($RulesContent -notmatch "continue loop") {
        Fail "case-43: project-rules.md missing continue loop in command reference"
    }
    Pass-Check "case-43: project-rules.md references continue loop"

    # Verify command-contracts.md has no stale path references
    $Contracts = Join-Path $PWD.Path "docs/command-contracts.md"
    if (-not (Test-Path $Contracts)) {
        Fail "case-43: command-contracts.md not found"
    }
    $ContractsContent = Get-Content $Contracts -Raw

    if ($ContractsContent -match "docs/next-phase-plan\.md") {
        Fail "case-43: command-contracts.md still references stale docs/next-phase-plan.md"
    }
    Pass-Check "case-43: command-contracts.md uses unified .agents/dev-protocol/next-phase-plan.md path"
}

# ── AQ. Case-44 specific checks (alias skill runtime consistency) ──────

if ($Case -eq '44') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-44 test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-44 test-plan.md exists"

    $AliasSkills = @(
        @{Name="dev-checkpoint"; V2="/dev-save"},
        @{Name="dev-resume"; V2="/dev-status"},
        @{Name="dev-bootstrap"; V2="/dev-init"},
        @{Name="dev-doctor"; V2="/dev-status"},
        @{Name="dev-help"; V2="README.md"},
        @{Name="dev-goal-template"; V2="/dev-scope"}
    )

    foreach ($alias in $AliasSkills) {
        $PromptFile = Join-Path $PWD.Path "skills/$($alias.Name)/PROMPT.md"
        if (-not (Test-Path $PromptFile)) {
            Fail "case-44: skills/$($alias.Name)/PROMPT.md not found"
        }
        $PromptContent = Get-Content $PromptFile -Raw

        # Must contain deprecation notice
        if ($PromptContent -notmatch "DEPRECATED") {
            Fail "case-44: $($alias.Name) PROMPT.md missing deprecation notice"
        }

        # Must redirect to v2 equivalent
        if ($PromptContent -notmatch [regex]::Escape($alias.V2)) {
            Fail "case-44: $($alias.Name) PROMPT.md does not redirect to $($alias.V2)"
        }
        Pass-Check "case-44: $($alias.Name) PROMPT.md deprecates and redirects to $($alias.V2)"
    }

    # Verify no alias contains v1 contradictions
    $ContradictionPatterns = @(
        @{Pattern='NEVER auto-commit'; Why='contradicts v2 /dev-save auto-commit'},
        @{Pattern='none/minor/major'; Why='uses deprecated drift terms instead of none/low/high'},
        @{Pattern='\.agent/'; Why='references legacy v1 path without deprecation note'}
    )

    foreach ($alias in $AliasSkills) {
        $PromptFile = Join-Path $PWD.Path "skills/$($alias.Name)/PROMPT.md"
        $PromptContent = Get-Content $PromptFile -Raw

        foreach ($contradiction in $ContradictionPatterns) {
            if ($PromptContent -match $contradiction.Pattern) {
                Fail "case-44: $($alias.Name) PROMPT.md contains contradiction: $($contradiction.Why)"
            }
        }
    }
    Pass-Check "case-44: no alias PROMPT.md contains v1 contradictions"

    # Verify dev-help no longer displays v1 command table
    $DevHelpPrompt = Join-Path $PWD.Path "skills/dev-help/PROMPT.md"
    $HelpContent = Get-Content $DevHelpPrompt -Raw
    if ($HelpContent -match "dev-bootstrap.*Initialize protocol") {
        Fail "case-44: dev-help PROMPT.md still displays v1 command table"
    }
    Pass-Check "case-44: dev-help PROMPT.md does not display v1 command table"
}

# ── Final result ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "RESULT: PASS"
