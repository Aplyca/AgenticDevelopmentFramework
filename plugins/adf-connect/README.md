# adf-connect

The connections plugin of the [Agentic Development Framework](https://github.com/aplyca/AgenticDevelopmentFramework):
how a project reaches its tracker and the services its stack uses.

| Skill | What it does |
|---|---|
| `/adf-connect:connect` | Connects the project to a service through the service's official MCP server — Supabase, Vercel, Contentful, GitLab, Linear, Jira. It writes the project's `.mcp.json` entry with safe defaults (read-only, never production, no credentials committed), pre-approves only the tools that read, writes it down in `DEV-SETUP.md`, and verifies that every write still prompts |

The servers themselves stay in the project, not in this plugin
([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)):
- Which project, environment, and host each one reaches differs by project.
- A plugin starts every server it carries in every project that turns it on.
- The allow lists that keep writes prompting are project settings.

This plugin carries the knowledge, and the project keeps the configuration. ClickUp has the
framework's `clickup` module, and GitHub needs only the `gh` CLI.

Turn it on in any project that connects services, committed or packaged:
`"adf-connect@aplyca": true` in `enabledPlugins`, beside `adf`. It's listed in the `aplyca`
marketplace at the same version as `adf`, and a project pins them together. Its skill is written here
by hand; `scripts/build-plugins.sh` only keeps the version equal.
