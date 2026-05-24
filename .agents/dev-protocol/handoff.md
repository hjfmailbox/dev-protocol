# Development Handoff

## Current Focus

v1 usability pass complete.

## Current Status

- active

## Completed Since Last Checkpoint

- Added /dev-goal-template skill (standardized goal template generation)
- Added /dev-help skill (quick usage reference)
- Added /dev-doctor skill (lightweight protocol diagnosis, read-only)
- Added lightweight incident logging mechanism (references/incident-rules.md)
- Integrated incident logging into dev-resume and dev-checkpoint prompts
- Improved self-documentation for dev-bootstrap, dev-checkpoint, dev-resume (When to use / NOT to use / Typical workflow sections)
- Added real-project onboarding guide (docs/onboarding.md, 6 scenarios)
- Updated README.md with new commands and current project status
- Created symlinks for new skills in .claude/skills/
- Added incidents.md to .gitignore

## In Progress

- none

## Blockers

- none

## Important Context

- This IS the dev-protocol project itself, not a consumer of it
- Global spec (design-doc-spec.md) loaded via user CLAUDE.md - governs all design docs
- RTK (Rust Token Killer) is installed for token optimization
- Runtime directory is `.agents/dev-protocol/` (plural), docs at `.agents/dev-protocol/docs/`
- v1 protocol frozen after successful real-project validation
- v1 retrospective completed and frozen
- Usability pass added 3 new commands + incident logging + onboarding guide
- Incident logging is detect+record only, no auto-fix, no daemon, no telemetry
- /dev-bootstrap remains detect+recommend, not detect+mutate
- case-06 test script has a path resolution bug when run from tests/ subdirectory (requires running from repo root)

## Next Recommended Actions

1. Review deferred improvements backlog
2. Consider case-01 full lifecycle test when ready
3. Validate new skills (goal-template, doctor, help) in real project usage

## Notes For Next Session

- State confidence is HIGH
- Strict validation rules enforced in dev-checkpoint skill
- Global spec prohibits the words "继承", "同上", "略" in design docs (word-level match)
- Phase is p3 — usability pass complete
- v1 retrospective frozen, no further protocol changes within v1 scope
- New commands are additive only; core protocol contracts unchanged
