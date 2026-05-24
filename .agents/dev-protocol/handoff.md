# Development Handoff

## Current Focus

Runtime structure cleanup complete: duplicated skill copies removed, obsolete test artifact cleaned.

## Current Status

- active

## Completed Since Last Checkpoint

- Removed duplicated skill copies in `.claude/skills/` (dev-doctor, dev-goal-template, dev-help)
- Replaced copied directories with symlinks pointing to canonical `skills/*`
- Verified all `.claude/skills/*` entries are symlinks
- Added canonical source note to `docs/runtime-integrations.md` (`skills/` is canonical, `.claude/skills/` is optional runtime wiring only)
- Removed obsolete `tests/case-01.txt` (unreferenced, unused)
- case-06 PASS on goal commit

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

## Next Recommended Actions

1. Review deferred improvements backlog
2. Consider Cursor or VS Code integration prototype
3. Validate protocol in a non-Claude environment (e.g., manual workflow)

## Notes For Next Session

- State confidence is HIGH
- Strict validation rules enforced in dev-checkpoint skill
- Global spec prohibits the words "继承", "同上", "略" in design docs (word-level match)
- Phase is p3 — runtime decoupling complete, structure cleanup complete
- v1 retrospective frozen, no further protocol changes within v1 scope
- New commands are additive only; core protocol contracts unchanged
- Protocol core is portable; runtime adapters are optional convenience layers
- `.claude/skills/` must only contain symlinks; `skills/` is the canonical source
