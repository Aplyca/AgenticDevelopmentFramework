# 0078: Docker and make commands run without a prompt — the docker module asks before none

- **Status:** accepted
- **Date:** 2026-11-12
- **Amends:** [0038](0038-fewer-prompts-for-tasks-and-local-git.md) — "allow broadly, ask by name"
  keeps the allow and drops the names, for `docker` and `make`;
  [0032](0032-local-environment-layout.md) — the docker module's permissions (point 11);
  [0077](0077-the-container-is-the-boundary-for-make-run.md) — `make reset` no longer asks, and the
  hook no longer asks about a command that names `env`

## Context

- **0038 allowed `docker *` and `make *`, and named 19 exceptions** that still asked: what deletes
  data (`compose down -v`, `rm`, `rmi`, `prune`, `make reset`), what leaves the machine
  (`docker push`), what prints secrets (`docker inspect`, a bare `compose config`, an `exec` that
  names `env`), and `make run`.
- **0077 took `make run` off that list** and gave it to a hook. Eighteen rules were left.
- **The maintainer's call: docker and make aren't sensitive commands.** They act on a project's
  local stack. Its data is a development copy that the seed and the migrations bring back, and a
  prompt on each of them is one more approval nobody reads.
- **The rules never were a boundary.** They matched the text an agent types: a command inside a
  task or a script, or an unusual form, already ran without a prompt. The module's guide said so.
- **A prompt wasn't the only check.** `/adf-dev:dev-env` and the specification already have an
  agent name what a destructive step loses and wait for the developer's yes in chat.

## Decision

- **The docker module adds no ask rule.** Its settings keep the two allows, `Bash(docker *)` and
  `Bash(make *)`, and the denies that stop an agent changing the local mode (M10).
- **`make reset` runs without a permission prompt,** and so does every other `docker` and `make`
  command. The specification's C9 says so.
- **The developer's yes in chat stays** before anything that deletes data: `/adf-dev:dev-env`'s
  safety rule and C12 are unchanged, and now say that no prompt backs them.
- **The hook asks only where `make run` would run on the host** (0077). Its check for a command
  that names `env` or a `.env` file goes: it mirrored an ask rule that no longer exists.
- **A project task that deletes data gets no ask rule of its own.** `/adf-dev:dev-env` names it in
  `DEV-SETUP.md` instead, so an agent knows to ask in chat.
- **A team that wants a prompt adds its own rule** to `permissions.ask`; an ask rule still wins
  over the allow.
- **On upgrade a migration removes the rules the module added,** by their exact text, and the
  report lists each under Permission changes. A rule the project wrote itself stays.

## Consequences

- **Positive:**
  - With the module, one prompt is left for docker and make: `make run` in native mode.
  - The settings are short: two allows and the mode denies.
  - Resetting a stack, rebuilding without a cache, or cleaning up after a test run doesn't stop to
    ask.
- **Negative / cost:**
  - **Local data can be deleted without a prompt.** `make reset` and `docker compose down -v` run
    as soon as an agent types them. The rule that it asks in chat first is an instruction, and a
    mistake there costs a re-seed.
  - **Some commands reach past the project.** `docker system prune`, `docker rm`, and
    `docker volume rm` act on every project's containers, images, and volumes on the machine, and
    another project's local data may not come back as easily.
  - **`docker push` leaves the machine** without a prompt, where the developer is signed in to a
    registry.
  - **`docker run` with a mount reaches the host's files** (already so since 0038).
  - **A secret can reach the conversation without a prompt:** `docker compose config`,
    `docker inspect`, `printenv` in a container. V4 still says no agent prints one.
  - **The docker module is the exception among modules:** every other one pre-approves only what
    reads.

## Alternatives considered

- **Keep the ask list** (0038). Declined by the maintainer: the commands aren't sensitive enough to
  stop the work.
- **Keep only the asks that reach past the project** (`prune`, `push`). Declined: the same call, and
  a short list still needs a pattern per spelling.
- **Allow docker by name instead of broadly,** so nothing dangerous is allowed and nothing needs an
  ask. Declined: any docker command not on the list would prompt.
- **A hook that asks before a deletion outside this project's Compose project.** Not taken: it
  would have to parse docker's command line, and the maintainer asked for fewer checks here.
