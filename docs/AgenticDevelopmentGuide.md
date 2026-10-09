# Agentic Development Guide

> An enablement guide for software development teams adopting AI agents across the whole lifecycle. It defines the principles, methodologies, and capabilities, and the concrete way to prepare a repository and a workflow so that agents produce reliable, maintainable, auditable code.
>

## Purpose and audience

This guide takes a team from "we use AI for autocomplete" to "we work with AI agents, with discipline, across the whole SDLC". It isn't a list of tools. It's an **operating contract** for how we work with agents, which responsibilities are never delegated, and how we keep code and documentation in a state that agents (and people) can understand.

The underlying premise: AI agents are excellent collaborators and terrible owners. They speed things up enormously, but they produce plausible code that can drift from the intent, hallucinate APIs, and degrade as the project grows. Our discipline exists to capture the speed without inheriting those failures.

---

## Principles of agentic development

1. **AI-First.** AI is the default option, not the exception. Before doing a task "by hand", the team considers whether an agent could do it better, faster, or with less effort. The question isn't "can I use AI here?" but "is there any reason *not* to use it?".
2. **AI-Native.** We structure applications and repositories knowing they will be developed *and maintained* with agents: modules with clear boundaries, machine-readable documentation, explicit conventions, versioned context files. An AI-native repository is one where a newly arrived agent can find its way without asking, and where a developer can build the app with AI agents from the start.
3. **Efficiency assessed, not assumed.** How much AI to use on each task is decided explicitly, along four axes:
    - **Time** — does it reduce the total time, review included?
    - **Effort** — does it reduce the developer's cognitive load, or only move it to the review?
    - **Cost** — tokens, tools, infrastructure. Phased workflows (see SDD) consume more tokens; budget for it.
    - **Complexity** — ambiguous or critical tasks need more scaffolding (specifications, gates) or simply more human control.

    Rule of thumb: the more autonomy the agent has, the more supervision and scaffolding it needs.

