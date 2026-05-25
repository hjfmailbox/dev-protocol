# External Benchmark: dev-protocol v2 vs. Existing Workflow Systems

Research conducted before freezing v2 protocol surface.

**Scope**: Analysis only. No redesign, no implementation changes, no command surface modifications.

---

## 1. Research Method

Searched 7 categories across 2024–2026 literature and repositories:

- Claude Code workflow harnesses
- Claude Code skills / slash-command repos
- Spec-driven development workflows
- Long-running agent orchestration
- Checkpoint / context recovery systems
- Onboarding / init workflows
- State persistence patterns

Selected 7 candidate systems for detailed comparison based on relevance to dev-protocol's problem domain (session-resilient AI-assisted development workflows).

---

## 2. Candidate Systems

### 2.1 ECC — Agent Harness Performance Optimization System

**Source**: [github.com/affaan-m/ecc](https://github.com/affaan-m/ecc)

**What it is**: A cross-harness operator system supporting Claude Code, Codex, Cursor, OpenCode, Gemini, Zed, and Copilot. 60 agents, 232 skills, 75 legacy command shims. Hook-based automation with SQLite state store and Rust control-plane prototype.

**Strengths**:
- Genuine cross-harness support with per-target configs (`.claude/`, `.cursor/`, `.codex/`, etc.)
- DRY Adapter Pattern for hook reuse across runtimes
- SQLite state store with CLI query interface
- Session lifecycle hooks (load on start, save on end)
- `/checkpoint` command with `/loop-status` inspection
- AgentShield security scanner (1282 tests, 98% coverage)
- Instinct-based continuous learning with confidence scoring

**Weaknesses**:
- Complex installer with strict mutual-exclusion rules ("Do not stack install methods")
- 232 skills create enormous surface area; discoverability problem
- Heavyweight: requires Node.js runtime, plugin manifests, MCP configs
- Control plane (`ecc2/`) is alpha Rust prototype
- Hook profile system (`minimal|standard|strict`) adds cognitive load

**Comparison to dev-protocol**:

| Dimension | Classification | Notes |
|-----------|----------------|-------|
| Onboarding flow | **Solved better externally** | ECC has multiple entry points (`/plugin`, `install.sh`, `npx`) with advisor (`npx ecc consult`). dev-protocol has `/dev-init` only. |
| State reconstruction | **Partially solved** | ECC has SQLite + hooks + `/checkpoint`. dev-protocol has YAML + Markdown files. ECC's store is queryable; dev-protocol's is human-readable. |
| Save/checkpoint semantics | **Partially solved** | ECC has `/checkpoint` and `/loop-status`. dev-protocol has `/dev-save` + `case-05`/`case-06` validation. ECC does not validate consistency against git. |
| Command surface simplicity | **Intentionally different** | ECC: 232 skills. dev-protocol: 4 commands. ECC targets power users; dev-protocol targets minimal mental model. |
| Portability beyond Claude | **Solved better externally** | ECC explicitly supports 7+ harnesses. dev-protocol is runtime-agnostic in principle but only tested with Claude Code. |
| Protocol/runtime separation | **Intentionally different** | ECC has deep runtime integration (hooks, plugins, MCPs). dev-protocol separates protocol core from optional `.claude/` adapter. |
| Hooks usage | **Solved better externally** | ECC has comprehensive hook system (session lifecycle, tool interception, compaction). dev-protocol has optional stop hook only. |

**Verdict**: ECC solves cross-harness portability and hook automation better than dev-protocol. However, its complexity (232 skills, plugin manifests, installer conflicts) is the exact opposite of dev-protocol's design goal. Worth observing: the SQLite state store and `/checkpoint` command are conceptually similar to dev-protocol's state files, but ECC does not validate checkpoint consistency against repository reality.

---

### 2.2 Superpowers (obra/superpowers)

**Source**: [lobehub.com/skills/obra-superpowers-agentic-workflow](https://lobehub.com/skills/obra-superpowers-agentic-workflow)

**What it is**: A cross-harness mandatory-workflow skills framework. Zero executable code — pure Markdown `SKILL.md` documents that inject behavioral instructions into agent sessions. Enforces 7-phase development cycle: Brainstorm → Spec → Plan → TDD → Subagent Development → Review → Finalize.

**Strengths**:
- True cross-harness: works on Claude Code, Codex, Cursor, OpenCode, Gemini CLI, Goose CLI
- Zero runtime dependency — skills are plain Markdown
- Mandatory enforcement philosophy prevents agents from skipping workflows
- Deep TDD integration (RED-GREEN-REFACTOR)
- Git worktree support for isolated parallel branches
- Subagent-driven development with two-stage review

**Weaknesses**:
- Enforcement depends on agent compliance, not executable checks
- No persistent state management — skills live in context, not on disk
- No checkpoint or recovery mechanism beyond "follow the skill"
- No onboarding flow — assumes project already configured
- 7-phase cycle is rigid; small tasks feel heavy

**Comparison to dev-protocol**:

| Dimension | Classification | Notes |
|-----------|----------------|-------|
| Onboarding flow | **Not addressed** | Superpowers has no init/onboarding concept. dev-protocol has `/dev-init`. |
| State reconstruction | **Not addressed** | Superpowers is stateless. dev-protocol persists state to `.agents/dev-protocol/`. |
| Save/checkpoint semantics | **Not addressed** | No checkpoint mechanism. dev-protocol has `/dev-save` with validation. |
| Command surface simplicity | **Intentionally different** | Superpowers: 20+ skills. dev-protocol: 4 commands. Different philosophies. |
| Portability beyond Claude | **Solved better externally** | Superpowers is inherently portable (Markdown). dev-protocol claims portability but lacks validation. |
| Protocol/runtime separation | **Solved better externally** | Superpowers has no runtime code to separate. It *is* the protocol. dev-protocol has `.claude/` adapter. |
| Hooks usage | **Not addressed** | No hooks. Pure prompt engineering. |

**Verdict**: Superpowers is the closest conceptual competitor. Both systems try to constrain agent behavior through structured protocols. Superpowers does this via mandatory skills; dev-protocol does it via state files and validation tests. Superpowers has no persistence, which is dev-protocol's core differentiator. The TDD enforcement in Superpowers is stronger than anything in dev-protocol. Worth copying: the mandatory-skill philosophy ("IF A SKILL APPLIES, YOU MUST USE IT") could strengthen dev-protocol skill adherence.

---

### 2.3 GitHub Spec Kit

**Source**: [github.com/github/spec-kit](https://github.com/github/spec-kit)

**What it is**: A spec-driven development (SDD) toolkit. 7-stage gated workflow: Constitution → Specify → Clarify → Plan → Tasks → Analyze → Implement. Generates linked Markdown artifacts (`spec.md`, `plan.md`, `tasks.md`) as persistent memory.

**Strengths**:
- Spec as executable source of truth — the contract persists across sessions
- Artifacts committed to repo serve as cross-agent memory
- 7-stage gates prevent premature implementation
- Supports 30+ AI coding agents (Copilot, Claude Code, Gemini CLI)
- Community presets (multi-repo branching, git submodules)
- Code reviews validate intent against acceptance criteria

**Weaknesses**:
- Heavy upfront investment — constitution and specification take time
- Not designed for exploratory or iterative work
- No checkpoint mechanism during implementation
- No explicit session recovery — relies on reading artifacts
- Version ~0.8.x; still maturing
- No validation suite — correctness is manual review

**Comparison to dev-protocol**:

| Dimension | Classification | Notes |
|-----------|----------------|-------|
| Onboarding flow | **Partially solved** | Spec Kit assumes project exists and has conventions. dev-protocol's `/dev-init` inspects and reconstructs reality. |
| State reconstruction | **Partially solved** | Spec Kit artifacts provide context. dev-protocol state files provide machine-readable progress + human-readable handoff. |
| Save/checkpoint semantics | **Not addressed** | No checkpoint during implementation. dev-protocol has `/dev-save` at boundaries. |
| Command surface simplicity | **Intentionally different** | Spec Kit: 7 commands for 7 stages. dev-protocol: 4 commands for lifecycle. |
| Portability beyond Claude | **Solved better externally** | Spec Kit supports 30+ agents. dev-protocol is runtime-agnostic but untested beyond Claude. |
| Protocol/runtime separation | **Solved better externally** | Spec Kit is pure protocol (Markdown artifacts). No runtime code at all. |
| Hooks usage | **Not addressed** | No hooks. Workflow is manual skill invocation. |

**Verdict**: Spec Kit and dev-protocol solve different but complementary problems. Spec Kit governs *what* to build; dev-protocol governs *how to resume building it* across sessions. Spec Kit's artifact chain (`spec.md` → `plan.md` → `tasks.md`) is a stronger specification system than dev-protocol's `/dev-scope`. However, Spec Kit has no session recovery mechanism — if a session crashes mid-implementation, the agent must re-read all artifacts and reconstruct context manually. This is exactly the gap dev-protocol fills.

---

### 2.4 LangGraph

**Source**: [langchain.com](https://www.langchain.com), [docs.langchain.com](https://docs.langchain.com)

**What it is**: A graph-based orchestration layer on top of LangChain. Dual persistence: Checkpointers (execution state per thread) and Stores (long-term cross-thread memory). Time-travel debugging, human-in-the-loop, subgraph propagation.

**Strengths**:
- Automatic checkpointing at super-step boundaries
- Immutable checkpoint history enables time-travel debugging
- Crash recovery: any worker can resume from last checkpoint
- Three-tier memory: working (State), cross-thread (checkpointer), long-term (Store)
- Subgraph checkpointer propagation
- Explicit `interrupt_before` / `interrupt_after` for human approval

**Weaknesses**:
- Steep learning curve for state schema design
- No built-in state schema versioning / migration
- Minimal observability without LangSmith
- Tightly coupled to LangChain ecosystem
- `InMemorySaver` loses data on process restart (dev-only)
- State schema changes break persisted checkpoints

**Comparison to dev-protocol**:

| Dimension | Classification | Notes |
|-----------|----------------|-------|
| Onboarding flow | **Not addressed** | LangGraph is a library, not a workflow protocol. No onboarding concept. |
| State reconstruction | **Solved better externally** | Automatic checkpoint restore by `thread_id`. dev-protocol requires manual `/dev-status` invocation. |
| Save/checkpoint semantics | **Solved better externally** | Automatic super-step checkpoints. dev-protocol requires explicit `/dev-save`. |
| Command surface simplicity | **Not addressed** | LangGraph has no command surface — it's a programming framework. |
| Portability beyond Claude | **Not addressed** | LangGraph is runtime-agnostic but code-centric, not chat-centric. |
| Protocol/runtime separation | **Not addressed** | LangGraph *is* runtime code. No protocol layer. |
| Hooks usage | **Not addressed** | No hooks. Event-driven graph execution. |

**Verdict**: LangGraph is a production-grade orchestration framework, not a chat-based development protocol. Its automatic checkpointing is technically superior to dev-protocol's manual `/dev-save`, but the two systems operate at different abstraction levels. LangGraph requires developers to write Python graph code; dev-protocol requires developers to use slash commands. Worth observing: LangGraph's three-tier memory model (working / cross-thread / long-term) maps roughly to dev-protocol's handoff.md (working) + workflow-state.yml (cross-thread) + project-rules.md (long-term), but dev-protocol's separation is implicit, not architectural.

---

### 2.5 wshobson/commands

**Source**: [github.com/wshobson/commands](https://github.com/wshobson/commands)

**What it is**: A collection of 52 production-ready slash commands for Claude Code. Two-tier organization: `workflows/` (15 multi-agent orchestration commands) and `tools/` (42 single-purpose utilities). Includes `context-save` and `context-restore` for state persistence.

**Strengths**:
- Practical, immediately usable commands
- `context-save` / `context-restore` for multi-session projects
- Workflow commands coordinate multiple agent perspectives (backend, frontend, testing, deployment)
- Progressive integration: start with tools, graduate to workflows
- Namespace organization (`/workflows:feature-development`, `/tools:security-scan`)

**Weaknesses**:
- Claude Code only — no portability claims
- `context-save` stores "architecture decisions, configuration snapshots" but no schema or validation
- No consistency checking between saved context and repository reality
- Commands are prompts, not enforced protocols
- No onboarding or init workflow

**Comparison to dev-protocol**:

| Dimension | Classification | Notes |
|-----------|----------------|-------|
| Onboarding flow | **Not addressed** | No init command. dev-protocol has `/dev-init`. |
| State reconstruction | **Partially solved** | `context-restore` reloads saved decisions. dev-protocol has full state file suite with validation. |
| Save/checkpoint semantics | **Partially solved** | `context-save` is manual and unvalidated. dev-protocol has `/dev-save` with `case-05` consistency checks. |
| Command surface simplicity | **Intentionally different** | 52 commands. dev-protocol: 4 commands. wshobson is a toolbox; dev-protocol is a lifecycle. |
| Portability beyond Claude | **Not addressed** | Claude Code only. |
| Protocol/runtime separation | **Not addressed** | Commands live in `.claude/commands/`. No protocol layer. |
| Hooks usage | **Not addressed** | No hooks. |

**Verdict**: wshobson/commands is the most practical existing skill collection for Claude Code developers. Its `context-save`/`context-restore` tools are conceptually similar to dev-protocol's state files, but lack structure, validation, and consistency checks. The workflow commands (`feature-development`, `tdd-cycle`, `incident-response`) show how multi-agent orchestration can be expressed via slash commands. Worth copying: the namespace organization (`workflows/` vs `tools/`) could inform dev-protocol's skill structure, though dev-protocol intentionally keeps a tiny surface.

---

### 2.6 barkain/claude-code-workflow-orchestration

**Source**: [github.com/barkain/claude-code-workflow-orchestration](https://github.com/barkain/claude-code-workflow-orchestration)

**What it is**: A Claude Code plugin for multi-step workflow orchestration. Features automatic task decomposition, parallel agent execution via "waves," and specialized agent delegation with native plan mode integration.

**Strengths**:
- Native plan mode integration (`EnterPlanMode` / `ExitPlanMode`)
- Parallel execution via "waves" — independent phases run concurrently
- Team mode: persistent subagents (`Agent(team_name=...)`) self-coordinate via `SendMessage`
- Sequential fallback when dependencies exist
- Slash command: `/workflow-orchestrator:delegate`

**Weaknesses**:
- Claude Code only
- No persistent state — workflows are ephemeral
- No checkpoint or recovery mechanism
- Requires understanding of wave dependencies
- Overkill for single-developer projects

**Comparison to dev-protocol**:

| Dimension | Classification | Notes |
|-----------|----------------|-------|
| Onboarding flow | **Not addressed** | No init. |
| State reconstruction | **Not addressed** | No persistence. |
| Save/checkpoint semantics | **Not addressed** | No checkpoints. |
| Command surface simplicity | **Not addressed** | Single command `/workflow-orchestrator:delegate` but complex internal model. |
| Portability beyond Claude | **Not addressed** | Claude Code only. |
| Protocol/runtime separation | **Not addressed** | Plugin-based. Deep Claude integration. |
| Hooks usage | **Not addressed** | No hooks. |

**Verdict**: This is an orchestration plugin, not a development protocol. Its parallel wave execution is interesting but irrelevant to dev-protocol's single-agent, session-resilient design. No lessons to copy.

---

### 2.7 Microsoft Agent Framework

**Source**: [diagrid.io blog critique](https://www.diagrid.io/blog/still-not-durable-how-microsoft-agent-framework-and-strands-agents-repeat-the-same-mistake)

**What it is**: Microsoft's unified agent framework (merger of AutoGen and Semantic Kernel). Provides Checkpoint Manager interface for superstep-based state persistence. Azure Durable Task Extension available separately for true durable execution.

**Strengths**:
- Native Checkpoint Manager with Cosmos DB / PostgreSQL backends
- Superstep checkpoint boundaries (Pregel model)
- Enterprise integration with Azure services
- Explicit `Checkpoint Manager` interface

**Weaknesses**:
- Checkpoints are storage, not reliability guarantees
- No automatic failure detection or auto-resume
- No distributed execution (Azure only)
- Pre-merger AutoGen left persistence to application layer
- Requires custom engineering for production durability

**Comparison to dev-protocol**:

| Dimension | Classification | Notes |
|-----------|----------------|-------|
| Onboarding flow | **Not addressed** | Framework library, not a workflow protocol. |
| State reconstruction | **Solved better externally** | Automatic checkpoint restore by thread. dev-protocol is manual. |
| Save/checkpoint semantics | **Partially solved** | Framework provides storage interface. Developer must implement validation and consistency. dev-protocol includes `case-05`/`case-06`. |
| Command surface simplicity | **Not addressed** | No command surface. Code API. |
| Portability beyond Claude | **Not addressed** | Azure-centric. |
| Protocol/runtime separation | **Not addressed** | Deep framework integration. |
| Hooks usage | **Not addressed** | No hooks. |

**Verdict**: Microsoft Agent Framework is an enterprise code framework, not a chat-based development protocol. Its Checkpoint Manager is technically more robust than dev-protocol's file-based state, but it requires developers to write orchestration code around it. The critique that "checkpoints are storage, not reliability guarantees" is directly relevant to dev-protocol: `case-05` and `case-06` exist precisely to turn storage into reliability guarantees.

---

## 3. Cross-Dimension Comparison Matrix

| System | Onboarding | State Recon | Save/Checkpoint | Cmd Surface | Portability | Proto/Runtime | Hooks |
|--------|------------|-------------|-----------------|-------------|-------------|---------------|-------|
| **dev-protocol** | `/dev-init` (inspect + reconstruct) | YAML + MD files, manual `/dev-status` | `/dev-save` + `case-05`/`case-06` validation | 4 commands | Claimed, untested | Clean separation | Optional stop hook only |
| **ECC** | Multiple paths + advisor | SQLite + hooks + `/checkpoint` | `/checkpoint` + `/loop-status` | 232 skills | 7+ harnesses | Deep integration | Comprehensive |
| **Superpowers** | None | None (stateless) | None | 20+ skills | 7+ harnesses | No runtime code | None |
| **Spec Kit** | None | Artifact chain (spec/plan/tasks) | None | 7 stage commands | 30+ agents | Pure protocol | None |
| **LangGraph** | None | Automatic by `thread_id` | Automatic super-step | Code API | Library-level | Code framework | None |
| **wshobson** | None | `context-restore` | `context-save` | 52 commands | Claude only | Commands only | None |
| **barkain** | None | None | None | 1 command | Claude only | Plugin | None |
| **Microsoft** | None | Automatic by thread | Checkpoint Manager | Code API | Azure-centric | Framework | None |

---

## 4. What dev-protocol Already Does Better

### 4.1 Validation Suite

No evaluated system has an equivalent to `case-05`/`case-06`. ECC has `/checkpoint` but no validation. LangGraph has automatic checkpoints but no correctness checks. Microsoft has Checkpoint Manager but no reliability guarantees. dev-protocol's explicit validation (`last_commit` matches `HEAD~1`, changed_files match git diff-tree, commit format enforcement) turns storage into a reliability contract.

### 4.2 Human-Readable State

ECC uses SQLite (queryable but opaque). LangGraph uses serialized graph state (opaque). Superpowers is stateless. dev-protocol's `handoff.md` is designed so "someone who never touched the project can pick up work in under 2 minutes." This is unique among evaluated systems.

### 4.3 Explicit Phase and Progress

No evaluated system tracks project phase and completed items in a machine-readable format. Spec Kit tracks task completion within a single spec, but not across the project lifecycle. dev-protocol's `workflow-state.yml` explicitly records `phase`, `progress.completed`, and `progress.in_progress`.

### 4.4 Protocol/Runtime Separation

Only dev-protocol explicitly separates protocol core (state files, scripts, docs) from runtime adapter (`.claude/`). ECC has per-harness configs but no clear boundary. Superpowers has no runtime to separate. LangGraph *is* runtime. This separation makes dev-protocol correct even without Claude Code installed.

### 4.5 Simplicity

4 commands vs. 232 skills (ECC), 52 commands (wshobson), 7 stages (Spec Kit), graph API (LangGraph). For solo developers or small teams, dev-protocol's mental model is significantly lighter.

---

## 5. Risks in Current Architecture

### 5.1 Portability Claims Untested

dev-protocol claims runtime-agnosticism but has only been validated with Claude Code. The `.claude/skills/` symlinks and `.agents/` convention are theoretically portable, but no Cursor, Copilot, or manual workflow has actually exercised them.

**Mitigation**: R5 real-project validation should include at least one non-Claude runtime.

### 5.2 Manual Save is a Reliability Gap

LangGraph and Microsoft Framework checkpoint automatically. dev-protocol requires explicit `/dev-save` invocation. If a developer forgets to save before a session ends, state drifts. This is the exact problem the protocol is trying to solve — but it depends on human discipline.

**Mitigation**: The stop hook auto-runs validation, but does not auto-save. Consider whether auto-save (with drift detection) is worth adding post-v2.

### 5.3 Phase Detection is Weak

dev-protocol's `/dev-init` defaults to `phase: unknown` — safe but unhelpful. `/dev-status` does not cross-check phase against git history (deferred #14). ECC's instinct-based learning and LangGraph's graph state both provide richer maturity signals.

**Mitigation**: R3 State Reconciliation must fix phase drift before real-project validation.

### 5.4 No Subagent or Parallelism Support

All evaluated systems except Superpowers and wshobson support some form of multi-agent or parallel execution. dev-protocol is explicitly single-agent. This is a deliberate v2 scope limit, but it may become a competitive disadvantage as multi-agent workflows mature.

**Mitigation**: Document as out-of-scope for v2. Revisit in v3 if real-project feedback demands it.

### 5.5 Hooks Are Underutilized

ECC has session lifecycle hooks, tool interception hooks, compaction hooks. dev-protocol has one optional stop hook. The protocol could benefit from a start hook (auto-run `/dev-status` on session start) without compromising runtime agnosticism.

**Mitigation**: Consider a `.claude/hooks/start-hook.ps1` for v2.1.

---

## 6. Opportunities to Simplify

### 6.1 Merge `case-05` and `case-06`

The two-test validation sequence (`case-06` before save, `case-05` after save) is a recurring friction point. LangGraph's automatic checkpointing eliminates this category of problem entirely. While dev-protocol cannot auto-checkpoint (it requires git commits), a unified `case-all` test that understands the save boundary could reduce cognitive load.

**Assessment**: Worth exploring post-v2. Not a v2 blocker.

### 6.2 Replace YAML with a More Readable Format

`workflow-state.yml` is machine-readable but requires YAML knowledge. ECC's SQLite is queryable but opaque. A TOML or simple INI format might be more approachable for manual editing. However, YAML is standard and well-supported.

**Assessment**: Not worth changing. YAML is fine.

### 6.3 Adopt Superpowers' Mandatory-Skill Philosophy

dev-protocol skills describe what *should* happen, but the agent can rationalize around them. Superpowers explicitly forbids this: "IF A SKILL APPLIES, YOU MUST USE IT." Adding this language to dev-protocol skill prompts could improve adherence without changing behavior.

**Assessment**: Zero-cost improvement. Add to all skill PROMPT.md files.

### 6.4 Adopt Spec Kit's Artifact Chain for `/dev-scope`

Spec Kit's `spec.md` → `plan.md` → `tasks.md` chain is richer than dev-protocol's single goal-output artifact. `/dev-scope` could generate a `scope.md` with embedded validation criteria, then `/dev-save` could update a `progress.md` tracking which criteria are met.

**Assessment**: Increases surface area. Revisit if real-project feedback shows goal scoping is too weak.

---

## 7. Things Explicitly NOT Worth Copying

### 7.1 ECC's Installer Complexity

Multiple install methods with mutual-exclusion rules and an advisor command (`npx ecc consult`) is overkill for a 4-command protocol. dev-protocol's onboarding is "clone repo, copy `.agents/` template, run `/dev-init`". Keep it.

### 7.2 LangGraph's Graph API

Requiring developers to write Python graph code to use a development workflow is absurd for chat-based AI assistance. dev-protocol correctly stays at the semantic level (commands, state files).

### 7.3 barkain's Parallel Wave Execution

Multi-agent parallel orchestration is out of scope for v2. Single-agent sequential execution is a feature, not a bug, for the target audience.

### 7.4 Microsoft Framework's Azure Coupling

Tying a development workflow protocol to a cloud provider destroys portability. dev-protocol's file-based state is the right abstraction.

### 7.5 Spec Kit's 7-Stage Gate Rigidity

Constitution → Specify → Clarify → Plan → Tasks → Analyze → Implement is excellent for enterprise specs but crushing for iterative exploration. dev-protocol's Init → Scope → Work → Save cycle preserves agility.

---

## 8. Final Recommendation

```text
READY_TO_FREEZE_V2
```

### Reasoning

After evaluating 7 candidate systems across 7 dimensions, dev-protocol v2 occupies a defensible niche: **the simplest session-resilient development workflow protocol with explicit validation**.

**No evaluated system solves the same problem better:**
- ECC and LangGraph are more powerful but orders of magnitude more complex.
- Superpowers enforces workflows but has no persistence.
- Spec Kit governs specifications but has no session recovery.
- wshobson is a toolbox, not a lifecycle protocol.
- barkain and Microsoft Framework operate at different abstraction levels.

**The protocol is not missing any critical ideas from the benchmark:**
- Automatic checkpointing (LangGraph, Microsoft) is nice-to-have but incompatible with git-based human-in-the-loop workflows.
- Multi-agent orchestration (ECC, barkain) is explicitly out of scope.
- Spec-driven gates (Spec Kit) are complementary, not competitive.
- Mandatory skills (Superpowers) can be adopted as prompt wording without protocol changes.

**The remaining risks (#14 phase drift, #15 status freshness) are implementation bugs, not design flaws.** They are scoped to R3 and do not require v2 command surface changes.

**Freeze recommendation**: Lock the v2 command surface (`/dev-init`, `/dev-scope`, `/dev-save`, `/dev-status`) and state file schema. Allow skill prompt improvements (e.g., mandatory-skill wording) as patch releases. Defer all command additions and schema changes to v3.

---

## Sources

- [GitHub - affaan-m/ecc](https://github.com/affaan-m/ecc)
- [obra/superpowers Agentic Skills Framework](https://lobehub.com/en/skills/aradotso-trending-skills-obra-superpowers-agentic-workflow)
- [GitHub - github/spec-kit](https://github.com/github/spec-kit)
- [LangGraph Persistence and Checkpointing](https://docs.langchain.com/oss/python/langgraph/add-memory)
- [GitHub - wshobson/commands](https://github.com/wshobson/commands)
- [GitHub - barkain/claude-code-workflow-orchestration](https://github.com/barkain/claude-code-workflow-orchestration)
- [Still Not Durable: Microsoft Agent Framework Critique](https://www.diagrid.io/blog/still-not-durable-how-microsoft-agent-framework-and-strands-agents-repeat-the-same-mistake)
- [7 State Persistence Strategies for Long-Running AI Agents in 2026](https://www.indium.tech/blog/7-state-persistence-strategies-ai-agents-2026/)
- [Checkpoint Patterns for Long-Running AI Agent Tasks](https://hendricks.ai/insights/checkpoint-patterns-long-running-ai-agent-tasks)
- [Crab: Semantics-Aware Checkpoint/Restore Runtime for Agent Sandboxes](https://arxiv.org/html/2604.28138v1)
- [LongSeeker: Elastic Context Orchestration for Long-Horizon Search Agents](https://arxiv.org/abs/2605.05191)
