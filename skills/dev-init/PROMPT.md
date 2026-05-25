You are executing /dev-init for a software project.

Your goal is to inspect the repository, reconstruct basic project reality, and initialize protocol state if appropriate.

**Boundary**: /dev-init is onboarding, not project analysis. Stop at "knowing the project reality," not "understanding how the project works." Do NOT perform deep architecture reasoning, implementation planning, business/domain analysis, or design conclusion generation.

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

## STEP 4: Project Context Discovery (High-Level Only)

If proceeding (Scenarios B or C), gather surface facts only. Do NOT perform deep analysis.

Allowed:

| Source | What to gather |
|---|---|
| README.md | Project purpose, setup instructions (surface only, no architecture conclusions) |
| docs/ | Existence and top-level structure only |
| CLAUDE.md / AGENTS.md | Runtime conventions, agent instructions |
| CI/CD configs | Presence only |
| Build scripts | Presence only |
| Dependency manifests | Language, framework indicators |
| .gitignore | Project type indicators |

Forbidden:

- Deep source code reading
- Architecture inference beyond explicit docs
- Implementation recommendations
- Generating project conclusions
- Business/domain analysis

Note what is absent. Do NOT assume missing information.

---

## STEP 5: Active Work Detection

Identify ongoing work from:

- `git status --short` — modified/untracked files
- `git branch` — non-main branches
- Outstanding tasks, fix markers in code (search common work-in-progress indicators sparingly)

If dirty workspace (Scenario C):

- Document dirty state
- Do NOT stash, reset, or modify any files
- Do NOT automatically generate state files
- Proceed to Step 6 for confirmation requirement

---

## STEP 6: Behavior Matrix Resolution + Confidence Gating

At this point you have classified into exactly one scenario. Confirm and proceed:

| Scenario | Condition | Next Action |
|---|---|---|
| B | Git repo + clean + no protocol state | Assess confidence → Step 7 if High/Medium, confirm if Low |
| C | Git repo + dirty + no protocol state | Explain dirty state, STOP and ask for confirmation before Step 7 |
| A or D | Already handled in Step 1 or 3 | Should have STOPped |

### Confidence Calibration

Assess confidence based on signals gathered:

| Level | Signals | Action |
|---|---|---|
| **High** | README present, clear structure, clean workspace, explicit docs | Auto-generate state in Step 7 |
| **Medium** | README present but minimal, some ambiguity, clean workspace | Auto-generate, note uncertainties in handoff |
| **Low** | No README, no docs, ambiguous structure, dirty workspace, low discoverability | STOP. Ask user: "Confidence is low. Generate state files anyway?" |

For Scenario C (dirty workspace), confidence is capped at Medium. If other low-confidence signals are present, require explicit confirmation.

---

## STEP 7: State File Generation

Create `.agents/dev-protocol/` directory if needed.

Generate three state files:

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

**Phase rule**: `phase` MUST be `unknown` until validated by user. Do NOT infer phase from maturity. Maturity classification (Step 2) is for confidence calibration only, never for phase assignment.

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

- State generated by /dev-init — confidence is medium until validated by user
```

### project-rules.md

Generate a minimal, non-speculative version. NEVER invent missing facts.

```markdown
# Project Rules

## Known Runtime Facts

- Language/Framework: <from dependency manifests, or "Unknown">
- Project purpose: <from README, or "Unknown">
- CI/CD: <present/absent, or "Unknown">
- Test tooling: <present/absent, or "Unknown">

## Protocol Rules

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
- /dev-save: persist state, validate, commit
- /dev-status: inspect state, resume context, read-only

## Unknown / Requires Validation

- Architecture constraints: <not inferred during init — validate later>
- Testing expectations: <not inferred during init — validate later>
- Documentation conventions: <not inferred during init — validate later>

## Notes

- Initialized by /dev-init on <date>
- Phase unknown until validated by user
```

**Critical rule**: If a field is uncertain, use "Unknown" or "Not inferred during init — validate later." Do NOT fabricate constraints, expectations, or conventions.

State generation rules:

- Write ONLY to `.agents/dev-protocol/`
- Do NOT create root-level copies
- `checkpoint.last_commit` MUST remain empty
- `phase` MUST be `unknown`
- Reflect CURRENT reality, not aspirations
- NEVER invent missing facts
- If confidence is low on any field, use "Unknown" and note in handoff
- For Scenario C (dirty workspace), only generate after explicit user confirmation

---

## STEP 8: Validation

Check:

- State consistency across all three files
- Recoverability from scratch chat
- No missing critical fields
- No root-level duplicates created

If confidence is low:

STOP and report failure with specific gaps.

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
