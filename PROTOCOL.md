# Dev Protocol v1

## Goal

Enable recoverable development sessions.

After `/dev-checkpoint`, a developer or agent should be able to:

- clear chat context safely
- start a new session with `/dev-resume`
- continue development without relying on prior conversation

---

## Commands

### /dev-bootstrap

Initialize protocol on an existing project.

Responsibilities:

- inspect project
- reconstruct current state
- initialize memory
- generate workflow state
- detect document drift

Does NOT auto-commit.

---

### /dev-resume

Recover development context.

Responsibilities:

- read workflow state
- read handoff
- read project rules
- inspect git status
- summarize current development state

---

### /dev-checkpoint

Persist development state.

Responsibilities:

- inspect changes
- sync memory
- sync docs
- update workflow state
- validate consistency
- commit with required format

Must fail if validation fails.

---

## Design Principles

1. State over history
2. Recoverable without chat history
3. Fail over partial success
4. LLM for reasoning, scripts for enforcement
5. Protocol logic must be reusable across projects
