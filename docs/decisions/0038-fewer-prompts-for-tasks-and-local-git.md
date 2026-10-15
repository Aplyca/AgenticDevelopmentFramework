# 0038: Allow broadly, ask by name: make, docker, git, and gh

- **Status:** accepted
- **Date:** 2026-10-15
- **Amends:** [0032](0032-local-environment-layout.md) — the docker module's `make` allows;
  [0033](0033-pull-request-upkeep-without-prompts.md) — which git commands run without a prompt

## Context

Testing in an adopting project, the developer was asked to approve commands all day, mostly make
commands. We read that project's session transcripts: about 2,200 commands. The project already
allowed `make *`, so a plain make task never prompted. The prompts came from elsewhere:

- **Commands written so no rule could read them,** about 650:
  - a leading variable assignment (`S=/private/tmp/…; …`, `W=…; cd $W && make install`);
  - `git -C <path>`;
  - shell loops;
  - heredocs into `python3` or `node`.

  Claude Code doesn't match an allow rule past an assignment, can't check a path held in a variable,
  and asks about a redirect outside the project.
- **`make run cmd="yarn …"`, about 110.** The project's own ask rule covers it, as it should: it runs
  any command. Agents reached for it because no task ran one test file, linted one file, formatted,
  or type-checked.
- **`git add` and `git commit`, about 65.** The skeleton allowed neither, so every commit
  `/adf:commit` made asked.

Separately, a project upgraded before its stack met the conventions kept its own `make logs`, which
followed. The docker module allowed `make logs`, so an agent that ran it waited until its timeout.

## Decision

- **The tasks cover what agents need.** In `dev-env`'s specification:
  - C3: `test` takes `t=<filter>`, `lint` takes `f=<files>`, and every mode adds `format` and
    `typecheck`, which say so when the stack has no such tool;
  - C10: a task that runs a command it's given, such as `make run cmd="…"`, is for people. It asks
    (`Bash(make run *)`, which the docker module adds), and a command agents keep needing becomes a
    task of its own.
- **Allow broadly, and name only what must ask (C9).** An ask rule wins over any allow rule, so
  the docker module allows `Bash(docker *)` and `Bash(make *)`, and lists the exceptions:
  - what deletes data: `compose down -v` or `--rmi`, `rm`, `rmi`, `prune`, and `make reset`;
  - what reaches the host: `docker run`, whose mounts reach the host's files (agents use
    `docker compose run`);
  - what leaves the machine: `docker push`;
  - what prints secrets: `docker inspect`, a bare `docker compose config`, and an `exec` or
    `compose run` that names `env`;
  - `make run`, which runs a command it's given.

  A project task that deletes data under another name gets an ask rule of its own, which
  `/dev-env set up` proposes and `/adf:upgrade` lists. No task waits for input or follows a log.
- **`git` and `gh` the same way.** The skeleton allows `Bash(git *)` and `Bash(gh *)`, and asks by
  name before:
  - `git config`, which could switch off the git hooks (`core.hooksPath`);
  - `git push --tags`: a tag is a release;
  - what changes a pull request's state or speaks for a reviewer: `gh pr ready`, `merge`, `review`;
  - what can't be undone or exposes a credential: releases, `gh repo delete`, `gh secret`, `gh auth`
    (`gh auth token` prints one), and `gh api` writes.

  The list is short on purpose, and the developer chose it. Discarding local work (`git reset --hard`,
  `clean`, `restore`, `branch -D`) and issue writes run without a prompt: the git-workflow rule and
  `AGENTS.md` still say an agent discards work or posts on an issue only when asked. A rare command
  that's easy to undo — closing a pull request, a label, a workflow run, `docker stop` — runs too.

  Staging everything and `git commit --amend` run: the git-workflow rule still says stage by name, and
  an amend that's been pushed needs a force-push, which decision 0033 already let a work branch take.
  The guard-git hook still blocks `--no-verify`, commits on a protected branch, pushes to one, and a
  pull request that isn't a draft.
- **Agents write commands a rule can read.** The skeleton's `claude-code.md` gains § Commands that
  run without a prompt:
  - use the tasks, with a variable after the task (`make up DEV_MODE=native`);
  - write paths out rather than holding them in variables;
  - run `git` from the session's folder rather than `git -C`;
  - read and edit with the tools rather than loops and heredoc scripts;
  - shorten output with a pipe rather than a redirect.

## Consequences

- **Positive:**
  - A test-first loop, the local check, and each commit run without approvals nobody reads, so the
    prompts left mean something.
  - An agent runs the one test or file it changed through the project's task, as
    `.claude/rules/testing.md` § Verification budget asks.
  - The settings say plainly what still asks: a short list of names.
- **Negative / cost:**
  - **`Bash(make *)` trusts the project's Makefile.** A rule matches the command, not what it runs:
    `make test` runs whatever the task says. A task that deletes data under a new name runs without a
    prompt until its ask rule goes in, so a reviewer reads a Makefile change as code that runs
    without one.
  - **`docker compose run` and `exec` run any command in the project's containers** without a
    prompt. The containers hold the project's code and data, not the host's.
  - **A secret can still reach the conversation** through a form the ask rules don't name, such as
    `docker compose config --format json`. `/dev-env`'s safety rules and the specification (V4) say
    never to print one; the rules catch the usual forms.
  - **An agent can discard uncommitted work, or post on an issue, without a prompt.** The rules say
    it does neither unasked, and a mistake there is the cost of this choice.
  - **`git`, `gh`, and `docker` run without a prompt but for the named exceptions.** That includes
    rare commands that change shared state and can be undone: closing a pull request, a label, a
    workflow run, stopping another project's container. The hooks still hold the line on protected
    branches, skipped checks, and draft pull requests. A write `gh` adds later runs until the
    skeleton names it, so upgrades review the ask list.
  - **The command-writing rules are instructions, not enforcement.** An agent can still write a
    command no rule reads. It then prompts, which is the safe failure.

## Alternatives considered

- **Allow each task by name, after a check** (`make -n` shows it exists in every mode and deletes
  nothing). Tried first in this change, and declined. It needs a rule per task and a step that adds
  them, and every new task prompts until that step runs again. Naming the few exceptions is
  simpler, and the ask rule beats the allow either way.
- **Allow the package manager** (`npm *`, `yarn *`). Declined. It would pre-approve installs and
  arbitrary scripts, and the framework names no stack. The tasks cover the commands agents need.
- **Allow the shell forms** (`python3 -`, `for`). Declined. They run anything. The tools do the same
  reads and edits with rules of their own.
