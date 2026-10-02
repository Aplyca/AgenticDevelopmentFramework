# aplyca-adf plugin — generated

The framework's machinery for a **packaged install** ([decision 0016](../../docs/decisions/0016-packaged-install.md)):
20 skills, 8 agents, 4 workflows, and the guardrail hooks. A packaged
project commits only its own layer — `AGENTS.md`, `CLAUDE.md`, the settings, `.claude/hooks/config.sh`,
the rules, `specs/`, the docs, and its modules — and pins a release of this plugin in its
`.claude/settings.json`. `/adopt` sets it up; [docs/SETUP.md](../../docs/SETUP.md) has the details.

Everything here is named under the plugin: `/aplyca-adf:triage`, `/aplyca-adf:deep-review`,
`@aplyca-adf:code-reviewer`. The hooks read the project's `.claude/hooks/config.sh`.

**Don't edit these files.** They're generated from `skeleton/.claude/` by `scripts/build-aplyca-adf.sh`.
