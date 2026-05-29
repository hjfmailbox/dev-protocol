# Project Rules

## Architecture Constraints

- Protocol must be reusable across projects (not project-specific)
- State files are the single source of truth; history is secondary
- Three core state files required: workflow-state.yml, handoff.md, project-rules.md
- Optional state files: goal-output.md, next-phase-plan.md (created by workflow, not required for initialization)
- No multi-agent support in v1

## Reality Priority

The protocol follows a strict source-of-truth hierarchy. When any two sources conflict, the higher-priority source wins.

```
Running code > Repository reality > Protocol state > Documentation > History > Memory > Assumptions
```

| Priority | Source | Meaning |
|---|---|---|
| 1 | **Running code** | The actual executable behavior is the ultimate truth |
| 2 | **Repository reality** | `git status`, `git log`, file contents on disk |
| 3 | **Protocol state** | `.agents/dev-protocol/workflow-state.yml`, `handoff.md` |
| 4 | **Documentation** | `docs/`, `references/`, `README.md` |
| 5 | **History** | Previous commits, past session logs |
| 6 | **Memory** | Agent's recollection of prior conversation |
| 7 | **Assumptions** | Unverified beliefs about project state |

**Implications**:

- If `workflow-state.yml` claims the workspace is dirty but `git status --short` is empty, `git status` wins. The state file is stale and must be updated.
- If `handoff.md` says the phase is `p1` but the repository has 50 commits and 10 docs, the repository wins. The phase is underestimated and must be corrected.
- If documentation describes a feature that does not exist in code, the code wins. Documentation must be marked as describing a future phase.
- If an agent remembers the project being in a different state than the files show, the files win. The agent must re-read state files on every session.

## Development Rules

- Never auto-commit from /dev-init
- /dev-save must fail if validation fails (no partial success)
- /dev-status must never modify files
- Reality priority is enforced on every command: recompute from git and files before trusting persisted state

## Code Style Rules

- Commit format: `<type>(<scope>): <summary>`
- Allowed types: feat, fix, refactor, docs, test, chore
- Summary: present tense, concise, describes actual change

## Goal Output Generation Rules (CRITICAL)

**LLM must not generate changed_files. Use the deterministic script.**

Required workflow:

1. Commit goal changes
2. Write goal-output.md (with any placeholder for changed_files)
3. Run `pwsh scripts/fix-goal-output.ps1` (Windows) or `./scripts/fix-goal-output.sh` (Unix)
4. Script overwrites `## Changed Files` section with git-derived list
5. Verify script output before proceeding

**Why prompt-level enforcement failed:**

The LLM rewrites or omits files even when instructed to use git output verbatim.
Prompt reminders ("remember to use git", "use output verbatim") are insufficient.
Only programmatic extraction guarantees correctness.

**What the script does:**

- Runs `git diff-tree --no-commit-id --name-only -r HEAD`
- Parses goal-output.md
- Replaces `## Changed Files` section with authoritative list
- Writes file back

**Prohibited:**

- Manual file lists from memory
- LLM formatting or paraphrasing of file lists
- Prompt-level enforcement without script execution
- Skipping the script "because the list looks correct"

**Script location:**

- `scripts/fix-goal-output.ps1` (PowerShell)
- `scripts/fix-goal-output.sh` (bash)

Both scripts are committed and portable across projects.

## Important Patterns

- State-over-history: prefer updating current truth over appending logs
- Fail-fast: hard failure on corruption, soft failure on ambiguity
- Drift detection: always check code vs docs vs state consistency

## Known Pitfalls

- Global spec prohibits: "继承", "同上", "略" in design docs (word-level match)
- Alias skill PROMPT.md files may contain stale v1 guidance; always prefer canonical v2 skills

## Important Commands

- /dev-init: initialize protocol, reconstruct state, NO auto-commit
- /dev-scope: declare focused goal with validation criteria
- /dev-save: persist state, validate, auto-commit protocol files only (chore(checkpoint))
- /dev-status: inspect state, diagnose, resume context, read-only
- generate plan: decompose goal into loops, write next-phase-plan.md
- continue loop: read plan, derive scope, auto-execute or produce scope document
- rtk gain: show token savings analytics (RTK tool)

## Testing Expectations

- Case-01 test plan validates full lifecycle: init → scope → work → save → status
- Success = no manual correction, state reconstructible, consistency maintained
- Failure = missing state, incorrect recovery, commit blocked incorrectly

## Documentation Rules

- Follow global spec (design-doc-spec.md) for all design documents
- 9 fixed chapters: background, concepts, flow, capabilities, modules, constraints, phases, validation, summary
- Text Block with unique text_id (p{phase}_{chapter}_{subsection}_{seq})
- Docs must not lead code; descriptions of unimplemented features must be marked as future phases

## Workflow Rules

- Always use /dev-save before ending a session
- State files must reflect current reality
- Prefer updating state over appending history
- Always run /dev-status after session reset before writing code

## Notes

- v2 scope excludes: multi-agent, auto-repair, complex document inference, advanced hooks, long-term memory, new skill implementation (documentation-only redesign)
