# Development Handoff

## Current Focus

Phase A completion — command contract hardening. Implemented phase inference in /dev-status (5-step priority: next-phase-plan → roadmap → handoff → workflow-state → unknown). Implemented no-op save support in /dev-save (clean workspace allowed, records validated target/summary/reasoning). Added current-focus.md prevention rule. Created test plans for case-a (phase inference), case-b (no-op save), case-c (focus migration).

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
- Created `docs/real-project-validation-checklist.md` with 12 scenarios and full workflow sequence validation
- Documented friction points: command naming ambiguity, validation order complexity, manual fix-goal-output step, phase drift, status freshness drift
- Reclassified deferred backlog: 6 must-fix, 4 safe-to-validate, 6 obsolete/resolved
- Explicit go/no-go decision: BLOCKED_WITH_REQUIRED_FIXES (R3 State Reconciliation and R4 Onboarding Hardening required before R5)
- Performed external benchmark research against 7 workflow systems (ECC, Superpowers, Spec Kit, LangGraph, wshobson/commands, barkain, Microsoft Agent Framework)
- Created `docs/external-benchmark.md` with cross-dimension comparison matrix
- Documented what dev-protocol does better: validation suite, human-readable state, explicit phase, protocol/runtime separation, simplicity
- Identified 5 architecture risks: portability untested, manual save gap, phase detection weak, no subagent support, hooks underutilized
- Listed 7 things explicitly NOT worth copying from external systems
- Final benchmark recommendation: READY_TO_FREEZE_V2
- Clarified v2 canonical commands vs legacy aliases in README.md and onboarding.md
- Cleaned temporary diagnostic artifacts (.claude/hooks/diagnosis-log.txt, stop-hook-log.txt)
- Retained reusable diagnostic tooling (scripts/debug/diagnose-stop-hook.ps1)
- Updated Phase description to v2-frozen-ready-for-real-project-validation
- Clarified architecture boundary: skills/ = protocol runtime, .claude/ = adapter, .agents/ = state
- Fixed /dev-save to auto-stage and auto-commit protocol state (chore(checkpoint) format)
- Updated docs to reflect auto-commit behavior (README, onboarding, workflow-rules)
- case-06 PASS on /dev-save fix commit
- Fixed /dev-status false-positive drift after checkpoint commits
- Added commit-type drift check: chore(checkpoint) commits are expected, not drift
- case-06 PASS on dev-status drift fix commit
- Fixed /dev-status to recognize chore(protocol) and chore(state) as protocol commits
- Expanded protocol commit patterns beyond single chore(checkpoint) prefix
- case-06 PASS on protocol commit detection fix commit
- Implemented phase inference in /dev-status PROMPT.md (5-step priority)
- Implemented no-op save support in /dev-save PROMPT.md (clean workspace allowed)
- Added current-focus.md prevention rule to references/workflow-rules.md
- Created case-a/b/c test plans for new protocol behavior
- case-06 PASS on Phase A completion commit

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

1. **Freeze v2 command surface** — lock `/dev-init`, `/dev-scope`, `/dev-save`, `/dev-status` and state file schema
2. Implement R3: State Reconciliation — fix phase drift (#14) and status freshness drift (#15)
3. Implement R4: Onboarding Hardening — fix Windows artifact emission (#8), NO_OP goal handling (#7), continuation handoff hardening (#6)
4. Re-run real-project validation checklist after R3/R4 completion
5. Proceed to R5: external real-project validation
6. Consider adding mandatory-skill wording to dev-protocol skill prompts (zero-cost improvement from Superpowers benchmark)

## Notes For Next Session

- State confidence is HIGH
- Strict validation rules enforced in dev-checkpoint skill
- Global spec prohibits the words "继承", "同上", "略" in design docs (word-level match)
- Phase is p3 — runtime decoupling complete, structure cleanup complete, r3.1 dry-run complete
- v1 retrospective frozen, no further protocol changes within v1 scope
- New commands are additive only; core protocol contracts unchanged
- Protocol core is portable; runtime adapters are optional convenience layers
- `.claude/skills/` must only contain symlinks; `skills/` is the canonical source
- **NEW: R3.1 dry-run validation complete** — checklist exists, friction documented, deferred reclassified
- **NEW: go/no-go = BLOCKED_WITH_REQUIRED_FIXES** — R3 (State Reconciliation) and R4 (Onboarding Hardening) required before R5
- **NEW: 6 must-fix deferred items identified** (#6, #7, #8, #14, #15, #13 enforcement)
- **NEW: 4 safe-to-validate deferred items** (#1, #3, #4, #9) — need real-project data
- **NEW: 6 obsolete/resolved deferred items** (#2, #5, #9-runtime, #10, #11, #12)
- **NEW: External benchmark complete** — 7 systems evaluated (ECC, Superpowers, Spec Kit, LangGraph, wshobson/commands, barkain, Microsoft Agent Framework)
- **NEW: Benchmark recommendation = READY_TO_FREEZE_V2** — no evaluated system solves the same problem better; remaining risks are implementation bugs, not design flaws
- **NEW: 5 architecture risks documented** — portability untested, manual save gap, phase detection weak, no subagent support, hooks underutilized
- **NEW: 7 things explicitly NOT worth copying** — ECC installer complexity, LangGraph graph API, barkain parallelism, Microsoft Azure coupling, Spec Kit 7-stage rigidity, etc.