4. **Human responsibility that can't be delegated.** Every artifact an AI generates — code, documentation, tests, configuration — is the responsibility of the person in charge of the activity. Assisted authorship doesn't dilute accountability: if you merge it, it's yours.
5. **The developer supervises and orchestrates.** The developer stops being the one who types every line and becomes the one who **directs, verifies at every checkpoint, and orchestrates** one or more agents. Directing is active work: it isn't "ask and approve", it's validating at each point before moving on to the next phase.
6. **Context is a finite, precious resource.** Every token an agent "sees" competes for its attention. Curating well what goes in (and leaving the noise out) affects quality more than switching models. This is context engineering, and it's a first-order skill (section 4.6).
7. **Expanding capabilities (T-shaped developers).** AI lowers the barrier to adjacent disciplines: a backend developer can produce basic or intermediate frontend work, a frontend developer can write SQL queries or infrastructure as code, and anyone can take on tasks outside their core competently. We use this on purpose to reduce bottlenecks and handoffs, make the team more versatile and autonomous, and as a path to **professional growth**: the agent is asked to explain, not only to solve, so people learn while they produce. We move from "I"-shaped specialists to "T"-shaped profiles (a deep core plus assisted breadth).
    1. **The critical nuance:** widening your *scope* doesn't automatically widen your *judgment*. Outside your specialty you have more "unknown unknowns" — the subtle accessibility, security, performance, or convention mistakes an expert spots at a glance and you might not. That's why this principle always comes with two obligations:
    2. **Build enough judgment to verify what you produce.** If you can't evaluate whether the output is correct, you aren't expanding your capability: you're accumulating risk. AI accelerates learning; it doesn't replace domain knowledge (remember: a spec doesn't replace knowing what a good database schema looks like).
    3. **Get a specialist's review for critical or high-risk work.** Expansion is for unblocking yourself and for low- or medium-risk tasks; critical work still goes through someone with the depth.

# Agentic development patterns

- Prompt pattern: the instructions the agents carry out
- Context pattern: the inputs that feed the model
- Harness pattern: the conditions and tools the model relies on
- Loop pattern: the verifications that guide the agent
- Graph pattern: the defined workflow (graph) in which several agents interact to accomplish a complex task

## The developer's roles in an agentic workflow

| Role | What they do | What they DON'T delegate |
| --- | --- | --- |
| **Specifier** | Translates the business intent into a specification with acceptance criteria, scope, and constraints | The definition of "what is correct" |
| **Orchestrator** | Assigns tasks to agents, sets the order, runs parallel or overnight runs | The decision about what runs autonomously |
| **Verifier** | Reviews code, runs and reads tests, validates security, performance, and accessibility | The final merge approval |
| **Context curator** | Keeps `AGENTS.md`, specs, skills, and rules up to date | The definition of conventions and antipatterns |

One person usually plays all four roles; the **Coordinator / Implementer / Verifier** pattern can also be split across several agents, with a human supervising.

---

## 4. Methodologies

### 4.1 Vibe coding — for prototyping only

Free-form, iterative prompting with no specification. Excellent for exploring, disposable by design. It **never** reaches production as is. Its characteristic failure — code that works but "feels foreign" to the rest of the project and degrades as it scales — is exactly what the other methodologies correct.

### 4.2 Spec-Driven Development (SDD) — the developer's responsibility

The specification, versioned and structured, is the **source of truth**; the code is the output, generated and regenerated against it. SDD arose as a direct response to three failures of prompting LLMs:

- **Intent drift** ("add login" is enormously underspecified).
- **Context decay** (the agent "forgets" old decisions and contradicts itself as the code grows).
- **Unverifiable output** (without explicit acceptance criteria there's no way to know whether it's right).

A good specification defines six elements: **expected outcomes, scope boundaries, constraints, prior decisions, task breakdown, and verification criteria**. Specs live in the repository (`/specs`) and are edited when the requirements change; then the affected part of the code is regenerated.

**The canonical SDD flow** (in line with tools such as GitHub Spec Kit):

```
constitution → specify → (clarify) → (checklist) → plan → tasks → (analyze) → implement
```

| Phase | Artifact | Purpose |
| --- | --- | --- |
| **Constitution** | `constitution.md` | The project's non-negotiable principles (mandatory testing, CLI-first, secure by default, the allowed stack). Defined once and amended. Every later phase checks it as a *gate*. |
| **Specify** | `spec.md` | What and why, with no technology. Requirements, user stories, acceptance criteria, edge cases. |
| **Clarify** (optional, recommended) | updates `spec.md` | A structured scan for ambiguities; the agent asks targeted questions and writes the answers back into the spec. |
| **Plan** | `plan.md`, `data-model.md`, `contracts/` | How: stack, architecture, data model, API contracts. Checks compliance with the constitution. |
| **Tasks** | `tasks.md` | A list of atomic tasks, ordered by dependency, with markers for the ones that can run in parallel and traceability to user stories. |
| **Analyze** (gate) | consistency report | A read-only analysis: coverage gaps, ambiguities, duplications, constitution violations, *before* implementing. |
| **Implement** | code | The agent carries out the tasks; the developer verifies at every checkpoint. |

> **Adoption levels** (from least to most radical): *spec-first* (the spec generates, the code is maintained), *spec-anchored* (spec and code coexist), and *spec-as-source* (the spec is the only artifact). Most teams start with spec-first.
>

> **Honest warnings:** SDD shines in greenfield work and well-scoped features; in a large *brownfield* codebase it can produce "work about the work" and volume more than fidelity. The spec doesn't replace domain knowledge: you still need to know what a good database schema looks like and to recognize subtle bugs. Use it as a tool, not a silver bullet.
>

### 4.3 Test-Driven Development (TDD) — leveraged with agents

Agents are particularly good at writing and maintaining tests. The recommended pattern: the person defines the acceptance criteria in the spec; the agent first generates the tests that encode them, then the code that makes them pass. The tests become an executable *gate* that limits what the agent can deliver. TDD and SDD complement each other: SDD checks for architecture and contract violations that unit tests can't capture structurally.

### 4.4 Documentation-First Development — the developer's responsibility

The intent is documented *before* implementing. In an agentic world, documentation has a second reader: the agent. Clear, versioned documentation is at once specification and context.

### 4.5 Using skills and MCP

- **Skills**: packaged, reusable capabilities (a folder with a `SKILL.md` and optional resources) that the agent discovers and loads for the task at hand. They encapsulate specialized knowledge and repeatable workflows. They're how we "teach" the agent how we do things once and reuse it across the whole team.
- **MCP (Model Context Protocol)**: an open standard for connecting agents to external services and data (repositories, issue trackers, databases, observability). Tools exposed through MCP should be self-contained, robust to errors, and have descriptive, unambiguous parameters — just like a good function.
- **Slash commands**: trigger multi-step workflows in a standard way (for example, the SDD pipeline).

Both MCP and the agent-instructions standard are now open standards under neutral foundation governance; preferring them reduces vendor lock-in.

### 4.6 Context engineering

The discipline of curating the agent's **entire** information environment: system instructions, tool definitions, history, retrieved documents, code context, git history, and team standards. It isn't "writing the prompt"; it's deciding what enters the context window, what gets compressed, what is retrieved on demand, and what is discarded.

Five core strategies: **selection, compression, ordering, isolation, and format optimization**. Concrete good practices:

- **Specific, with examples.** "Use good practices" is useless to an agent. `## Preferred` / `## Avoid` blocks with real code are among the most effective.
- **Progressive disclosure.** Metadata at the top of every context file (`owner`, `last_updated`, `scope`), so the agent can decide whether it's worth reading and people know whom to call when the context goes stale.
- **Avoid bloat.** Dirty context (stale history, raw tool output) degrades performance faster than a weaker model does.
- **ContextOps.** Define the conventions once, in a governed and versioned place, and distribute them to each tool's format; when a convention changes, it changes in one place.

### 4.7 The full SDLC with AI

AI isn't only for "generating code": it runs through the whole cycle. See section 5.

---

## 5. AI capabilities across the SDLC

| Stage | What the agent does | What the human verifies |
| --- | --- | --- |
| **Specification** (design, architecture) | Turns vague ideas into structured specs, proposes architectures, identifies edge cases and gaps | Consistency with the business, key architectural decisions |
| **Code generation** | Implements against the spec and tasks, following the repository's conventions | That it respects existing patterns and doesn't introduce debt |
| **Debugging** | Reproduces, isolates, and proposes fixes | The real root cause vs. a surface patch |
| **Documentation** (end-user and technical) | Writes docs and keeps them in sync with the code | Accuracy and completeness |
| **Tests** | Generates and maintains unit, integration, and E2E tests | Meaningful coverage, not just green |
| **Verifications** | Runs **security, performance, and accessibility** checks | That the findings are really resolved |

> **A calibration data point:** different studies report that LLMs generate code with vulnerabilities in roughly 10% to 42% of cases, depending on the benchmark. That's why security checks aren't optional, and AI-generated code goes through the same automated checks and human review as any other code.
>

---

## 6. Enabling an application for agentic development

### 6.1 Minimal file structure

```
repo/
├── README.md                 # For people: what it is, how to run it, how to contribute
├── AGENTS.md                 # For agents: the "agent's README" (see 6.2)
├── .claude/rules/claude-code.md  # Optional: the Claude Code layer (no CLAUDE.md)
├── /docs                     # Technical and end-user documentation
│   ├── architecture.md
│   └── decisions/            # ADRs (architecture decision records)
├── /specs                    # Versioned specifications (SDD's source of truth)
│   └── 001-feature-x/
│       ├── spec.md
│       ├── plan.md
│       ├── tasks.md
│       └── contracts/
├── /.specify
│   └── memory/constitution.md  # The project's non-negotiable principles
└── (the project's code, with nested AGENTS.md files where they help)
```

### 6.2 `AGENTS.md` — the instructions contract for agents

`AGENTS.md` is an open, vendor-neutral Markdown format: a "README for agents". Codex, Cursor, Copilot, Windsurf, Aider, Gemini (through its own file), and many more read it natively; Claude Code reads it natively too, as long as there's no `CLAUDE.md`, which it would read instead. It's designed so that **a single file** works across every tool and institutional knowledge doesn't get trapped in chat history.

**What to include** (no field is mandatory; these are the recommended sections):

- **Overview**: what the project does, and its purpose.
- **Stack**: languages, frameworks, versions, database, auth.
- **Conventions**: export style, folder organization, naming.
- **Commands**: how to build, run, and test (`npm run lint && npm run test`, etc.).
- **Testing instructions**: where the CI plan is, how to run one package's suite.
- **Boundaries / antipatterns**: what the agent must **not** touch ("don't modify `/legacy`, it's frozen") and where the repository deliberately departs from statistically common patterns. This section is "defensive programming for collaborating with AI".
- **Security**: practices and considerations.

**Good practices:**

- Be **specific**, not exhaustive: don't dump all the documentation into it. Keep the root file focused and **link** to deeper documents (coding standards, architecture).
- **Hierarchy / nesting**: in large repositories, place nested `AGENTS.md` files per module or feature. Agents automatically read the one closest to the file being edited; context scales from the general (root) to the local (module) to edge cases (feature). The closest one wins, and an explicit prompt from the user in the chat overrides everything.
- For tool-specific configuration, use each tool's own files (`.claude/rules/` for Claude Code, `.cursor/rules/` for Cursor), and keep what's shared in `AGENTS.md`.

### 6.3 The agentic development workflow, step by step

1. **Define or update the project's constitution** (once; afterwards it's amended).
2. **Write the feature's specification** (what and why). Iterate with the agent, using a *clarify* phase to remove ambiguity.
3. **Generate the plan** (how) and check that it respects the constitution.
4. **Break it down into tasks**, atomic and ordered by dependency.
5. **Run the consistency analysis** (a read-only gate) before implementing: coverage gaps, contradictions, constitution violations.
6. **Implement in phases** (Setup → Foundation → User stories → Tests → Polish). For large features, validate the core before adding incrementally, so as not to saturate the agent's context.
7. **Verify at every checkpoint**: run it, read the tests, review security, performance, and accessibility.
8. **Human review + automated checks** before the merge (section 7).
9. **Update the specs and docs** if the implementation revealed changes: the spec stays alive.

