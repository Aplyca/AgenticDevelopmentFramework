# 0077: In Docker mode the container is the boundary — `make run` needs no prompt there

- **Status:** accepted
- **Date:** 2026-11-12
- **Amends:** [0038](0038-fewer-prompts-for-tasks-and-local-git.md) — `make run` is no longer "for
  people": the specification's C9 and C10; [0032](0032-local-environment-layout.md) — the docker
  module's permissions (point 11)

## Context

- **Developers named permission prompts as what slows them most.** Decision 0076 took the tracker's;
  this one takes the shell's most frequent: a command no task covers.
- **0038 answered with tasks.** `make run cmd="…"` ran any command, so it asked, and a command
  agents kept needing was to become a task of its own (C10).
- **Agents need too many different commands for that.** A package manager, a code generator, a
  migration tool, a one-off script: each would need a task or an allow rule, and the next one
  prompts until someone adds it.
- **In Docker mode the command doesn't run on the host.** The app's container holds the project's
  code and runtime, and nothing else of the machine. Decision 0038 already let
  `docker compose exec` run any command there without a prompt.
- **In native mode it does run on the host,** with the developer's files and credentials in reach.
- **What Claude Code's permissions allow** (its documentation, read 2026-11-12):
  - an ask rule still prompts when a `PreToolUse` hook returns `allow`: deny and ask rules are
    evaluated whatever the hook returns;
  - a rule matches the command's text, so no rule can tell a Docker checkout from a native one;
  - a hook can force a prompt (`ask`) where an allow rule matches, and can skip one (`allow`).
- **How `make` passes the command** (GNU make 3.81, checked with the templates):
  - a variable given on the command line is in the recipe's environment, so `"$$cmd"` hands it on as
    one argument;
  - `$(cmd)` pastes its text into the recipe, where the host's shell reads its quotes and
    separators: `cmd='a; b'` runs `b` on the host;
  - `make` expands a `$` in the value before either: `cmd='echo $HOME'` arrives as `echo OME`, and
    `cmd='$(shell …)'` runs on the host. A `$$` arrives as `$`.

## Decision

- **`run` is a task every mode defines (C3),** and the way an agent runs a command no task covers:
  `make run cmd='<command>'`.
  - Docker mode: `$(COMPOSE) exec -T $(APP) sh -c "$$cmd"` — in the app's container.
  - Native mode: on the host, with the services' ports exported.
  - The templates gain both. They had none: the rule and C10 named a task projects wrote themselves.
- **A hook decides, by the checkout's mode.** `approve-container-run.sh` runs before a Bash call
  that has `make … run` in it, in a project with the docker module:
  - **it approves** `make run cmd='<command>'` written on its own when all hold:
    - the mode is Docker, read as the root `Makefile` reads it: `DEV_MODE` in the environment, then
      in `.env`, then `DEFAULT_MODE`;
    - the `run` task in `ops/docker/Makefile` hands `"$$cmd"` to Compose's `exec` or `run`, and
      nowhere pastes `$(cmd)`;
    - the value is one neither the host's shell nor `make` expands — single-quoted with each `$`
      doubled, double-quoted with no `$`, backquote, or backslash, or a bare word — and it doesn't
      name `env` or a `.env` file;
  - **it says nothing** when that call is followed by a pipe or another command: the permission
    rules judge the line;
  - **it asks** before every other: native mode, a mode it can't read, a task of another form,
    `make` pointed at another folder or given another setting, a command it can't read.
- **The module's `Bash(make run *)` ask rule goes,** since it would win over the hook. `Bash(make *)`
  then allows `make run`, and the hook's `ask` is what prompts in native mode.
- **`make reset` still asks,** and so does any task that deletes data: their rules are unchanged.
- **`APPROVE_CONTAINER_RUN="1"`** in `.claude/hooks/config.sh`; empty asks in every mode, as before.
- **The specification says what the boundary is (C10, D5):**
  - it bounds the host outside the checkout, provided the app's service mounts only the checkout
    and named volumes — no Docker socket, no path outside it, not `privileged` (D5);
  - it doesn't bound the checkout (mounted, `.git` and `.env` included), the stack's local data
    (the backing services answer on its network), the credentials in `.env` and in the container's
    environment, or the network.
- **`/adf-dev:dev-env` says where commands run:** in Docker mode, a named task or `make run`, never
  the host.
- **One clause of always-loaded text.** The Claude Code rule's "Use the project's tasks" bullet
  names `make run cmd='<command>'` for what no task covers, so a session that never runs
  `/adf-dev:dev-env` or `make help` still knows the way. The rest stays in the skill.

## Consequences

- **Positive:**
  - In Docker mode an agent runs the project's own tools without a prompt and without a rule per
    tool.
  - A mistake there costs the checkout and its local data, both rebuilt from git and the seed.
  - Native mode keeps its prompt, and a stack whose `run` would leak onto the host keeps it too.
  - The prompt left on `make run` means something: the command runs on the host.
- **Negative / cost:**
  - **A secret in `.env` isn't protected.** A command in the container can read it and send it
    anywhere. The hook asks about a command that names `env` or `.env`, which catches the usual
    forms and no more. Production credentials stay out of `.env`.
  - **Local data can be changed or dropped without `make reset`,** through the app's own tools.
  - **The git guard doesn't read inside `cmd`.** A commit or push from the container isn't checked,
    as it already wasn't through `docker compose exec`. The rules still say an agent does neither
    there.
  - **Native mode's prompt now depends on a hook, not a rule.** With hooks turned off the allow rule
    lets `make run` through in both modes. Without `jq` and `python3` the hook asks.
  - **The hook reads the mode from where it runs.** A `DEV_MODE` exported only in the shell profile
    that Bash calls load, and not in Claude Code's own environment, isn't seen.
  - **Nothing checks what the app's service mounts.** D5 is the audit's, not the hook's: a service
    with the Docker socket reaches the host.
  - **`docker *` is still allowed** (0038), so `make run` isn't the only way into a container, and
    `docker run` with a mount still reaches the host without a prompt. Narrowing that is a decision
    of its own.
  - **A `$` must be doubled.** `make` takes a single one, so the hook asks rather than approve a
    command that would arrive changed.
  - **An existing project's own `run` task keeps asking** until it has the specification's form.
  - **The hook's `ask` wasn't exercised in a live session** in each permission mode. The
    documentation says it prompts, in auto mode too; `dontAsk` and `bypassPermissions` aren't
    described for it.

## Alternatives considered

- **Keep the ask rule and have the hook approve.** Not possible: an ask rule prompts whatever a hook
  returns.
- **Allow each command by name, or add a task for each.** Declined: the set never closes, which is
  what brought this up.
- **Allow `Bash(docker *)` as the way in.** It already is (0038), and it isn't a boundary: on the
  host, `docker` mounts any folder and deletes any volume. The project's own task is one command to
  read.
- **Leave `make run` to `Bash(make *)` in both modes.** Declined: in native mode it's any command on
  the host.
- **Deny `make run` in native mode.** Declined: a developer there may still want it, and a prompt
  lets them say so.
- **Have the hook check `compose.yaml` for the Docker socket.** Declined: a search for one string
  misses overrides, `privileged`, and host paths, and would read as a check that passed.
- **Pass the command to the hook's approval whatever it contains.** Declined: `$(…)`, a backquote,
  and `make`'s own `$(shell …)` run on the host before the container sees anything.
