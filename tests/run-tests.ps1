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
        'A'  { return 'case-a-phase-inference' }
        'B'  { return 'case-b-noop-save' }
        'C'  { return 'case-c-focus-migration' }
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

# ── F. Case-A specific checks (phase inference) ──────────────────────

if ($Case -eq 'A') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-A test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-A test-plan.md exists"

    # Verify workflow-state.yml exists
    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-A: workflow-state.yml not found"
    }
    Pass-Check "case-A: workflow-state.yml exists"

    # Verify phase inference sources exist
    $Roadmap = Join-Path $PWD.Path "docs/v2-redesign-roadmap.md"
    $Handoff = Join-Path $StateRoot "handoff.md"
    if (-not (Test-Path $Roadmap) -and -not (Test-Path $Handoff)) {
        Fail "case-A: no phase inference source found (roadmap or handoff)"
    }
    Pass-Check "case-A: phase inference source exists"

    # Verify current-focus.md does NOT exist (prevention)
    $CurrentFocus = Join-Path $StateRoot "current-focus.md"
    if (Test-Path $CurrentFocus) {
        Fail "case-A: current-focus.md should not exist"
    }
    Pass-Check "case-A: current-focus.md absent (redundancy prevention)"
}

# ── G. Case-B specific checks (no-op save) ───────────────────────────

if ($Case -eq 'B') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-B test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-B test-plan.md exists"

    # Workspace must be clean
    & git diff --quiet
    if ($LASTEXITCODE -ne 0) {
        Fail "case-B: workspace must be clean for no-op save test"
    }
    Pass-Check "case-B: workspace clean"

    & git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        Fail "case-B: staged changes detected"
    }
    Pass-Check "case-B: no staged changes"

    # Verify state files exist
    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-B: workflow-state.yml not found"
    }
    Pass-Check "case-B: workflow-state.yml exists"

    $Handoff = Join-Path $StateRoot "handoff.md"
    if (-not (Test-Path $Handoff)) {
        Fail "case-B: handoff.md not found"
    }
    Pass-Check "case-B: handoff.md exists"
}

# ── H. Case-C specific checks (focus migration) ──────────────────────

if ($Case -eq 'C') {
    if (-not (Test-Path $TestPlan)) {
        Fail "case-C test-plan.md not found at $TestPlan"
    }
    Pass-Check "case-C test-plan.md exists"

    $StateRoot = Join-Path $PWD.Path ".agents/dev-protocol"

    # current-focus.md must NOT exist
    $CurrentFocus = Join-Path $StateRoot "current-focus.md"
    if (Test-Path $CurrentFocus) {
        Fail "case-C: current-focus.md should not exist"
    }
    Pass-Check "case-C: current-focus.md absent"

    # handoff.md must contain Current Focus section
    $Handoff = Join-Path $StateRoot "handoff.md"
    if (-not (Test-Path $Handoff)) {
        Fail "case-C: handoff.md not found"
    }
    $HandoffContent = Get-Content $Handoff -Raw
    if ($HandoffContent -notmatch "Current Focus") {
        Fail "case-C: handoff.md missing 'Current Focus' section"
    }
    Pass-Check "case-C: handoff.md contains Current Focus"

    # workflow-state.yml must contain focus field
    $WorkflowState = Join-Path $StateRoot "workflow-state.yml"
    if (-not (Test-Path $WorkflowState)) {
        Fail "case-C: workflow-state.yml not found"
    }
    $StateContent = Get-Content $WorkflowState -Raw
    if ($StateContent -notmatch "focus:") {
        Fail "case-C: workflow-state.yml missing focus field"
    }
    Pass-Check "case-C: workflow-state.yml contains focus field"

    # references/workflow-rules.md must contain preventive rule
    $WorkflowRules = Join-Path $PWD.Path "references/workflow-rules.md"
    if (-not (Test-Path $WorkflowRules)) {
        Fail "case-C: references/workflow-rules.md not found"
    }
    $RulesContent = Get-Content $WorkflowRules -Raw
    if ($RulesContent -notmatch "current-focus.md") {
        Fail "case-C: references/workflow-rules.md missing current-focus.md prevention rule"
    }
    Pass-Check "case-C: workflow-rules.md documents current-focus.md prevention"
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
    if ($PromptContent -notmatch "NEVER stage non-protocol files") {
        Fail "case-07: /dev-save prompt missing 'NEVER stage non-protocol files' constraint"
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
    $GitPos = $PromptContent.IndexOf("git reality")
    $WsPos = $PromptContent.IndexOf("workflow-state.yml")
    $FocusPos = $PromptContent.IndexOf("current-focus")
    $RoadmapPos = $PromptContent.IndexOf("roadmap")
    $FallbackPos = $PromptContent.IndexOf("fallback")

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

    if ($PromptContent -notmatch "NEVER force /goal") {
        Fail "case-15: /dev-scope prompt missing scope misuse detection (NEVER force /goal)"
    }
    Pass-Check "case-15: /dev-scope prompt detects scope misuse"
}

# ── Final result ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "RESULT: PASS"
