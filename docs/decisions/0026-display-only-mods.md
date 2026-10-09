# 0026: The framework's mods are display-only — the first shows the local environment's URL

- **Status:** accepted
- **Date:** 2026-10-08
- **Builds on:** [0022](0022-local-check-before-the-pull-request.md) — the local check before the pull
  request; [0023](0023-plugins-by-concern.md) — mods as a later layer, one plugin per concern

## Context

**Before the draft pull request opens, the developer checks the change on the local environment**
(0022). The agent starts it and gives the developer the URL. Which URL depends on the checkout:
- with the parallel-agents module, each worktree has a port of its own, so the URL changes from task
  to task;
- without it, the project has one dev server.

Nothing on screen says which URL this checkout has, or whether anything answers there.

**Mods** (code.claude.com/docs/en/plugins/mods, checked 2026-10-08):

- **What they are:** JavaScript or TypeScript event handlers inside a plugin, running within Claude
  Code.
- **What they can do:** draw — a band above the prompt, panes, buttons — add `/commands` that run
  without a model turn, and hold or rewrite tool calls and prompts.
- **Where they work:** Claude Code v2.1.287 or later in a terminal, and the desktop app from v2.1.286.
  Their hooks run in `-p` and cloud sessions, but only a terminal or the desktop app shows what they
  draw.
- **What they can reach:** they run unsandboxed, with the developer's permissions, and can approve a
  tool call that an ask rule would prompt for.
- **How they ship:** in plugins only. A project can't commit one.
- **How they're checked:** `claude plugin validate` lists what a mod hooks and calls, and
  `claude plugin test` runs its tests against the engine.

## Decision

1. **The framework's mods are display-only.** They read files, request URLs, draw, and add commands.
   They don't:
   - approve, refuse, or rewrite a tool call or a prompt;
   - start a turn, run a process, write a file, call a model, or change settings.

   The process stays in skills, hooks, and permissions that every install shares; a mod only shows it.
2. **A static check holds every plugin's mod to that.** It allows only session, turn, command, and
   drawing events, and refuses calls to prompts, tools, processes, agents, models, file writes, and
   settings. It also requires every mod to have tests. `run-evals.sh` runs them with
   `claude plugin test` where the CLI is installed; CI, which doesn't install it, still runs the
   static check.
3. **A mod ships in the plugin of its concern,** written there by hand: there's no committed copy to
   generate it from. It works in any project that turns that plugin on, committed or packaged.
4. **The first mod, in `adf-dev`: the local environment's URL above the prompt,** with ● when it
   answers and ○ when it doesn't.
   - **Where the URL comes from:** `LOCAL_URL` in `.claude/hooks/config.sh` — a new, optional
     setting — or the parallel-agents worktree's `READY_URL`. Either may name `${APP_PORT}`, filled
     from the env file, of which the mod reads `APP_PORT` alone.
   - **When it refreshes:** every 15 seconds and after each turn.
   - **Elsewhere:** `/local-url` says the same in places that don't draw.
   - **Who fills `LOCAL_URL`:** `/adopt` and `/dev-env set up`.

## Consequences

- **Positive:**
  - The URL the local check needs is on screen in every checkout, worktrees included, along with
    whether the app is up.
  - The developer stops asking for it, and the agent stops looking for it.
  - No mod can weaken a guardrail: the check refuses the events and calls that would.
- **Negative / cost:**
  - **Claude Code only, and recent versions only.** Other tools, the VS Code chat panel, and older
    versions show nothing. The URL stays in `config.sh` for them, and the rule names where it lives.
  - **The mod has no committed copy,** so it updates only with the plugin's pin.
  - **Requests every 15 seconds** to the local URL, while a session is open.
  - **Its tests don't run in CI,** only where the `claude` CLI is installed.
  - **Not verified at runtime yet:** the band drawn in a live session. The tests mount it on the
    terminal and desktop surfaces, and `claude plugin validate` reads it.

## Alternatives considered

- **A status-line entry** (`$.ui.status`). It's one per plugin, and gives no room for the answering
  dot or a link.
- **A SessionStart hook that prints the URL.** That's once per session, with no live state; and
  through the model's context, it costs tokens.
- **Mods that guard as well as show:** for example, holding `docker compose down -v` and listing the
  volumes it would delete. That's left for a decision of its own, since a mod that intercepts tool
  calls runs beside the permission system, not inside it.