> An asynchronous working pattern: writing specs during the day and leaving agents running overnight works **only** if the spec is well defined, because the agent can't ask clarifying questions during the run.
>

---

## 7. Governance, quality, and security

Autonomy is powerful and potentially dangerous; the controls are built in from the start, not afterwards.

- **Code that hasn't been read is never merged.** The golden rule, with no exceptions — and stricter the more autonomous the agent.
- **Every agent-generated PR goes through the standard process**: human review **+** automated security checks before integrating.
- **Verify the PR, not just the diff.** Recent studies show inconsistencies between the description and the code in agents' PRs ("phantom" changes, or descriptions that don't match). Quick checks: the diff isn't empty, the description isn't too short for the size of the change, and watch out for template markers such as `[WIP]`.
- **Calibrate your trust in suggestions.** The evidence indicates that agents' suggestions are adopted at a lower rate than humans', and when adopted, they tend to increase the code's complexity and size more. Review the impact on maintainability with a critical eye.
- **Where the human remains essential**: understanding the design *intent*, transferring project knowledge, and reasoning about critical business logic. Agents excel at finding defects and at targeted improvements; complement, don't replace.
- **Scoping and guardrails**: limit the agents' privileges and environments; govern the dependencies they suggest (don't accept packages blindly).
- **Prompts and context as versioned, auditable artifacts**, not improvised in the chat. Shared repositories of prompts and skills keep developers consistent.
- **Compliance**: specifications are starting to be treated as regulatory evidence. If the project falls under regimes such as the EU AI Act, the versioned specs and the verification gates are part of the compliance record.

