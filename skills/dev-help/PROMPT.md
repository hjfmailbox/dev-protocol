You are executing /dev-help.

Your goal is to display a concise, actionable reference for dev-protocol usage.

---

## STEP 1: Display Reference

Output the following sections exactly:

---

### dev-protocol — Quick Reference

#### Commands

| Command | Writes? | Purpose |
|---------|:-------:|---------|
| `/dev-bootstrap` | Yes | Initialize protocol on a project. Reconstructs state. No auto-commit. |
| `/dev-checkpoint` | Yes | Persist state, validate, commit. Safe to `/clear` after. |
| `/dev-resume` | No | Recover context from state files. Read-only. |
| `/dev-goal-template` | No | Generate a standardized goal template for `/goal`. |
| `/dev-doctor` | No | Diagnose protocol health. Read-only. |
| `/dev-help` | No | This reference. |

#### Typical Lifecycle

**First time:**
```
/dev-bootstrap → review state → commit → /dev-checkpoint
```

**Daily:**
```
/dev-resume → /goal <task> → implement → /dev-checkpoint → /clear
```

**Recovery:**
```
/clear → /dev-resume → continue working
```

#### Command Order

1. `/dev-bootstrap` — first on any new project
2. `/dev-resume` — after `/clear` or new session (needs state files)
3. `/goal` — after resume, before implementation
4. `/dev-checkpoint` — after meaningful changes, before `/clear`

#### Common Mistakes

| Mistake | Fix |
|---------|-----|
| `/dev-checkpoint` without `/dev-bootstrap` | Run `/dev-bootstrap` first |
| `/dev-resume` with no state files | Run `/dev-bootstrap` first |
| `/dev-checkpoint` produces no commit | Normal — no changes since last checkpoint (self-drift) |
| Forgot `/dev-checkpoint` before `/clear` | Run `/dev-resume`; uncheckpointed work may need redo |
| Dirty workspace blocks checkpoint | Commit or stash, then retry checkpoint |
| Re-running `/dev-bootstrap` on initialized project | Safe — updates state, does not overwrite |

#### State Files

Location: `.agents/dev-protocol/`

| File | Purpose |
|------|---------|
| `workflow-state.yml` | Progress, phase, checkpoint metadata |
| `handoff.md` | Session handoff with focus and next actions |
| `project-rules.md` | Project constraints and known pitfalls |

#### More Information

- `/dev-doctor` — diagnose issues
- `docs/` — design documents
- `references/` — protocol rules
- `README.md` — project overview

---

## RULES

- NEVER modify files
- NEVER commit
- NEVER diagnose (use /dev-doctor for that)
- Output the reference once, then stop
