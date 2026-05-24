# Commit Rules

## Principle

Commits must be structured, concise, and recoverable.

A commit should explain:

- what changed
- why it changed
- current development intent

---

## Format

<type>(<scope>): <summary>

Examples:

feat(protocol): add checkpoint validation
fix(workflow): repair recovery state
refactor(memory): simplify handoff generation
docs(sync): update architecture notes
chore(checkpoint): refresh workflow state

---

## Allowed Types

- feat
- fix
- refactor
- docs
- test
- chore

---

## Scope Rules

Prefer:

- protocol
- bootstrap
- resume
- checkpoint
- workflow
- memory
- sync
- hooks

Project-specific scope is allowed.

---

## Summary Rules

Must:

- use present tense
- be concise
- describe actual change

Avoid:

- vague wording
- generic summaries

Bad:

update files

Good:

update workflow recovery logic

---

## Checkpoint Rule

Checkpoint operations should generate commit messages automatically.

In Claude Code, `/dev-checkpoint` generates the message. In manual mode, the operator
or a script must infer:

- dominant change
- correct type
- scope
- concise summary

---

## Failure Rules

Commit fails if:

- message format invalid
- change scope unclear
- summary too vague
