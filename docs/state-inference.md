# State Inference Design

Machine-actionable rules for inferring protocol state when persisted values are stale or missing.

---

## Part 1 — /dev-status Phase Inference

### Problem

`/dev-status` frequently reports `phase: unknown` even when surrounding context is clear.

Current sources of phase information exist but are not used in a defined precedence.

### Phase Inference Precedence

When `workflow-state.yml` contains `phase: unknown` or `phase` is stale, `/dev-status` must infer phase using this strict priority order:

```
1. active roadmap
2. next-phase-plan.md
3. handoff.md
4. workflow-state.yml (persisted phase)
5. fallback: unknown
```

Lower numbers win. If a higher-priority source yields a valid phase, stop. Do not consult lower-priority sources.

### Source Definitions

#### 1. Active Roadmap

Source: `docs/v2-redesign-roadmap.md` or active roadmap file.

Extraction rules:

- Read the "Current Direction" or "Current Phase" section
- If a phase label is explicitly stated, use it
- Valid phase labels: `p0`, `p1`, `p2`, `p3`, `p4`, `stabilization`, `ergonomics`, `robustness`
- If roadmap references a phase code (e.g., "Phase A — Stabilization"), map to `p3`

#### 2. Next-phase-plan

Source: `.agents/dev-protocol/next-phase-plan.md`.

Extraction rules:

- If file exists and contains pending loops, infer phase from loop content
- If loops mention "stabilization", "hardening", "fix": phase = `p3-stabilization`
- If loops mention "ergonomics", "compression", "reduce friction": phase = `p3-ergonomics`
- If loops mention "robustness", "replay", "audit", "deterministic": phase = `p3-robustness`
- If no pending loops but completed loops exist: phase = transition to next phase

#### 3. Handoff

Source: `.agents/dev-protocol/handoff.md`.

Extraction rules:

- Read "Current Focus" section
- If focus contains phase indicator (e.g., "Phase A", "stabilization"), use it
- If focus mentions specific deferred items (D01-D09), map to corresponding phase
- If "Next Recommended Actions" mention stabilization tasks: phase = `p3-stabilization`
- If "Next Recommended Actions" mention ergonomics tasks: phase = `p3-ergonomics`

#### 4. Workflow-state

Source: `.agents/dev-protocol/workflow-state.yml`.

Extraction rules:

- Read `current_state.phase`
- If not `unknown` and `checkpoint.last_commit` matches HEAD or HEAD~1: use persisted phase
- If `checkpoint.last_commit` differs from HEAD by > 2 commits: mark as stale, do not use
- If `unknown`: skip, proceed to fallback

#### 5. Fallback

If no source yields a valid phase:

- Output: `phase: unknown`
- Add note: "Phase could not be inferred from available context. Run /dev-scope to define current phase or update roadmap."

### Inference Algorithm

```
function inferPhase():
    phase = extractFromRoadmap()
    if phase is valid: return phase

    phase = extractFromNextPhasePlan()
    if phase is valid: return phase

    phase = extractFromHandoff()
    if phase is valid: return phase

    phase = extractFromWorkflowState()
    if phase is valid and not stale: return phase

    return "unknown"
```

### Examples

**Example 1: Roadmap defines phase**

```text
roadmap: "Current Direction: Phase A — Stabilization"
next-phase-plan: missing
handoff: focus = "fix drift detection"
workflow-state: phase = "unknown"
→ inferred phase: p3-stabilization
→ source: roadmap
```

**Example 2: Next-phase-plan defines phase**

```text
roadmap: generic, no phase stated
next-phase-plan: "Loop 1: Reduce /dev-scope → /goal duplication"
handoff: focus = "workflow compression"
workflow-state: phase = "unknown"
→ inferred phase: p3-ergonomics
→ source: next-phase-plan (ergonomics task)
```

**Example 3: Handoff defines phase**

```text
roadmap: generic
next-phase-plan: empty
handoff: focus = "command contract hardening", next actions = "add drift detection"
workflow-state: phase = "unknown"
→ inferred phase: p3-stabilization
→ source: handoff (stabilization language)
```

**Example 4: Persisted phase is current**

```text
roadmap: generic
next-phase-plan: missing
handoff: focus = "continue current work"
workflow-state: phase = "p3", last_commit = HEAD~1
→ inferred phase: p3
→ source: workflow-state (valid and not stale)
```

**Example 5: Nothing available**

```text
roadmap: generic, no phase
next-phase-plan: missing
handoff: focus = "onboarding"
workflow-state: phase = "unknown"
→ inferred phase: unknown
→ source: fallback
→ note: "Phase could not be inferred..."
```

---

## Part 2 — current-focus.md Redundancy Review

### Current State

`current-focus.md` does not exist in the repository.

It is referenced in:

- deferred D04 (phase recovery): "Useful signals already exist: current-focus.md"
- deferred D02 (continue loop): "Sources: next-phase-plan.md, current-focus.md, recent completed loops"

### Analysis

If `current-focus.md` were introduced, it would overlap with:

| File | Overlap | Unique Value |
|------|---------|-------------|
| `handoff.md` "Current Focus" section | Same information, different format | `handoff.md` is human-readable narrative |
| `workflow-state.yml` `current_state.focus` | Same information, structured | `workflow-state.yml` is machine-readable |

No unique value exists for `current-focus.md` that is not already covered by `handoff.md` and `workflow-state.yml`.

### Recommendation

**Do not introduce `current-focus.md`.**

Instead:

1. Ensure `handoff.md` "Current Focus" section is always current and detailed
2. Ensure `workflow-state.yml` `current_state.focus` is always synchronized with handoff
3. Use `handoff.md` as the human-readable source
4. Use `workflow-state.yml` as the machine-readable source

### Migration Plan (if current-focus.md exists in future)

If `current-focus.md` is ever created (e.g., by an external tool or manual edit):

1. Read its content
2. Merge into `handoff.md` "Current Focus" section
3. Update `workflow-state.yml` `current_state.focus`
4. Delete `current-focus.md`
5. Run `/dev-save`

### Preventive Rule

Add to `references/workflow-rules.md`:

> `current-focus.md` is not a recognized protocol state file. Focus information belongs in `handoff.md` (human-readable) and `workflow-state.yml` (machine-readable). Agents must not create `current-focus.md`.

---

## Part 3 — Immediate Implementations

1. **Update `/dev-status` skill prompt** — Add phase inference algorithm with 5-step precedence. Modify `skills/dev-status/PROMPT.md` STEP 4 to include inference logic before falling back to persisted `phase`.

2. **Update `references/workflow-rules.md`** — Add preventive rule against `current-focus.md`. Document that focus information belongs exclusively in `handoff.md` and `workflow-state.yml`.

3. **Update `/dev-scope` skill prompt** — Add auto-execution criteria. Modify `skills/dev-scope/PROMPT.md` to detect simple scopes (≤ 3 files, no API changes) and auto-execute without requiring separate `/goal`.

4. **Create `next-phase-plan.md` template** — Add `templates/next-phase-plan.md` with the structure required for `continue loop`. Include example loops and status fields.

5. **Update `skills/dev-save/PROMPT.md`** — Add self-drift detection for no-op saves. When only state files changed and source is clean, early-exit without creating redundant commit.
