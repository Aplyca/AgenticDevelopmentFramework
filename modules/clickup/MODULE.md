# Module: clickup

For teams whose requirements arrive as ClickUp tasks. Connects agents to ClickUp's official MCP
server, so they read the task — description, comments, statuses — instead of asking someone to paste
it, while every write the client can see still waits for a person's yes.

## What it adds

| File | Purpose |
|---|---|
| `.mcp.json` | ClickUp's hosted MCP server (`https://mcp.clickup.com/mcp`). No tokens in the repository: each developer signs in with OAuth on first use, so the agent acts as that developer |
| `.claude/settings.json` (merged) | `enabledMcpjsonServers: ["clickup"]`, so teammates get the server once they trust the folder, and a **read-only allowlist**: `clickup_get_*`, `clickup_search*`, `clickup_list_*`, `clickup_find_*`, `clickup_filter_tasks`. Every write tool — comments, status and task changes, chat messages, time tracking, docs — stays off the list and prompts |

## Install

Run the install script — not `cp -R`. `.mcp.json` and `.claude/settings.json` usually exist
already, and the script merges into them:

```bash
modules/clickup/install.sh /path/to/your-repo
```

It keeps your other MCP servers, your permissions, and a `clickup` entry you've customized; adds only
what's missing; and is safe to run again — `/upgrade` reruns it to pick up new read-only patterns.
`/adopt` runs it when you choose the module.

## Customize

In `docs/TRACKER-INTEGRATION.md`:

1. **The tracker** is ClickUp. Task links look like `https://app.clickup.com/t/<task-id>`, or your
   custom task IDs (e.g. `MKT-412`) — `/triage` searches the spec folders for them.
2. **§ Connecting the tracker** — replace the example `.mcp.json` with this module's, and note that
   the allowlist is already in `.claude/settings.json`.
3. **§ Stakeholder updates → Task statuses** — `clickup_get_task` with `expand_statuses: true` lists
   the statuses a task can move to; `/stakeholder-update` uses it before proposing a status change.
4. **Link back** — where pull request links go on a task: a "Links" section in the description, or a
   comment.

## Good to know

- **No revision history.** ClickUp's MCP server returns a task's current description and its
  `date_updated`, not earlier versions. Once a delivered task is edited, the spec folder is the only
  record of what was agreed — which is why a change request starts from the spec folder and the
  comments since it last changed (`specs/README.md` § Change requests).
- **Each developer acts as themselves.** Comments and status changes carry that developer's name, so
  the agent confirms each one first (`AGENTS.md` § Requirements & traceability).
- **ClickUp owns the tool names.** After installing, run `/mcp` in Claude Code and look at the
  server's tools: every allowed pattern must match only tools that read. If a new read tool prompts,
  allow it by exact name; never allow a write tool. If reads keep prompting, your Claude Code version
  doesn't match partial wildcards — list the read tools by exact name instead.

## Verify

- Both files are valid JSON: `python3 -m json.tool .mcp.json` and `python3 -m json.tool .claude/settings.json`.
- In a new session, `/mcp` shows `clickup`; signing in connects it.
- Ask the agent to read a task assigned to you — no permission prompt. Ask it to draft a comment — it
  shows the text, and posting prompts.

## Requirements

`python3` for the install script. A ClickUp account in the workspace for each developer.
