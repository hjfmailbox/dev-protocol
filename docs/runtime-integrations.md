# Runtime Integrations

dev-protocol is a **runtime-agnostic** development workflow protocol. It can be used with Claude Code, Cursor, GitHub Copilot, custom agents, or any future orchestrator that can read and write files and execute shell commands.

This document explains how dev-protocol integrates with specific runtimes and what is required when a runtime does not provide automation hooks.

---

## Architecture

```
+---------------------------------------------------------+
|                    dev-protocol Core                     |
|  (portable, runtime-agnostic)                           |
|  - State files (.agents/dev-protocol/)                  |
|  - Deterministic scripts (scripts/)                     |
|  - Validation tests (tests/)                            |
|  - Design documents (docs/, references/)                |
+---------------------------------------------------------+
                          ^
                          |
+---------------------------------------------------------+
|              Optional Runtime Adapters                   |
|  - Claude Code: .claude/settings.json + hooks           |
|  - Cursor: (future) .cursor/ or plugin                  |
|  - Copilot: (future) VS Code extension                  |
|  - Manual: direct script invocation                     |
+---------------------------------------------------------+
```

**Protocol correctness is guaranteed by the core.** Runtime adapters are convenience automation only.

---

## Claude Code Integration

Claude Code is the reference runtime. Integration uses the `.claude/` directory, which Claude Code discovers automatically.

### What the Stop Hook Does

The Stop hook (configured in `.claude/settings.json`) runs when a Claude Code session ends. It:

1. **Normalizes** the goal-output artifact by calling `scripts/fix-goal-output.ps1`
2. **Validates** the normalized artifact against the goal-output contract
3. **Blocks** session stopping if validation fails (forcing repair before exit)

This prevents the common failure mode where an LLM generates a goal-output artifact with schema drift (e.g., `validation_results` as a string instead of an array) and the session stops with a validation error.

### Why the Stop Hook is Optional

The Stop hook is **convenience automation**, not a protocol requirement. All of its behavior can be replicated manually:

| Hook Behavior | Manual Equivalent |
|---|---|
| Normalize artifact | Run `pwsh scripts/fix-goal-output.ps1` |
| Validate artifact | Read `.agents/dev-protocol/goal-output.json` and check schema |
| Block on failure | Do not mark goal complete until artifact is valid |

**Without the Stop hook:**

- Protocol still works
- `scripts/fix-goal-output.ps1` still repairs artifacts
- `tests/run-tests.ps1 06` still validates goal completion
- The only difference is the agent must remember to run the fix script before declaring completion

### Claude-Specific Assets

| Path | Purpose | Required? |
|---|---|---|
| `.claude/settings.json` | Stop hook configuration | No |
| `.claude/hooks/stop-hook.ps1` | Normalization + validation hook | No |
| `.claude/skills/` | Symlinks to `skills/` for Claude discovery | No (skills work without symlinks) |

These files are tracked in git for convenience but are **not** part of the protocol contract.

---

## Non-Hook Environments

Any environment that can execute PowerShell or Bash can use dev-protocol without hooks.

### Minimal Manual Fallback Workflow

1. **Bootstrap** — Create state files manually or run a script:
   ```powershell
   # Inspect project structure, create .agents/dev-protocol/*
   # Or use the dev-bootstrap skill logic directly
   ```

2. **Goal work** — Implement changes within a scoped objective.

3. **Normalize artifact** — Before declaring completion, always run:
   ```powershell
   pwsh scripts/fix-goal-output.ps1
   ```
   This repairs `changed_files` and schema automatically.

4. **Validate** — Run case-06:
   ```powershell
   pwsh tests/run-tests.ps1 -Case 06
   ```

5. **Checkpoint** — Commit state files and goal artifact:
   ```bash
   git add .
   git commit -m "chore(checkpoint): describe change"
   ```

6. **Resume** — In a new session, read state files to recover context.

### Key Difference from Hook Mode

In hook mode, normalization happens automatically on session stop. In manual mode, the operator must run `fix-goal-output.ps1` explicitly before completing a goal. The protocol behavior is identical; only the trigger mechanism changes.

---

## Semantic Operations (Runtime Mapping)

dev-protocol defines semantic operations. Each runtime maps them to its own interaction model:

| Protocol Semantic | Claude Code | Cursor | Manual / Other |
|---|---|---|---|
| Bootstrap | `/dev-bootstrap` | Custom command or plugin | Run bootstrap logic manually |
| Checkpoint | `/dev-checkpoint` | Custom command or plugin | `git add . && git commit` + state update |
| Resume | `/dev-resume` | Custom command or plugin | Read `.agents/dev-protocol/handoff.md` |
| Goal | `/goal` | AI chat with structured output | Write scope document, execute, write goal-output |
| Doctor | `/dev-doctor` | Custom command or plugin | Run validation scripts manually |
| Help | `/dev-help` | Documentation panel | Read `docs/` and `references/` |

The slash commands are **Claude Code's representation** of the protocol semantics. They are not the protocol itself.

---

## Future Runtime Adapters

To add a new runtime adapter:

1. Create a directory for runtime-specific configuration (e.g., `.cursor/`, `integrations/vscode/`)
2. Map protocol semantics to the runtime's interaction model
3. Optionally provide automation hooks if the runtime supports them
4. Document the integration in this file

**Do not** place runtime-specific logic in the protocol core (`scripts/fix-goal-output.ps1`, `tests/`, `.agents/`). The core must remain portable.
