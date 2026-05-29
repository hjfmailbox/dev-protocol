# Deferred Improvements

> Only unresolved improvements with demonstrated workflow value remain here.
> Completed items are removed rather than archived.

---

## ~~D01 — Reduce `/dev-scope` → `/goal` duplication~~

**Status**: RESOLVED

Auto-execution for simple scopes implemented in `skills/dev-scope/PROMPT.md` and `SKILL.md`.

`/dev-scope` now evaluates auto-execution criteria after scope generation. When ALL criteria are met (≤3 files, non-architectural, no API changes, single-step validation, low ambiguity, low blast radius), the scope executes directly without requiring a separate `/goal`.

Complex, ambiguous, or architectural work still requires explicit `/goal`.

See: `docs/workflow-compression.md` for design rationale.

### Problem

Simple workflow loops currently require:

```text
/dev-scope
/goal
```

for even low-risk scoped work.

This creates unnecessary friction during iterative development and validation loops.

### Why Deferred

The current flow is functionally correct, but repetitive enough to reduce protocol ergonomics.

Observed repeatedly during DesignDocMCP validation loops.

### Desired Outcome

For simple scoped work:

```text
/dev-scope
```

should optionally execute directly without requiring an additional `/goal`.

Keep `/goal` for:

* multi-step planning
* repo-wide changes
* complex orchestration
* ambiguous work
* long-running implementations

### Suggested Fix

Introduce lightweight execution mode:

```text
/dev-scope --execute
```

or implicit auto-execution for low-risk scopes.

### Risk

Low

### Priority

P2

---

## ~~D02 — Continuous loop execution from plan~~

**Status**: RESOLVED

`continue loop` workflow implemented in `skills/continue-loop/PROMPT.md` and `SKILL.md`.

`continue loop` reads `next-phase-plan.md`, identifies the next incomplete loop via tolerant parsing, derives scope from plan + handoff + recent commits, applies auto-execution criteria, and either executes immediately or produces a scope document for `/goal`.

Preconditions verified before execution. Stop conditions defined for no plan, empty plan, dirty workspace, blockers, drift, ambiguity, all completed, and unrecognizable format.

See: `docs/workflow-compression.md` for design rationale. See: `docs/command-contracts.md` for command contract.

### Problem

Planned execution still requires repeated manual orchestration:

```text
/dev-status
/dev-scope
implement
/dev-save
repeat
```

even when `next-phase-plan.md` already exists.

### Why Deferred

The planning workflow is now mature enough to support guided continuation.

Repeated loops exposed substantial orchestration friction.

### Desired Outcome

Allow:

```text
continue loop
```

or:

```text
/dev-continue
```

to automatically:

1. detect next planned loop
2. derive scope
3. execute workflow
4. prepare checkpoint recommendation

### Suggested Fix

Add plan-aware continuation mode:

Sources:

* `next-phase-plan.md`
* `current-focus.md`
* recent completed loops

### Risk

Medium

### Priority

P2

---

## D03 — `/dev-save` optional arguments

### Problem

`/dev-save` currently infers:

* checkpoint summary
* save reason
* commit semantics

heuristically.

User cannot explicitly provide context.

### Why Deferred

The current auto behavior works, but friction appears during repeated loop execution and review.

### Desired Outcome

Support optional arguments such as:

```text
/dev-save "loop 5 undo implementation"

/dev-save --summary="loop 5"

/dev-save --type=checkpoint
```

### Rules

* fully backward compatible
* no required arguments
* preserve current auto behavior

### Suggested Fix

Support optional structured flags while keeping default inference.

### Risk

Low

### Priority

P2

---

## D04 — `/dev-status` phase recovery remains weak

### Problem

`/dev-status` frequently reports:

```text
phase: unknown
```

despite enough surrounding context existing.

Observed after:

* planning workflow
* completed loops
* saved checkpoints

### Why Deferred

Context recovery works, but user-facing workflow quality suffers.

Already impacts usability.

### Desired Outcome

Infer active phase using:

Priority order:

1. current protocol state
2. `current-focus.md`
3. `next-phase-plan.md`
4. recent completed scopes
5. recent git activity

Example:

Instead of:

```text
phase: unknown
```

recover:

```text
phase: next_phase_plan_execution
```

### Suggested Fix

Introduce weighted phase inference logic.

### Risk

Low

### Priority

P2

---

## D05 — `/dev-save` should fully close workflow task state

### Problem

After successful `/dev-save`, Claude Code may still show stale internal tasks such as:

```text
Update protocol state for Loop X
```

even though:

* protocol state updated
* checkpoint commit exists
* `/dev-status` reports drift = none

### Why Deferred

No repository corruption occurs, but workflow completion feels ambiguous.

Observed after Loop 7.

### Desired Outcome

Successful `/dev-save` should imply:

* checkpoint complete
* protocol task resolved
* no stale pending workflow task remains

### Suggested Fix

Explicitly finalize protocol task state during `/dev-save`.

### Risk

Low

### Priority

P3

---

## D06 — Constants coverage audit

### Problem

After repeated implementation loops, duplicated literals may gradually reappear.

Examples:

