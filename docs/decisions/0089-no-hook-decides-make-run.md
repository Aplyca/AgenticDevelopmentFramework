# 0089: No hook decides `make run` — the developer's permission mode does

- **Status:** accepted
- **Date:** 2026-11-18
- **Amends:** [0077](0077-the-container-is-the-boundary-for-make-run.md) — the approve-container-run
  hook goes, and with it the prompt before `make run` in native mode;
  [0084](0084-docker-mode-needs-nothing-on-the-host.md) — the hook no longer names the tools service

## Context

- **The hook was meant to remove prompts, and in practice it added them.** It approved
  `make run cmd='…'` written on its own in Docker mode, said nothing when that call came first in a
  line followed by a pipe or another command, and asked about every other line containing
  `make … run`. Agents chain commands, so a line such as `sed -i … && make run cmd='npm run lint'`
  prompted, and the prompt showed a line that starts with `sed`, `grep`, or `find`.
- **A field report ([issue 177](https://github.com/aplyca/AgenticDevelopmentFramework/issues/177))**:
  in one dependency-upgrade session in `bypassPermissions` mode, 15 of 32 `make run` calls prompted.
  The prompts came from chained lines, a `for` loop, and a `$` or backslash in `cmd=`.
- **The docker module already allows `Bash(make *)`.** That rule lets `make run` through, so the
  hook's `allow` added nothing in default mode, and its `ask` overrode the project's own rule. It
  never read `permission_mode`, so it prompted in `bypassPermissions` mode too, where the developer
  had already chosen not to be asked.
- **It had no off switch.** An empty `APPROVE_CONTAINER_RUN` made it ask in every mode.
- **What it protected:**
  - in native mode, `make run` runs its command on the host, and the hook's ask was the only prompt
    in front of it;
  - `make` reads a single `$` in the value before the container does, so `cmd='$(shell …)'` runs on
    the host even in Docker mode.

## Decision

- **The approve-container-run hook goes,** with its `APPROVE_CONTAINER_RUN` setting and its
  wiring in the `adf` plugin and the skeleton's `.claude/settings.json`.
- **`Bash(make *)` covers `make run` in both modes, and the session's permission mode decides the
  rest.** What Claude Code may do is the developer's choice: their permission mode and their
  project's rules. A framework hook that second-guesses it with prompts is what issue 177 reports.
- **Native mode is documented, not guarded.** The docker module's `MODULE.md`, `dev-env`'s
  specification (C9, C10, D5), the native `run` task's comment, and the onboarding guide say that
  in native mode `make run` runs its command on the host without a prompt, and that a project
  that wants one adds `Bash(make run *)` to `permissions.ask`. An ask rule can't read the mode, so
  it prompts in Docker mode too.
- **The same rule is the answer when the container stops bounding the host:** an app or tools
  service that mounts the Docker socket or a path outside the checkout (D5), where an empty
  `APPROVE_CONTAINER_RUN` used to be.
- **The v2.9.0 migration that removed `Bash(make run *)` no longer waits for the hook.** A project
  upgrading from v2.8.0 or earlier loses the rule its installer added, as every project at v2.9.0
  or later already has, and the upgrade report says how to add it back.

## Consequences

- **Positive:**
  - No framework hook prompts on `make run`. A chained, looped, or quoted line follows the
    project's rules and the session's permission mode, `bypassPermissions` included.
  - One less hook to keep in step with the `run` task's form, and one less setting.
- **Negative / cost:**
  - **In native mode `make run cmd='…'` runs any command on the host without a prompt,** unless the
    project adds the ask rule. `Bash(make *)` covers the whole line, so the command inside `cmd=` is
    never checked on its own: the project's other rules, deny rules included, and the git guard
    don't see it.
  - **`make` expands a single `$` on the host.** `cmd='$(shell …)'` runs there in either mode. The
    rules still say to write a `$` for the command as `$$`, in single quotes; nothing enforces it.
  - **A `run` task that doesn't hand its command to the container** — one that pastes `$(cmd)`, or
    hands it to a service outside D5 — runs some or all of it on the host without a prompt. The
    `dev-env` audit still names it.
  - **An ask rule on a project's other host task** (`make exec`, C10) guards less than it did:
    in native mode `make run` reaches the same host without one.

## Alternatives considered

- **Fix the fallback** (issue 177's proposal): read `permission_mode` and stay silent in
  `bypassPermissions`, and stay silent on a chained line whose `make run` parts are clean.
  Rejected: it keeps a hook whose only effect, next to `Bash(make *)`, is prompts the developer
  didn't ask for, and each new line shape agents write is another case to parse.
- **Ship `Bash(make run *)` as an ask rule.** Rejected: it prompts in Docker mode too, where the
  container is the boundary (0077), which is what 0077 and 0078 removed.
- **An off switch for the hook.** Rejected for the same reason as the fix: the default would still
  add prompts that override the project's own rules.
