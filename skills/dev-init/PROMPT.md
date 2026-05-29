You are executing /dev-init for a software project.

Your goal is to inspect the repository, reconstruct basic project reality, and initialize protocol state if appropriate.

**Boundary**: /dev-init is onboarding, not project analysis. Stop at "knowing the project reality," not "understanding how the project works." Do NOT perform deep architecture reasoning, implementation planning, business/domain analysis, or design conclusion generation.

## STEP 0: Reality Priority

Before any discovery, establish the source-of-truth hierarchy. When sources conflict, the higher-priority source wins.

```
Repository reality (files on disk) > Git state (git status, git log) > Explicit docs (README, CLAUDE.md) > Existing protocol state > Assumptions
```

Implications:

- If `git status` contradicts what docs claim, `git status` wins
- If README describes features not in code, the code wins
- If existing workflow-state.yml claims phase `p2` but repository is empty, repository wins
- NEVER trust assumptions over observable reality
- NEVER infer beyond what is explicitly present

You MUST follow these steps strictly.

---

## STEP 1: Git State Discovery

Run and gather:

- `git status` — branch, clean/dirty, modified/untracked files
- `git log --oneline -20` — recent commit context
- `git rev-parse --git-dir` — confirms git initialized

Classify git state:

| Condition | Classification |
|---|---|
| `git rev-parse --git-dir` fails | No git repository (Scenario A) |
| Working tree clean, no uncommitted changes | Clean |
| Modified or untracked files present | Dirty |

If Scenario A (no git repo):

STOP. Output:

```
No git repository detected.

Required: git init
Recommended:
  git init
  git add .
  git commit -m "initial commit"
  /dev-init

/dev-init requires git history to inspect and reconstruct project reality.
```

Do NOT create state files. Do NOT modify anything.

---

## STEP 2: Repository Maturity Assessment

If git exists, assess maturity using:

- Commit depth (`git rev-list --count HEAD`)
- Directory structure (src/, tests/, docs/, lib/, etc.)
- File count (`git ls-files | wc -l` or equivalent)
- Dependency manifests (package.json, Cargo.toml, requirements.txt, etc.)

Classify into exactly one:

| Classification | Indicators |
|---|---|
| **empty repo** | 0–2 commits, <5 files, no src/ or tests/ |
| **early repo** | 3–20 commits, basic structure forming, minimal docs |
| **active repo** | 21–100 commits, src/ and tests/ present, some docs |
| **mature repo** | 100+ commits, rich docs, CI, tests, multiple modules |

Output classification with brief justification.

---

## STEP 3: Existing Protocol State Detection

Check for state files in this exact order:

1. `.agents/dev-protocol/workflow-state.yml`
2. `.agents/dev-protocol/handoff.md`
3. `.agents/dev-protocol/project-rules.md`

Also check legacy path (informational only):

4. `.agent/dev-protocol/` (v1 legacy — note if found)

Rules:

- If ANY state file exists in `.agents/dev-protocol/` → **Scenario D**
- If NO state files exist anywhere → proceed to Step 4

If Scenario D:

Output:

```
Existing protocol state detected at .agents/dev-protocol/

Recommended: /dev-status
Reason: Existing protocol state already exists.
        Re-running init is unnecessary and may overwrite onboarding assumptions.

Next step: Run /dev-status to inspect and reconstruct context from existing state.
```

STOP. Do NOT create or modify state files. Do NOT overwrite existing state.

---

## STEP 4: Project Context Discovery (Surface Facts Only)

If proceeding (Scenarios B or C), gather surface facts only. Do NOT perform deep analysis.

Allowed:

| Source | What to gather |
|---|---|
| README.md | Project name, one-line purpose, setup instructions (surface only). NEVER infer architecture from README wording. |
| docs/ | Existence and top-level structure only. Do NOT read contents beyond file names. |
| CLAUDE.md / AGENTS.md | Runtime conventions, agent instructions |
| CI/CD configs | Presence only |
| Build scripts | Presence only |
| Dependency manifests | Language, framework indicators |
| .gitignore | Project type indicators |

Forbidden:

