# 0096: Hooks stay silent on what they can't read, and stop only where the risk is

- **Status:** accepted
- **Date:** 2026-11-22
- **Amends:** [0088](0088-reads-of-git-config-releases-and-secrets-run.md) — a `git config` form the
  guard hook can't read no longer asks, unless it names `core.hooksPath`; [0038](0038-fewer-prompts-for-tasks-and-local-git.md)
  — `gh auth` and `glab auth` ask only before a login, a switch, or a token shown

## Context

[0089](0089-no-hook-decides-make-run.md) removed a hook that asked about every `make run` line it
couldn't parse: an `ask` from a hook beats the allow rules and `bypassPermissions`, so the developer's
own permission mode couldn't quiet it. The developer owns what Claude Code may do; a hook asks or
stops only about a risk it has positively identified. A review of the remaining hooks found five
that still acted on doubt, or on something that wasn't the risk they exist for:

- **`guard-git.sh`** asked before any `git config` form with a flag it didn't know (0088's
  fallback), and treated a folder it couldn't read (`git -C "$WT"`) as the session's own — so a
  commit in another checkout was blocked because the session's checkout was on `main`.
- **`triage-first.sh`** stopped the first write anywhere — a memory note, a plan, a scratch file
  outside the project — read a quoted `"git branch cleanup"` in an `echo` as a new branch, and asked
  an answer's triage, which names no lane, for a fast-lane line.
- **`careful-paths.sh`** stopped the first edit in a sensitive area even when the triage had already
  chosen the careful or full lane, and stopped subagents, which work under their caller's triage.
- **`check-env-declared.sh`** reported every variable the whole file read, after every edit, so a
  variable the platform provides (`PORT`, `VERCEL_URL`) stopped each edit to that file for good.
- **`Bash(gh auth *)` and `Bash(glab auth *)`** asked before `auth status`, a read the agent runs to
  see who will post.

## Decision

- **Unreadable input is silent.** `guard-git.sh` knows no branch for a folder it can't read, and lets
  a `git config` form with an unknown flag run — unless the form names `core.hooksPath`, the setting
  that switches the hooks off, which is the risk the check exists for. The common flags (`--global`,
  `--local`, `--show-origin`, …) are known, so `git config --global user.name x` still asks.
- **`triage-first.sh` looks only at the project's files and real commands,** and accepts any triage:
  a lane named, or the `Triage —` heading an answer's triage opens with.
- **`careful-paths.sh` lets the edit through when the latest lane the replies name is careful or
  full** ("fast lane … now the careful lane" counts as careful), and leaves subagents alone.
- **`check-env-declared.sh` checks the names the edit wrote** — an Edit's new text, a Write's content
  — and its message names `ENV_IGNORE` for what the platform sets.
- **`auth` asks only before a login, a logout, a switch, a refresh, a git credential, or a token
  shown** (`gh auth token`, `auth status -t`/`--show-token`); `auth status` runs.

## Consequences

- **Positive:**
  - The hooks stop for the risks they name, and the developer's permission mode decides the rest.
  - No stop on files the developer never asked to triage, and no repeat prompts on harmless reads.
- **Negative / cost:**
  - **A commit through a computed path skips the protected-branch check:** `git -C "$WT" commit`
    on another checkout's `main` passes. The git-hooks module's pre-push and the remote's branch
    protection still hold, and the instructions say to write paths out.
  - **An unknown `git config` flag before a write passes** unless it names `core.hooksPath`.
  - **The careful-paths check reads the transcript,** like triage-first, so a reply that names the
    careful lane in passing as the latest lane lets the edit through. It's a reminder, not a lock.
  - **A MultiEdit is still checked against the whole file:** its new text isn't one field.

## Alternatives considered

- **Keep asking on unreadable input, and document the bypass.** Declined: it's what 0089 removed for
  `make run`, and a hook's ask beats the developer's own mode.
- **Drop careful-paths and triage-first.** Declined: both are once-per-session reminders, and each
  is off with an empty setting.
