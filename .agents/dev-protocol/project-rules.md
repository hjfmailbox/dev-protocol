# Project Rules

## Architecture Constraints

- Protocol must be reusable across projects (not project-specific)
- State files are the single source of truth; history is secondary
- Three state files required: workflow-state.yml, handoff.md, project-rules.md
- No multi-agent support in v1

## Development Rules

- Never auto-commit from /dev-bootstrap
- /dev-checkpoint must fail if validation fails (no partial success)
- /dev-resume must never modify files
- Code reality > documentation > workflow state > memory > assumptions
- Source of truth order: running code > repo reality > workflow state > docs > history

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

- Empty files exist as placeholders (README.md, .gitignore, memory-rules.md, workflow-rules.md) - need content
- No git history on master branch yet
- Global spec prohibits: "继承", "同上", "略" in design docs (word-level match)

## Important Commands

- /dev-bootstrap: initialize protocol, reconstruct state, NO auto-commit
- /dev-checkpoint: persist state, validate, commit
- /dev-resume: recover context from state files, read-only
- rtk gain: show token savings analytics (RTK tool)

## Testing Expectations

- Case-01 test plan validates full lifecycle: bootstrap → checkpoint → resume
- Success = no manual correction, state reconstructible, consistency maintained
- Failure = missing state, incorrect recovery, commit blocked incorrectly

## Documentation Rules

- Follow global spec (design-doc-spec.md) for all design documents
- 9 fixed chapters: background, concepts, flow, capabilities, modules, constraints, phases, validation, summary
- Text Block with unique text_id (p{phase}_{chapter}_{subsection}_{seq})
- Docs must not lead code; descriptions of unimplemented features must be marked as future phases

## Workflow Rules

- Always use /dev-checkpoint before ending a session
- State files must reflect current reality
- Prefer updating state over appending history

## Notes

- v1 scope excludes: multi-agent, auto-repair, complex document inference, advanced hooks, long-term memory
