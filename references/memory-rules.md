# Protocol Memory Rules

## Purpose

Protocol memory exists so any session can resume work without prior chat history.

It replaces "scroll back and remember" with "read a file and know."

---

## "State Over History" Principle

Never rely on chat history, git log narratives, or mental context to understand
where work left off. The three state files in `.agents/dev-protocol/` are the
single source of truth. If chat history says one thing and `workflow-state.yml`
says another, trust the state file.

**Why:** Chat history is ephemeral. A new session has zero access to prior
conversation. State files are durable across sessions, machines, and time gaps.

---

## State File Roles

| File | Purpose | Update Frequency |
|---|---|---|
| `workflow-state.yml` | Machine-readable progress, phase, checkpoint metadata | Every `/dev-checkpoint` |
| `handoff.md` | Human-readable current focus, blockers, context | Every `/dev-checkpoint` |
| `project-rules.md` | Stable project conventions, constraints, decisions | Only when rules change |

**Example:** `workflow-state.yml` says `phase: "p2"` and `progress.completed` lists
20 items. `handoff.md` explains *why* phase is p2 and what "populate placeholders"
means in practice. `project-rules.md` defines *how* commits must be formatted — a
rule that doesn't change between checkpoints.

---

## How `/dev-resume` Uses Memory

1. Reads `workflow-state.yml` for phase, completed items, in-progress items
2. Reads `handoff.md` for human-readable context and blockers
3. Reads `project-rules.md` for stable conventions
4. Compares state against repository reality (git status, recent commits)
5. Generates recovery summary: current phase, active focus, completed progress,
   blockers, recommended next actions

If state files are missing, `/dev-resume` fails and recommends `/dev-bootstrap`.

---

## Rules for Keeping Memory Reliable

1. **Update at checkpoint, not continuously.** Memory is batched into
   `/dev-checkpoint` executions. Do not incrementally edit state files during
   a session — that introduces drift between state and actual work.

2. **Completed items must match reality.** If `workflow-state.yml` marks something
   completed but the file doesn't exist or the code isn't there, it's a bug.
   Fix it at the next checkpoint.

3. **Phase transitions are explicit.** Moving from p1 to p2 requires all p1
   deliverables to be done. Never advance phase with incomplete items.

4. **Handoff should be useful to a stranger.** Write `handoff.md` so someone
   who never touched the project can pick up work in under 2 minutes.

5. **Delete stale entries.** If a blocked item is no longer relevant, remove it.
   Accumulated stale data makes the whole file untrustworthy.