- Deep source code reading
- Architecture inference beyond explicit docs
- Architecture conclusions from README wording
- Implementation recommendations
- Generating project conclusions
- Business/domain analysis

Note what is absent. Do NOT assume missing information.

---

## STEP 5: Active Work Detection

Identify ongoing work from:

- `git status --short` — modified/untracked files only
- `git branch` — non-main branches
- Modified/untracked files for outstanding tasks or fix markers (do NOT scan the full repository)

If dirty workspace (Scenario C):

- Document dirty state
- Do NOT stash, reset, or modify any files
- Do NOT generate state files in this step
- Proceed to Step 6 for confirmation logic (Scenario C is always gated)

---

## STEP 6: Behavior Matrix Resolution + Confidence Gating

At this point you have classified into exactly one scenario. Confirm and proceed:

| Scenario | Condition | Next Action |
|---|---|---|
| B | Git repo + clean + no protocol state | Assess confidence → Step 7 if High/Medium, STOP and confirm if Low |
| C | Git repo + dirty + no protocol state | STOP. Explain dirty state, request explicit confirmation. Only proceed to Step 7 if user confirms. |
| A or D | Already handled in Step 1 or 3 | Should have STOPped |

### Confidence Calibration

Assess confidence based on signals gathered in Steps 1–5. This is the ONLY step that gates state generation.

| Level | Signals | Action |
|---|---|---|
| **High** | README present, clear structure, clean workspace, explicit docs | Proceed to Step 7 |
| **Medium** | README present but minimal, some ambiguity, clean workspace | Proceed to Step 7, note uncertainties in handoff |
| **Low** | No README, no docs, ambiguous structure, dirty workspace, low discoverability | STOP. Output: "Confidence is low. Generate state files anyway? (yes/no)" |

Rules:

- Scenario C (dirty workspace) caps confidence at Medium
- If Low confidence signals are present in any scenario, STOP and require explicit user confirmation
- Do NOT proceed to Step 7 without passing confidence gating
- Confidence gating happens ONLY in this step

---

## STEP 7: State File Generation

Create `.agents/dev-protocol/` directory if needed.

Generate three state files and bootstrap runtime telemetry:

### workflow-state.yml

Use template:

```yaml
version: 1

project:
  name: "<inferred project name from README or directory>"
  initialized: true

current_state:
  phase: unknown
  focus: onboarding
  status: active

progress:
  completed: []
  in_progress: []
  blocked: []

context:
  important_constraints: []
  recent_decisions: []

next:
  recommended_actions:
    - "review generated state files"
    - "run /dev-scope to declare first goal"

checkpoint:
  last_updated: ""
  last_commit: ""  # MUST be empty — no checkpoint baseline yet
  summary: ""

confidence:
  state_confidence: <high | medium | low>
```

**Phase rule**: `phase` MUST be `unknown` until validated by user or `/dev-status`. Do NOT infer phase from maturity. Maturity classification (Step 2) is for confidence calibration only, never for phase assignment.

**Phase ownership**: The user or `/dev-status` owns setting the correct phase. `/dev-init` only records that onboarding occurred; it does NOT claim to know the project's development phase.

**Confidence rule**: Set `state_confidence` to match the confidence assessed in Step 6. Include note in handoff if Medium or Low.

### handoff.md

Use template:

```markdown
# Development Handoff

## Current Focus

- Protocol initialization completed via /dev-init
- <any active work detected>

## Current Status

- active

## Completed Since Last Checkpoint

- /dev-init executed
- Project reality reconstructed from repository inspection

## In Progress

- <list from active work detection, or "none">

## Blockers

- <list, or "none">

## Important Context

- Repository maturity: <classification>
- Git state: <clean/dirty>
- <any relevant discoveries from Steps 4–5>

## Next Recommended Actions

1. Review generated state files for accuracy
2. git add .agents/
3. git commit -m "chore(protocol): initialize dev-protocol"
4. Run /dev-scope to declare first goal

## Notes For Next Session

- State generated by /dev-init
- Phase is `unknown` — must be validated by user or `/dev-status` before relying on it for planning
- Confidence level: <high/medium/low>
```

### project-rules.md

Generate a minimal, non-speculative version. NEVER invent missing facts.