---

## 8. Metrics for evaluating adoption

- Cycle time per feature (review included), before and after adoption.
- Defects caught early (at the gates) vs. after release.
- The adoption rate of agents' suggestions, and their effect on complexity and size.
- Meaningful test coverage (not just a green percentage).
- Context freshness: the share of `AGENTS.md` files and specs reviewed in the last N months.
- Token cost per feature (phased workflows consume more; keep an eye on it).

Rollout strategy: start with a pilot team or feature, confirm it adds value without disruption, then extend it to more repositories.

---

## 9. "Agent-ready repository" checklist

- [ ]  `README.md` for people and `AGENTS.md` for agents, both current.
- [ ]  `constitution.md` with non-negotiable principles.
- [ ]  A `/specs` directory with versioned specs and acceptance criteria.
- [ ]  A `/docs` directory with the architecture and ADRs.
- [ ]  Build, test, and lint commands documented and runnable by the agent.
- [ ]  The relevant skills and MCP servers configured and versioned.
- [ ]  Nested `AGENTS.md` files in complex modules.
- [ ]  An explicit boundaries and antipatterns section.
- [ ]  A CI pipeline with mandatory security checks before merging.
- [ ]  A written policy: no merge without human review.

---

## 10. Antipatterns to avoid

- **Vibe coding into production.** Prototype with it; don't ship it.
- **Over-automating without review.** Assume generated code has errors until proven otherwise.
- **`AGENTS.md` as a dumping ground.** If it contains everything, it guides nothing. Focus it, and link out.
- **Generic context.** "Follow good practices" isn't an actionable constraint; give examples and rules specific to the repository.
- **Stale context.** Without `owner` and `last_updated`, context rots silently.
- **Treating the spec as bureaucracy.** SDD isn't waterfall or documents nobody reads; it's communicating intent in a verifiable way.
- **Confusing "passes the tests" with "is correct".** Unit tests don't capture architecture or contract violations.

