# 0038: A project's make tasks and local git work run without a prompt, once they're checked

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
- **A make task runs without a prompt once it's checked (C9).** The docker module allows no `make`
  task itself. `/dev-env set up` adds `Bash(make <task>)` and `Bash(make <task> *)` for each task
  that passes the check, in every mode the project uses:
  - it exists;
  - `make -n` shows it does what C3 says, and deletes nothing;
  - `logs` never follows.

  The tasks that can pass are every C3 task but `reset`, plus `help`, `env`, and native mode's
  `services`. `reset` always asks. `/adf:upgrade` removes an old rule whose task fails the check.
- **Local git work runs without a prompt.** The skeleton allows:
  - `git add`, `git commit`, and `git switch`;
  - `git fetch`, and `git pull --ff-only`.

  `git add .`, `git add -A`, and `git commit --amend` ask: the git-workflow rule says stage by name,
  and an amend rewrites history. The guard-git hook still blocks `--no-verify`, commits on a
  protected branch, and pushes to one.
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
  - A task that would hang an agent never gets a rule.
- **Negative / cost:**
  - **An allow rule trusts the project's Makefile.** A rule matches the command, not what it runs: an
    allowed `make test` runs whatever the task says. The check runs when the rule goes in, and again
    when the task changes. A reviewer reading a Makefile change reads it as code that runs without a
    prompt.
  - **`git commit` runs without a prompt.** A commit is local and easy to undo, and the hooks still
    hold the line on protected branches and skipped checks.
  - **Until `/dev-env set up` runs, a project with the docker module prompts for every make task.**
    Before, four were allowed in every project. The upgrade names the step.
  - **The command-writing rules are instructions, not enforcement.** An agent can still write a
    command no rule reads. It then prompts, which is the safe failure.

## Alternatives considered

- **Allow `make *` in the module.** Declined. It would pre-approve a task that deletes data, a
  following `logs`, and `make run`'s arbitrary commands. Ask rules cover `reset` and `run`, but not
  a project's own destructive task under another name.
- **Allow the package manager** (`npm *`, `yarn *`). Declined. It would pre-approve installs and
  arbitrary scripts, and the framework names no stack. The tasks cover the commands agents need.
- **Allow the shell forms** (`python3 -`, `for`). Declined. They run anything. The tools do the same
  reads and edits with rules of their own.
