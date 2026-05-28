# State File Simplification Proposal

Analysis of current state file footprint and redundancy.

## Current State Files

All files live in `.agents/dev-protocol/`:

| File | Purpose | Format |
|------|---------|--------|
| `workflow-state.yml` | Machine-readable progress, phase, persistence metadata | YAML |
| `handoff.md` | Human-readable session handoff with current focus and next actions | Markdown |
| `project-rules.md` | Project-specific constraints, coding standards, known pitfalls | Markdown |

## Files Referenced but Not Present

The following files are referenced in deferred items and skills but do not currently exist:

| File | Referenced By | Purpose |
|------|---------------|---------|
| `current-focus.md` | D04 (phase recovery) | Explicit current focus document |
| `next-phase-plan.md` | D02 (continue loop) | Planned execution document |

These are **proposed** files, not current files.

## Redundancy Analysis

### workflow-state.yml vs handoff.md

**Overlap areas**:

- Phase information exists in both
- Focus exists in both (machine-readable vs human-readable)
- Progress/completed tasks exist in both
- Next actions exist in both

**Divergence risk**:

- `workflow-state.yml` updated by `/dev-save`
- `handoff.md` updated by `/dev-save`
- Both contain overlapping but not identical information
- Risk of inconsistency if one is updated without the other

**Current mitigation**:

- `/dev-save` updates both files atomically
- No evidence of drift between the two in current usage

### project-rules.md

**Unique role**:

- Contains constraints not present in other state files
- Project-specific rules, coding standards, known pitfalls
- No overlap with workflow-state.yml or handoff.md

**Assessment**: Not redundant. Should be preserved.

## Proposed current-focus.md

If `current-focus.md` is introduced (per deferred D04):

**Question**: Does it duplicate `handoff.md` "Current Focus" section?

**Analysis**:

- `handoff.md` focus is human-readable narrative
- `current-focus.md` would be machine-readable structured data
- Similar information, different consumers (human vs agent)

**Recommendation**: If introduced, keep both. `current-focus.md` as structured input for `/dev-status` phase inference. `handoff.md` as human-readable narrative.

## Proposed next-phase-plan.md

If `next-phase-plan.md` is introduced (per deferred D02):

**Question**: Does it duplicate `workflow-state.yml` `next.recommended_actions`?

**Analysis**:

- `workflow-state.yml` next actions are brief strings
- `next-phase-plan.md` would contain detailed planned execution steps
- Different granularity

**Recommendation**: If introduced, keep both. `workflow-state.yml` for machine-readable pointers. `next-phase-plan.md` for detailed planning document.

## Recommendation

### Short term (no new files)

Keep current three-file structure. It is working and has no demonstrated drift.

### Medium term (if introducing planned execution)

If `current-focus.md` and `next-phase-plan.md` are introduced:

- Keep all five files
- Document ownership: what goes where
- Update `/dev-save` to update all five atomically

### Long term (consolidation opportunity)

If drift between `workflow-state.yml` and `handoff.md` becomes a problem:

- Option 1: Merge `workflow-state.yml` into `handoff.md` as a YAML frontmatter block
- Option 2: Keep separate but add validation rule: `handoff.md` must match `workflow-state.yml` on phase and focus
- Option 3: Generate `handoff.md` from `workflow-state.yml` (single source of truth)

**Current recommendation**: No action. Three-file structure is stable. Introduce new files only when deferred D02 and D04 are implemented.