# Levels of agentic development

- AI-assisted: asking with a prompt. Similar to Google or Stack Overflow
- Vibe coding: loose prompts. Using a coding agent
- Context & Harness: files for agentic development
    - agents
    - skills
    - MCP
    - AGENTS.md
- Loop: SDD and TDD
    - specs
    - slices
    - verification
    - tests
- Graph: the full, automated SDLC
    - requirements (agent)
    - architecture (agent)
    - specs (SDD) (agent)
    - documentation
    - plan
        - tasks
        - writing the tests (TDD) (agent)
    - execution per task
        - running the tests: they must fail
        - coding
        - running the tests: they must pass
    - commit

---

## 11. Glossary

- **AI agent**: a system that takes a high-level instruction, plans, and writes, tests, and modifies code with limited human intervention.
- **SDD (Spec-Driven Development)**: a methodology in which the versioned specification is the source of truth and the code is derived from it.
- **Context engineering**: the discipline of curating the agent's entire information environment.
- **AGENTS.md**: an open, neutral Markdown format for instructing coding agents.
- **MCP (Model Context Protocol)**: an open standard for connecting agents to external tools and data.
- **Skill**: a packaged, reusable capability (a folder with a `SKILL.md`) that the agent loads for the task at hand.
- **Constitution**: the document of non-negotiable principles that every SDD workflow checks as a gate.
- **Brownfield / greenfield**: existing, inherited code vs. a new project from scratch.
- **Gate**: a checkpoint that must be passed before moving on to the next phase.

---

## References

- AGENTS.md — an open format for coding agents (agents.md; stewarded by the Agentic AI Foundation / Linux Foundation).
- GitHub Spec Kit — a Spec-Driven Development toolkit (github/spec-kit; quickstart and command documentation).
- Anthropic — *Effective context engineering for AI agents* (anthropic.com/engineering).
- *Spec-Driven Development: From Code to Contract in the Age of AI* (arXiv, Feb. 2026), and guides on SDD from Augment Code and BCMS.
- *Human-AI Synergy in Agentic Code Review* and *Analyzing Message-Code Inconsistency in AI Coding Agent-Authored Pull Requests* (arXiv, 2026).
- Governance guides for coding agents (Google Cloud, Apiiro, Real Python) on human supervision and mandatory review.
- Packmind / Faros — good practices for context engineering and ContextOps for teams.