* thresholds
* retry intervals
* timeout values
* repeated action names
* status literals

### Why Deferred

Loop 7 introduced centralized constants, but no protection against future drift exists.

### Desired Outcome

Periodic audit command or validation ensuring:

* no duplicated thresholds
* no repeated timeout literals
* no status string drift
* no duplicated event action names

### Suggested Fix

Add grep-based or AST-based audit.

Example:

```text
/dev-audit-constants
```

### Risk

Low

### Priority

P3

---

## D07 — Planning workflow should support "verification loops"

### Problem

Some loops conclude with:

```text
behavior already correct
```

(no implementation required)

Current workflow supports this operationally, but planning semantics remain implementation-oriented.

### Why Deferred

No blocker exists, but planning language still assumes "fix/change" loops.

Observed during:

* CLARIFY_REWRITE verification
* API audit loop

### Desired Outcome

Planning workflow explicitly recognizes:

```text
validation loop
verification loop
no-op success
```

as first-class workflow outcomes.

### Suggested Fix

Extend planning conventions and loop classification.

### Risk

Low

### Priority

P3

---

## D08 — Protocol documentation split needs clarification

### Problem

Two documentation locations currently exist:

```text
.agents/dev-protocol/docs/
docs/
```

causing ambiguity about source of truth.

### Why Deferred

Current usage works, but future maintenance may diverge.

### Desired Outcome

Clearly define:

* authoritative runtime docs
* public documentation
* synchronization rules

### Suggested Fix

Document ownership boundaries or consolidate.

### Risk

Low

### Priority

P3

---

## D09 — Workflow checkpoint semantics should become explicit

### Problem

Checkpoint commits currently rely on naming conventions such as:

```text
chore(protocol):
chore(checkpoint):
```

to infer protocol state.

### Why Deferred

Detection works after fixes, but remains convention-dependent.

### Desired Outcome

Protocol commits become structurally identifiable independent of wording.

### Suggested Fix

Introduce explicit protocol metadata marker.

Example:

```text
[protocol-checkpoint]
```

or structured commit annotation.

### Risk

Low

### Priority

P4

---

## D10 — Cross-runtime hook lifecycle compatibility

### Problem

Stop hook lifecycle termination has been verified for Claude Code only.

Other runtimes (Cursor, Trae, Roo, custom agents) may have different hook semantics or lack equivalent cleanup mechanisms.

### Why Deferred

Claude Code is the reference runtime. Other runtime integrations are future work.

No immediate breakage risk — protocol core does not depend on hooks.

### Desired Outcome

Verify or document equivalent hook cleanup semantics for each supported runtime.

If a runtime does not support equivalent hooks, document the limitation and provide fallback behavior.

### Suggested Fix

Per-runtime adapter validation:

- Cursor: verify extension unload behavior
- Trae: verify lifecycle hooks
- Roo: verify task termination
- Manual: document that hook validation is optional

### Risk

Low

### Priority

P3

---

## D11 — Formalize /goal as first-class skill or deprecate into /dev-scope

### Problem

`/goal` is documented in `docs/command-contracts.md` but has no `skills/goal/` directory, no PROMPT.md, and no SKILL.md. It is the only canonical command without a skill definition. This creates inconsistent skill structure.

### Why Deferred

Current workflow works correctly. `/goal` is executed as an implementation phase after `/dev-scope`, and its behavior is well-documented in command contracts. This is architectural cleanup, not a v1.0 blocker.

### Desired Outcome

Either:
1. Create `skills/goal/PROMPT.md` and `SKILL.md` with full execution semantics, OR
2. Officially merge `/goal` into `/dev-scope` auto-execution and remove `/goal` as a standalone command

### Suggested Fix

Create `skills/goal/` with PROMPT.md and SKILL.md defining:
- Scope consumption
- Implementation boundaries
- Normal commit creation
- Goal-output artifact production
- Validation criteria verification

### Risk

Low

### Priority

P2

---

## D12 — Structured project audit command

### Problem

Current workflow still requires large manual prompts for:

* project understanding
* architecture review
* roadmap/progress evaluation
* testing assessment
* optimization recommendations

### Why Deferred

No protocol failure caused by missing audit command. Manual prompts work. This is a workflow compression opportunity, not a correctness gap.

### Desired Outcome

Canonical command replacing ad-hoc prompts like:

"结合当前项目既定目标与实际进度进行全面系统检查..."

Two-stage model:

1. **Context reconstruction**
   * understand project goal
   * roadmap
   * defer
   * architecture
   * tests
   * recent progress

2. **Structured review report**
   * goal alignment
   * architecture
   * testing
   * maintainability
   * documentation
   * prioritized recommendations

### Desired Workflow

```text
/dev-audit
```

### Risk

Low

### Priority

P2

---

## D13 — Rename repository default branch master → main

### Problem

Default branch is `master`. Modern convention is `main`.

### Why Deferred

No correctness benefit during v1.0 freeze. Avoid workflow churn while protocol stabilizes.

### Desired Outcome

Rename default branch after v1.0 freeze.

Includes:

* git branch rename
* remote migration
* docs/scripts update

### Risk

Low

### Priority

P3
