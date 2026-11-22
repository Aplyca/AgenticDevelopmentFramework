# 0088: Reading git config, a release, or the secrets' names runs without a prompt

- **Status:** accepted; amended by [0096](0096-hooks-stay-silent-on-what-they-cannot-read.md) (an unreadable `git config` form runs unless it names `core.hooksPath`)
- **Date:** 2026-11-16
- **Amends:** [0038](0038-fewer-prompts-for-tasks-and-local-git.md) — `git config`, releases, and
  `gh secret` ask before a write, not before every use

## Context

A developer asked whether `bypassPermissions` would stop the prompts that still came in auto mode.
It wouldn't. An explicit ask rule prompts in every mode, `bypassPermissions` included, and so does
the desktop app's question before a session moves into a folder nobody trusted. What bypass does
remove is the check on everything else.

The session logs record each permission decision, and a prompt the developer answered shows as
`source: "user_temporary"`. Over two weeks in four adopting projects and this repository, 153
prompts came in 81 sessions. The largest group the framework causes came from ask rules that catch reads:

- **30 were `git config` reads**, mostly `git config core.hooksPath` or `--get`, run while checking
  that the git hooks are on before a commit. 0038's `Bash(git config *)` rule asks before every
  form, because `core.hooksPath` can switch the hooks off.
- **10 were `gh release list` or `view`, and `gh secret list`**, caught by `Bash(gh release *)` and
  `Bash(gh secret *)`. A release list shows nothing private, and `gh` can't print a secret's value.

The rest were by design (merging, issue writes, tag pushes), a move into a worktree beside the main
checkout that v2.10.0 retires (0083), or one-off commands.

## Decision

- **The git guard hook decides `git config`.** The skeleton drops the `Bash(git config *)` ask rule:
  a permission pattern can't tell `git config core.hooksPath` (a read) from
  `git config core.hooksPath /dev/null` (a write), and an ask rule would win over any hook. The
  `guard-git.sh` hook asks before a change, and a read runs under `Bash(git *)`:
  - a read is a get or list form (`--get`, `--get-all`, `--get-regexp`, `--list`, the `get` and
    `list` subcommands) or a single name with no value;
  - anything else asks: a name and a value, `--unset`, `--add`, `--replace-all`, a section rename
    or removal, `--edit`, and the `set`, `unset`, and `edit` subcommands;
  - a flag the hook doesn't know counts as taking no value, so the word after it counts as a value:
    a form it can't read asks rather than runs. A redirect isn't a value.
- **Releases and secrets ask before a write.** The ask rules name the subcommands that write:
  `gh release create` (and its alias `new`), `edit`, `upload`, `delete`, `delete-asset`, and
  `gh secret set`, `delete` (and its alias `remove`). `list`, `view`, `download`, and `verify` run.
- **GitLab stays as it is.** `glab variable get` prints a value, so the `glab variable` and
  `glab securefile` rules keep asking before every use, and `glab release` keeps its rule until its
  write subcommands are checked against a `glab` install.

## Consequences

- Replayed through the new hook, the 77 distinct commands from those two weeks that ran
  `git config` were all reads, and none asks now. About 20 prompts a week go.
- A `gh release` or `gh secret` subcommand added later that writes runs without a prompt until a
  rule names it: the list is by name, as 0038's is.
- The hook reads the command text, as its other rules do: a `git config` hidden in a variable or a
  `bash -c` string isn't seen. The rule it replaces matched the same text.
- A project upgrades through the three-way merge of `.claude/settings.json`: the three old rules go
  and the new ones arrive, each listed under Permission changes. A project that edited those lines
  resolves the merge by hand.

## Alternatives considered

- **Turn on `bypassPermissions`.** Rejected: ask rules still prompt in that mode, and it removes the
  auto-mode check on every other command.
- **Keep the ask rule and have the hook approve reads.** Not possible: an ask rule prompts whatever
  a hook returns (0077).
- **Ask rules for the write forms of `git config`.** Rejected: a write is a second word, which a
  pattern can't separate from a read's flags (`git config --get-regexp alias x`).
- **Have agents check `core.hooksPath` some other way.** Rejected: `git config` is the documented
  way to read it, and the agent would still need a read that runs.
