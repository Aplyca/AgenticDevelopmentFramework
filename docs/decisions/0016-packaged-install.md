# 0016: A packaged install — the framework's machinery as a pinned plugin, `aplyca-adf` (opt-in, Claude Code only)

- **Status:** accepted
- **Date:** 2026-10-02
- **Amends:** [0009](0009-optional-modules.md) — what ships as committed files

## Context

An adopted repository carries the whole framework as committed files. The skeleton's own files fall
into two kinds:

- **The project's own:** `AGENTS.md`, `CLAUDE.md`, the settings, `config.sh`, the rules, `specs/`,
  and the docs. Teams fill them in and keep editing them.
- **Generic machinery that no project edits:** 20 skills, 8 agents, 4 workflows, and 8 hook scripts
  with their README — about 40 files that every upgrade copies over verbatim.

A marketing-site project's upgrade to `d5934b3` touched 82 files, mostly that machinery. Its team
asked whether the framework could be used like a package — versioned, but outside the project's
history. The framework said no on purpose: the plugin carries no framework content, so an adopted
repository stays readable by every AI tool with no runtime dependency (0009, both READMEs). Two
things have changed since. The repository is public, so any developer or CI job can fetch it. And
Claude Code plugins now carry skills, agents, workflows, and hooks.

**A spike** (2026-10-02, Claude Code 2.1.286) built a plugin from the skeleton's machinery and
loaded it into a project that had only the committed layer:

1. **Everything registers, under the plugin's name.** 20 skills and 4 workflows came up as
   `/<plugin>:<name>`. The agents came up as `<plugin>:<folder>:<name>`, because the skeleton keeps
   each agent in its own folder; flat files give `<plugin>:<name>`. A bare `/triage` isn't a
   command.
2. **The model still finds skills by their bare names.** The Skill tool loaded `write-spec` without
   the prefix, so instruction text that names `/write-spec` keeps working for the agent. People type
   the prefix.
3. **The plugin's hooks run on the project's settings.** This needed one change: `_lib.sh` reads
   `${CLAUDE_PROJECT_DIR}/.claude/hooks/config.sh` instead of a file next to itself. The
   session-context hook then reported a branch that only the project's `config.sh` protects,
   `guard-git` blocked `--no-verify`, and `triage-first` stopped the first edit.
4. **A project can pin a version.** Adding the marketplace with `#<ref>` writes `"ref"` into the
   project's `extraKnownMarketplaces` entry. Branches and tags work; a commit SHA was rejected.
5. **Versions are per project, but the marketplace isn't.** Two projects each recorded their own
   installed version (1.0.0 and 2.0.0). But Claude Code keeps one entry per marketplace name per
   user, and it follows whichever project declared it last: "Plugins already installed from it now
   update from the new source."
6. **Trust and fresh machines.** A project's marketplace entry counts only after someone trusts the
   folder. A machine that already installed the plugin loaded it even in a headless run, in a folder
   nobody had trusted. A fresh machine, such as CI, has to run the install commands first.
7. **Cloud sessions don't install plugins that a repository's settings declare** (Claude Code docs),
   so the packaged machinery is missing there.

## Decision

Offer a second install mode, **packaged**, alongside the committed install, which stays the default.
Packaged is for teams that work in Claude Code only.

- **The plugin `aplyca-adf`** carries the core skills, the agents (as flat files), the workflows, and
  the hook scripts, wired through its own `hooks/hooks.json`. Its hooks read the project's
  `.claude/hooks/config.sh`. Skills are typed `/aplyca-adf:<name>`: `/aplyca-adf:triage`,
  `/aplyca-adf:write-spec`.
- **It's generated from `skeleton/`** by a script in this repository and published in the same
  marketplace as `aplyca-framework`, the installer. A static check fails when the generated plugin
  and the skeleton drift apart, so the skeleton stays the single source.
- **Every release gets a tag** named after its changelog heading (`release-<SHA>`). A project pins
  that tag: `"ref": "release-<SHA>"` in its `.claude/settings.json`. The stamp in `CLAUDE.md` names
  the same release.
- **The project still commits** `AGENTS.md` and `CLAUDE.md` (with the prefixed skill names), the
  settings (permissions, model, the plugin and its pinned marketplace), `config.sh`, the rules,
  `specs/`, the docs, and every module's files. Modules stay committed: their files are scripts,
  templates, and configuration the project owns.
- **`/adopt` offers the choice** between committed (every tool, no dependency) and packaged (Claude
  Code only, about 40 fewer files). It records the choice in PDR-0001. **`/upgrade` in a packaged
  project** bumps the pinned tag — a one-line change — and merges the committed layer as it does
  today.

## Consequences

- **Positive:**
  - About 40 fewer files in each project's history.
  - The machinery upgrades with a one-line change, and its files never need merging.
  - A team sees exactly which release it runs, from the pinned tag.
- **Negative / cost:**
  - **Claude Code only.** Cursor, Copilot, and Gemini users still get `AGENTS.md` and the rules, but
    no skills. Teams with mixed tools stay committed.
  - **Longer names to type:** `/aplyca-adf:triage`. The agent resolves the bare names itself.
  - **Not everywhere:** absent in cloud sessions, and a CI job has to install it first. A teammate
    gets it once they trust the folder.
  - **One marketplace entry per user.** A developer working in two projects pinned to different
    releases sees that entry follow whichever project declared it last. Each project keeps its
    installed version until someone updates it. Teams on one release don't notice.
  - **Process changes arrive as a tag bump**, so reviewers read that release's changelog entry
    instead of a diff in their own repository. The upgrade pull request links it.
  - **Two shapes to maintain.** The generated plugin and its drift check are new framework code, and
    every skeleton change ships in both modes.
  - **A runtime dependency** on GitHub and this repository's tags.

## Alternatives considered

- **Committed only (today).** Simplest and works with every tool, but the generic machinery fills
  every project's history and every upgrade.
- **Packaged as the default.** It drops multi-tool support and cloud sessions for every team. Keep it
  opt-in.
- **A git submodule or subtree for `.claude/`.** The same directories hold the project's own skills,
  rules, and configuration, so the split doesn't line up, and submodules are friction for every
  clone.
- **An untracked local copy** (`/adopt`'s local-only fallback, `.git/info/exclude`). No shared
  version, and each developer installs it by hand.
- **A user-scope plugin.** It would turn the framework on in every project on a machine. Installs are
  per project.
