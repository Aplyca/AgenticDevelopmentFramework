# 0025: The worktree scripts are the plugin's commands — `adf-worktree-new`, `-ls`, `-rm` (parallel-agents module)

- **Status:** accepted
- **Date:** 2026-10-09
- **Amends:** [0016](0016-packaged-install.md) — what a packaged project commits for a module;
  [0023](0023-plugins-by-concern.md) — what a module's plugin carries

## Context

**The test from 0016 and 0023.** What a project edits is committed; machinery no project edits is
packaged. Both records still count every module script as the project's own. 0016 says "Modules stay
committed: their files are scripts, templates, and configuration the project owns", and 0023 lists
scripts among what a module commits.

**The parallel-agents scripts are machinery.**

- `worktree-new.sh`, `worktree-ls.sh`, `worktree-rm.sh`, and `_worktree-lib.sh` are 542 lines with no
  `<!-- CUSTOMIZE -->` markers.
- `/upgrade` already treats them that way. Its safe-to-overwrite bucket lists "module scripts", copied
  verbatim from the new release.
- The project's half is `scripts/agent/worktree.conf`, with eleven `CUSTOMIZE` notes. The scripts
  read it as `config.sh` is read by the hooks.

So a packaged project with the module commits four files that no project edits and every upgrade
replaces.

**Who runs them:**

- **A dispatched worker,** whose first step is `scripts/agent/worktree-new.sh <branch> --no-start`
  (0021). The session-context hook prints that step, and `/dispatch`'s prompt names it.
- **The hub hook,** whose message names the same step.
- **`/dev-env`** (`docker` module), which verifies a worktree's stack with `worktree-new.sh` and
  `worktree-ls.sh`.
- **People in a terminal.** The module's setup adds the three scripts to `AGENTS.md` § Quick
  reference.

**How they find things today:**

- **The library locates itself.** `_worktree-lib.sh` finds the main checkout from the git directory
  of the folder it's in, and loads `worktree.conf` from beside itself.
- **Module checks look for the script.** The hooks (`protect-hub.sh`, `session-context.sh`),
  `/dispatch`, `/dev-env`, `/connect`, and the install prompt decide that the module is installed
  when `scripts/agent/worktree-new.sh` exists.

**What the plugin docs say** (code.claude.com/docs/en/plugins, checked 2026-10-09):

- **Commands on the Bash tool's PATH.** A plugin's `bin/` folder is added to the Bash tool's PATH
  while the plugin is on.
- **Not the developer's own shell.** Nothing says it reaches a developer's own terminal.
- **Not every surface.** claude.ai and Cowork don't install a plugin with a top-level `bin/`.

**A spike** (2026-10-09, Claude Code 2.1.286): four headless sessions on Haiku, with a throwaway
plugin loaded through `--plugin-dir` into a scratch repository. What happened:

1. **The plugin validates.** `claude plugin validate` accepts a top-level `bin/`.
2. **Bare names work.** The Bash tool ran a `bin/` command by its bare name, and so did a plugin
   skill that named it. The plugin's `bin/` was the last entry on PATH.
3. **Allow rules match the bare name.** `Bash(adf-spike-env *)` matched. Without a rule, the headless
   run denied the command, as it denies any command that isn't allowed.
4. **No plugin variables in the Bash tool.** Neither `CLAUDE_PLUGIN_ROOT` nor `CLAUDE_PROJECT_DIR` is
   set in a Bash tool command. A command finds its own folder through `BASH_SOURCE`, and the project
   through its working directory.
5. **Hooks don't get the commands.** A hook's PATH doesn't include `bin/`, but the hook has
   `CLAUDE_PLUGIN_ROOT`.
6. **The worktree scripts run from `bin/` after two changes.**
   - The library finds the checkout and `worktree.conf` from the working directory instead of its own
     folder: three places.
   - Each script loads the library from the plugin.

   **In a session:**
   - `adf-worktree-new feat/spike-session --no-start` created the worktree.
   - The scripts left their marker in its git directory.
   - `adf-worktree-ls` listed it.

   **Run directly:**
   - The commands also worked from inside a worktree and from a subdirectory.
   - Outside a repository, they stop with "not inside a git repository". Today's scripts work from
     any directory.

## Decision

1. **`adf` carries the scripts as commands** in its `bin/`: `adf-worktree-new`, `adf-worktree-ls`,
   and `adf-worktree-rm`, with the scripts' arguments.
   - **The `adf-` prefix.** The plugin's `bin/` comes last on PATH (finding 2), so a developer's own
     command with the same name would run instead, without a warning. The build requires a command's
     name to start with its plugin's.
   - **One file per command.** Each command carries the scripts' helper, `_worktree-lib.sh`, inline,
     so nothing in the plugin loads a file by a path the shell computes. The Claude Directory's checks
     refuse such paths for hooks.