**Separation principle**: Project runtime facts and protocol operating rules are distinct. Protocol rules describe how dev-protocol operates; they are NOT project-specific conventions.

```markdown
# Project Rules

## Project Runtime Facts

Facts observed during /dev-init. Never inferred, never speculated.

- Language/Framework: <from dependency manifests, or "Unknown">
- Project purpose: <from README, or "Unknown">
- CI/CD: <present/absent, or "Unknown">
- Test tooling: <present/absent, or "Unknown">

## dev-protocol Operating Rules

These are protocol-level constraints. They do NOT belong to the project; they govern how the protocol interacts with this repository.

- Never auto-commit from /dev-init
- /dev-save must fail if validation fails (no partial success)
- /dev-status must never modify files
- State files are the single source of truth

## Code Style Rules

- Commit format: `<type>(<scope>): <summary>`
- Allowed types: feat, fix, refactor, docs, test, chore

## Important Commands

- /dev-init: initialize protocol, reconstruct state, NO auto-commit
- /dev-scope: declare focused goal with validation criteria
- /dev-save: persist state, validate, no git operations
- /dev-status: inspect state, resume context, read-only

## Unknown / Requires Validation

Fields NOT inferred during /dev-init. Must be validated by user or /dev-status before use.

- Architecture constraints: <unknown — validate before relying on>
- Testing expectations: <unknown — validate before relying on>
- Documentation conventions: <unknown — validate before relying on>

## Notes

- Initialized by /dev-init on <date>
- Phase is `unknown` until user or /dev-status validates and updates it
```

### runtime-telemetry Bootstrap

After state files, ensure `.agents/dev-protocol/runtime-telemetry/` exists with:

1. **Find dev-protocol source**: Resolve the path of this skill file (`skills/dev-init/SKILL.md`) upward to the dev-protocol repository root.
2. **Copy from source** to target project's `.agents/dev-protocol/runtime-telemetry/`:
   - `telemetry.ps1`
   - `README.md`
3. **Create `config.json`** if not copied:
   ```json
   {
     "enabled": true,
     "record_command_args": true,
     "record_git_context": true
   }
   ```
4. If source files cannot be found, create the directory and `config.json` only, and note the missing telemetry recorder in handoff.md.

**Critical rule**: If a field is uncertain, use "Unknown" or "not inferred during init — validate before relying on." Do NOT fabricate constraints, expectations, or conventions.

State generation rules:

- Write ONLY to `.agents/dev-protocol/`
- Do NOT create root-level copies
- `checkpoint.last_commit` MUST remain empty
- `phase` MUST be `unknown`
- Reflect CURRENT reality, not aspirations
- NEVER invent missing facts
- If confidence is low on any field, use "Unknown" and note in handoff
- For Scenario C (dirty workspace), only generate after explicit user confirmation
- Runtime telemetry files MUST be created so `/dev-status`, `/dev-scope`, `/dev-save`, and other commands can record events

---

## STEP 8: Validation

Check:

- State consistency across all three files
- Recoverability from scratch chat
- No missing critical fields
- No root-level duplicates created
- `phase` is `unknown`
- `checkpoint.last_commit` is empty
- No invented facts in project-rules.md

If validation fails:

STOP and report specific gaps. Do NOT proceed with invalid state.

---

## STEP 9: Output Summary

Provide:

- Detected scenario (A/B/C/D) and resolution
- Repository maturity classification
- Git state summary
- Created/updated files
- Detected active work (if any)
- Confidence level
- Recommended next step

For Scenario B or C, output MUST include:

```
State files generated in .agents/dev-protocol/
Next: Review → git add .agents/ → git commit → /dev-scope
```

---

## RULES

- NEVER auto-commit
- NEVER stage files
- NEVER mutate source code
- NEVER overwrite existing `.agents/dev-protocol/` state without explicit user instruction
- NEVER invent missing facts
- NEVER proceed with low confidence silently
- NEVER perform deep project analysis (architecture, implementation, domain)
- ALWAYS prefer correctness over completeness
- ALWAYS prefer reality over history
- ALWAYS stop at onboarding boundary — /dev-init is onboarding, not project analysis
