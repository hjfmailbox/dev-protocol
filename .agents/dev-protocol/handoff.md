# Development Handoff

## Current Focus

v1→v2 compatibility aliases implemented. v1 commands deprecated but supported: /dev-bootstrap→/dev-init, /dev-resume→/dev-status, /dev-goal-template→/dev-scope, /dev-checkpoint→/dev-save.

## Current Status

- active

## Completed Since Last Checkpoint

- Removed duplicated skill copies in `.claude/skills/` (dev-doctor, dev-goal-template, dev-help)
- Replaced copied directories with symlinks pointing to canonical `skills/*`
- Verified all `.claude/skills/*` entries are symlinks
- Added canonical source note to `docs/runtime-integrations.md` (`skills/` is canonical, `.claude/skills/` is optional runtime wiring only)
- Removed obsolete `tests/case-01.txt` (unreferenced, unused)
- case-06 PASS on goal commit
- Implemented /dev-scope v2 runtime skill (R2.3) with ambiguity detection and validation-first rule
- case-06 PASS on /dev-scope implementation commit
- Implemented /dev-save v2 runtime skill (R2.4) for state persistence
- case-05 and case-06 PASS on /dev-save implementation commit
- v2 command surface complete: /dev-init, /dev-status, /dev-scope, /dev-save
- Hardened /dev-save semantics: removed checkpoint/commit/staging ambiguity from skill definitions and documentation
- Implemented v1→v2 compatibility aliases: /dev-bootstrap→/dev-init, /dev-resume→/dev-status, /dev-goal-template→/dev-scope, /dev-checkpoint→/dev-save
- case-05 and case-06 PASS on alias implementation commit

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
- **NEW: Protocol is runtime-agnostic** — works with Claude Code, Cursor, Copilot, or manual workflows
- **NEW: .claude/ is optional** — protocol correctness guaranteed without hooks
- **NEW: `.claude/skills/` is symlink-only** — canonical source is `skills/`
- **NEW: v1→v2 aliases implemented** — v1 commands deprecated but supported, redirecting to v2 semantics

## Next Recommended Actions

1. Review v2 command surface for gaps or inconsistencies
2. Consider real-project validation of full v2 workflow
3. Evaluate deferred backlog for next phase

## Notes For Next Session

- State confidence is HIGH
- Strict validation rules enforced in dev-checkpoint skill
- Global spec prohibits the words "继承", "同上", "略" in design docs (word-level match)
- Phase is p3 — runtime decoupling complete, structure cleanup complete
- v1 retrospective frozen, no further protocol changes within v1 scope
- New commands are additive only; core protocol contracts unchanged
- Protocol core is portable; runtime adapters are optional convenience layers
- `.claude/skills/` must only contain symlinks; `skills/` is the canonical source
