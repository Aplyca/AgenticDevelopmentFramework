# 0031: A project changes an agent's model in its own rule

- **Status:** accepted
- **Date:** 2026-10-09

## Context

The framework sets each agent's tier in its `model:` frontmatter (0010, 0012). Three docs told a
project how to change one:

- `COST-MODEL.md`: "edit the agent's `agent.md` frontmatter";
- `AGENTS-REFERENCE.md`: edit it, record why in `.claude/rules/claude-code.md`, and re-apply it after
  each upgrade;
- `UPGRADING.md`: record why in the project's `CLAUDE.md`, which no project has since 0024.

That works only in a committed install. A packaged project, the default (0018), has no agent file. Its
agents are the `adf` plugin's, `@adf:code-reviewer` and the rest, and an update replaces the plugin's
copy.

**What Claude Code offers** (its sub-agents docs, checked 2026-10-09). A subagent's model comes from
the first of these that is set:

1. the `model` Claude passes when it spawns the agent;
2. the `model:` in the agent's definition;
3. `CLAUDE_CODE_SUBAGENT_MODEL`;
4. the main conversation's model.

No setting targets one agent by name.

**Checked** in a throwaway project on Claude Code v2.1.286. It had a plugin agent on `sonnet` and a
project agent of the same name on `haiku`:

- **Both agents were offered,** as `<plugin>:<name>` and `<name>`. The project's agent didn't replace
  the plugin's.
- **`CLAUDE_CODE_SUBAGENT_MODEL=haiku` left the plugin agent on Sonnet.** With
  `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1`, it ran on Haiku. The variable then applies to every subagent.
- **A `model` passed at spawn time ran the plugin agent on Haiku.**
- **A row in the project's `.claude/rules/claude-code.md` worked as an instruction.** The prompt only
  asked for the agent, and a Sonnet session and a Haiku session both passed `haiku` from the row.

## Decision

- **A project records an agent's model override in `.claude/rules/claude-code.md`.** It's a table of
  agent, model, and why, under "Agent model overrides". The session passes that model when it spawns
  the agent. The format is in `COST-MODEL.md` § Per-agent recommendations.
  - It works the same in both installs.
  - It lives in the project's own layer, so upgrades merge it instead of overwriting it.
- **A committed project can also edit `model:` in the agent's `agent.md`.** That doesn't depend on
  the session, but an upgrade overwrites it. The rule's row stays the record.
- **`/adf:orchestrate` keeps each agent's tier unless the project's rules record an override** for
  that agent.
- **Switching a committed project to packaged moves an override.** In `/adf:upgrade`, an agent whose
  only edit is its `model:` is removed with the others, and its model becomes a row in the rule.
- **The docs name what doesn't change one agent's tier:**
  - editing the plugin's copy;
  - `CLAUDE_CODE_SUBAGENT_MODEL`, with or without its force flag;
  - the `ANTHROPIC_DEFAULT_*_MODEL` alias variables;
  - a project agent with the same name.

## Consequences

- **Positive:**
  - A packaged project can change an agent's tier at all, and the change survives updates.
  - Both installs follow one procedure, and the override and its reason sit in the file every session
    loads.
- **Negative / cost:**
  - **It's an instruction, not configuration.** A session that misses the row runs the agent on the
    framework's tier. That fails safe: the framework's default is a tier chosen for the work (0012).
    An override here is a cost preference, not a guardrail, so 0006 doesn't require configuration.
  - **The row doesn't reach the `/deep-*` workflows.** Their lenses don't spawn the agents (0029),
    and they run on the session's model unless the script pins one.
  - **A few more lines in a project's always-loaded rule,** only for a project that overrides an agent.

## Alternatives considered

- **Say plainly that the override is committed-only.** Declined. Claude Code gives a packaged project
  a working lever, and the session already reads the rule.
- **`CLAUDE_CODE_SUBAGENT_MODEL` in the project's settings.** Declined. Without the force flag it
  doesn't move the framework's agents, which all name a model. With it, every agent runs on one tier:
  the framework's, the project's own, and Claude Code's built-in ones. That includes
  `@adf:spec-analyzer` and `@adf:architect`, which are on Opus for judgment.
- **A project agent that replaces the plugin's.** Not possible. The plugin's agents carry its prefix,
  so a project agent with the same name sits beside them. Calling the project's copy instead would be
  a fork that upgrades don't reach.
- **A mod that sets the model on `agent.spawn`.** Declined. The framework's mods are display-only
  (0026), and a mod is one more plugin for every developer to run. Its model takes the place of the
  spawn-time `model`, but Claude Code's docs don't say whether it beats the agent's frontmatter.
- **The alias variables (`ANTHROPIC_DEFAULT_SONNET_MODEL` and the others).** Declined. They change
  what an alias resolves to for the whole session, the main conversation included.
