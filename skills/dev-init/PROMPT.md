You are executing /dev-init for a software project.

Your goal is to inspect the repository, reconstruct project reality, and initialize protocol state if appropriate.

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

Action: Redirect to /dev-status
Reason: /dev-init is for first-time initialization only.
       Running init on existing state risks overwriting current progress.

Next step: Run /dev-status to inspect and reconstruct context from existing state.
```

STOP. Do NOT create or modify state files.

---

## STEP 4: Project Context Discovery

If proceeding (Scenarios B or C), inspect:

| Source | What to gather |
|---|---|
| README.md | Project purpose, setup instructions, architecture overview |
| docs/ | Design documents, API docs, architecture diagrams |
| CLAUDE.md / AGENTS.md | Runtime conventions, agent instructions |
| CI/CD configs | GitHub Actions, Travis, etc. — workflow maturity |
| Build scripts | Makefile, package.json scripts, build.rs, etc. |
| Dependency manifests | Language, framework, external dependencies |
| .gitignore | Project type indicators |

Do NOT assume missing information. Note what is absent.

---

## STEP 5: Active Work Detection

Identify ongoing work from:

- `git status --short` — modified/untracked files
- `git branch` — non-main branches
- Outstanding tasks, fix markers in code (search common work-in-progress indicators sparingly)

If dirty workspace (Scenario C):

- Document dirty state in generated handoff.md
- Set `current_state.status` to `active` with note about uncommitted work
- Do NOT stash, reset, or modify any files

---

## STEP 6: Behavior Matrix Resolution

At this point you have classified into exactly one scenario. Confirm and proceed:

| Scenario | Condition | Next Action |
|---|---|---|
| B | Git repo + clean + no protocol state | Proceed to Step 7 (state generation) |
| C | Git repo + dirty + no protocol state | Proceed to Step 7 (state generation with dirty note) |
| A or D | Already handled in Step 1 or 3 | Should have STOPped |

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
  phase: "<inferred phase: p1 | p2 | p3 | p4 | p5>"
  focus: "<active focus or 'initializing'>"
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
  state_confidence: medium
```

Phase inference rules:

| Maturity | Suggested Phase | Rationale |
|---|---|---|
| empty repo | p1 | protocol-definition-and-bootstrap |
| early repo | p1 or p2 | depending on whether bootstrap is complete |
| active repo | p2 or p3 | architecture-and-core or implementation |
| mature repo | p3 or p4 | implementation or hardening |

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

Use template from `templates/project-rules.md` or generate minimal version:

```markdown
# Project Rules

## Architecture Constraints

- <from project context discovery>

## Development Rules

- Never auto-commit from /dev-init
- /dev-save must fail if validation fails (no partial success)
- /dev-status must never modify files

## Code Style Rules

- Commit format: `<type>(<scope>): <summary>`
- Allowed types: feat, fix, refactor, docs, test, chore

## Important Patterns

- State-over-history: prefer updating current truth over appending logs
- Fail-fast: hard failure on corruption, soft failure on ambiguity

## Known Pitfalls

- <from active work detection or project context>

## Important Commands

- /dev-init: initialize protocol, reconstruct state, NO auto-commit
- /dev-scope: declare focused goal with validation criteria
- /dev-save: persist state, validate, commit
- /dev-status: inspect state, diagnose, resume context, read-only

## Testing Expectations

- <from project context>

## Documentation Rules

- <from project context or global conventions>

## Workflow Rules

- Always use /dev-save before ending a session
- State files must reflect current reality
- Prefer updating state over appending history
- Always run /dev-status after session reset before writing code

## Notes

- Initialized by /dev-init on <date>
```

State generation rules:

- Write ONLY to `.agents/dev-protocol/`
- Do NOT create root-level copies
- `checkpoint.last_commit` MUST remain empty
- Reflect CURRENT reality, not aspirations
- If confidence is low on any field, use empty string or `[]` and note in handoff

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
- ALWAYS prefer correctness over completeness
- ALWAYS prefer reality over history
