# Deferred Improvements

> Only unresolved improvements with demonstrated workflow value remain here.
> Completed items are removed rather than archived.

---

## D01 — Reduce `/dev-scope` → `/goal` duplication

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

## D02 — Continuous loop execution from plan

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