2. **The module stays the one source.** `modules/parallel-agents/module.json` names the commands:
   `"commands": {"adf-worktree-new": "scripts/agent/worktree-new.sh", …}`. `scripts/build-plugins.sh`
   generates them:
   - it inlines the helper each script loads;
   - it points the helper's one self-locating line at the project's `scripts/agent/`, found from the
     working directory (finding 4), and fails if anything else in a command looks beside itself;
   - it renames the scripts in every plugin's skills, agents, hooks, and commands:
     `scripts/agent/worktree-new.sh` and `worktree-new.sh` become `adf-worktree-new`, as `/triage`
     becomes `/adf:triage`.

   A committed install copies the scripts unchanged, so they keep working from any directory.
3. **`worktree.conf` stays in the project,** at `scripts/agent/worktree.conf`: the project's settings,
   as `config.sh` is the hooks'.
4. **The module's settings file is what shows it's installed.** In both installs, the hooks,
   `/dispatch`, `/dev-env`, `/connect`, and the install prompt check for `scripts/agent/worktree.conf`,
   not the script.
5. **The commands act only where they should:**
   - **Outside a repository,** a command says so and stops.
   - **No module:** without `scripts/agent/`, which a packaged project keeps for `worktree.conf`, a
     command says the project doesn't use the parallel-agents module, and stops. A plugin is on or off
     as a whole (0023).
   - **A committed install:** where the project has the committed script, the command runs that
     instead, with the same arguments. The plugin is on there for `/upgrade`, and the project runs the
     version it upgraded to, as the skills' Step 0 does.
6. **A packaged project names the commands.**
   - `/adopt` writes `adf-worktree-new` and the others in `AGENTS.md` § Quick reference, as it writes
     `/adf:triage` in `DEV-SETUP.md`.
   - The names note in `.claude/rules/claude-code.md` gains a sentence that maps each script to its
     command.
   - `docs/PARALLEL-AGENTS.md` names the scripts and says what they're called in a packaged install,
     so it reads true in both.
   - `/adopt`, `/upgrade`, and the plugin's hooks and skills name `adf-worktree-new`. It's there in
     both installs whenever they run, and runs the committed script where there is one.
7. **`/upgrade` moves a packaged project to the commands** when the pinned release's plugin carries
   them. It deletes the four scripts when none changed since the old release, keeps `worktree.conf`,
   and renames the references above. If the team edited one, the four stay together — each loads
   `_worktree-lib.sh` from beside it — and the commands run them. A switch to the committed install
   copies them back.
   Permissions don't change. Neither install allows the scripts today, and a project that wants no
   prompt adds `Bash(adf-worktree-new *)` and the others.
8. **It ships with the next release, v2.0.0,** and breaks nothing on its own. A packaged project that
   keeps its scripts loses nothing, because the commands run them (5).

## Consequences

- **Positive:**
  - A packaged project with the module commits `worktree.conf` alone: four fewer files and 542 fewer
    lines, which its upgrades skip. Fixes to the scripts arrive with the pin.
  - The framework's test holds for modules too. `/upgrade`'s bucket and 0023 stop disagreeing.
  - Commands cost no context: unlike skills, `bin/` isn't listed.
  - The worker's first step works from any folder in the repository, not only from its root.
- **Negative / cost:**
  - **The developer's own terminal doesn't have the commands** in a packaged project, since `bin/`
    reaches only the Bash tool. People go through `/adf:dispatch`, which every task does already
    (0020), ask Claude to list or remove a worktree, or run the cached copy by its full path.
  - **`adf` gets a top-level `bin/`.** claude.ai and Cowork don't install such a plugin. `adf` is a
    Claude Code plugin; revisit with the own-plugin alternative below if it's offered there.
  - **Two names for one script:** `scripts/agent/worktree-new.sh` in a committed project,
    `adf-worktree-new` in a packaged one. The docs and the names note carry both, as they do for the
    skills.
  - **The commands need the repository.** Run from outside it, they stop (finding 6).
  - **The build learns module commands:** inlining, rewriting, and the hand-over. That's more
    generated code, and the drift check covers it.
  - **Not verified at runtime yet.** Check these before the release:
    - a plugin installed from the marketplace, not a folder: its cache path, and that the commands
      keep their executable bit;
    - a session that the desktop app opens from the `/dispatch` chip;
    - a worker that moves into its worktree after creating it, where the commands should stay on
      PATH because PATH belongs to the session.

## Alternatives considered

- **Keep the scripts committed** (today). Nothing new to build, and the terminal keeps them. But
  every packaged project commits 542 lines that no project edits and every upgrade replaces, against
  the test that moved the skills.
- **Call them from the plugin's folder by full path, with no `bin/`.** `adf` would stay installable
  on claude.ai and Cowork. But the Bash tool has no `CLAUDE_PLUGIN_ROOT` (finding 4), so every printed
  step and every allow rule would name the versioned cache folder, and change with each release.
- **A plugin of their own** (`adf-worktrees`), so `adf` has no `bin/`. That's a fourth plugin to
  explain, turn on, and allow for one module's commands, and the module is part of the process, which
  is `adf`'s concern (0023).
- **Committed wrappers that run the plugin's copy,** so the terminal keeps the commands. Each wrapper
  has to find the versioned cache folder, so it's machinery again, in every project.
- **One library for both installs,** finding the project from the working directory. It needs no
  rewrite in the build. Declined: the committed scripts would stop working from outside the
  repository, and nothing gains from that.
