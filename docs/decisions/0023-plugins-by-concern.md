# 0023: One plugin per concern — the process, development, connections — and modules as each project's switches

- **Status:** accepted; amended by [0025](0025-worktree-scripts-as-plugin-commands.md) (a module's plugin carries its scripts too, as commands, when its `module.json` lists them)
- **Date:** 2026-10-08
- **Amends:** [0009](0009-optional-modules.md) — what a module may be about, and where its skills go;
  [0016](0016-packaged-install.md) — the marketplace lists more than one plugin;
  [0017](0017-semantic-versioning.md) — one version for every plugin in the marketplace;
  [0020](0020-every-task-through-dispatch.md) — which plugin carries a module's skill

## Context

The requests:

- **Issue trackers:** GitHub and GitLab.
- **MCP servers for stack tools:** Contentful, Ibexa, Supabase, Vercel.
- **Skills for technical specialties:** a Docker development environment, frontend, performance.

The question is where each goes: the core plugin, new plugins, or modules.

**The test from 0016 and 0019.** What a project edits is committed; machinery no project edits is
packaged. A project's MCP endpoints, permission rules, CI templates, and stack rules are its own.
Skills, agents, hooks, and mods are machinery.

**What a plugin can't carry.** A plugin can't carry the project's half. The plugin reference
(code.claude.com/docs/en/plugins, checked 2026-10-08) lists what a plugin ships:

- skills, agents, hooks, workflows, mods;
- MCP and LSP servers;
- output styles, monitors, executables;
- `userConfig`.

It doesn't list permission rules, rules files, or instructions.

**Facts that shape the plugins:**

- **Many plugins in one repository.** A marketplace in one repository can list many plugins.
  Anthropic's repositories and `wshobson/agents` (94 plugins) are built that way. A plugin listed by a
  relative path loads from the marketplace's copy, with no install step.
- **A plugin is on or off as a whole.** `skillOverrides` doesn't reach plugin skills, so a project
  can't hide one skill of a plugin it turned on.
- **The listing budget.** Every listed skill's description is in context on every turn. The listing
  has a budget of 1% of the context window (`skillListingBudgetFraction`). Past it, the descriptions
  of the least-used skills are dropped.
- **Every MCP server in a plugin starts when the plugin is turned on.** The only per-server switch
  is a user's `/mcp` toggle, kept in `~/.claude.json`, not in the repository.
- **`userConfig` values are per user.** They're kept in user settings, so a team can't commit a
  project's Supabase `project_ref` or Contentful space through them.
- **Renaming a plugin breaks every install,** unless the marketplace's `renames` map migrates it.
  Claude Code then loads the plugin under its new name and rewrites `enabledPlugins` in the user,
  project, and local settings.
- **Vendor plugins.** `claude-plugins-official` has plugins for GitHub, GitLab, Supabase, and Vercel,
  each with its MCP server. Contentful has a hosted MCP server and no plugin. Ibexa's `ibexa/mcp` is
  experimental, with no hosted server.

**Two shapes were weighed:** one plugin per module, which an earlier draft of this record chose, and
one plugin per concern. Per module gives the finest choice, but a team would explain, turn on, and
allow a plugin for every module.

## Decision

1. **One plugin per concern, all in the `aplyca` marketplace, all at the release's version:**

   | Plugin | Concern | Carries | Today |
   |---|---|---|---|
   | `adf` (`aplyca-adf` until v2.0.0) | The process | The skeleton's skills, agents, workflows, and hooks; the reference docs; the installer; process modules' skills (`parallel-agents`' `/dispatch`) | Built |
   | `adf-dev` | Development | The skills and agents of development modules (`docker`'s `/dev-env`; performance and frontend next) | Built |
   | `adf-connect` | Trackers and services | `/connect`, which writes a project's MCP configuration from a catalog of safe defaults and pre-approves only the tools that read | Built in v2.0.0 |

2. **Modules stay each project's switch and its half.** A module commits what the project owns:
   config, scripts, templates, permission rules, MCP configuration. It names the plugin that carries
   its skills and agents in `modules/<module>/module.json`. A module with neither has no
   `module.json`. Each skill stops where the stamp doesn't name its module, so a plugin turned on for
   one module never acts for another.

3. **How the plugins are built.** Each plugin folder has a hand-written manifest and README. Every
   plugin is listed in the marketplace by hand. `scripts/build-plugins.sh` generates:
   - `adf`'s machinery from the skeleton;
   - every plugin's module skills from the modules that name it;
   - `adf`'s version, copied into the others' manifests.

   Names are unique across every plugin. `adf` never names another plugin's skill.

4. **Turning the plugins on.** A packaged project turns a module's plugin on beside `adf`,
   once however many of its modules it has: `"adf-dev@aplyca": true` in `enabledPlugins`, and
   `Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`. A committed project copies
   the modules' skills and leaves the plugin off.

5. **MCP server definitions stay in the project.** Endpoints differ by project, `userConfig` is per
   user, and a plugin can't turn individual servers off. So a project's `.mcp.json` keeps them,
   written by a module or by `adf-connect`'s `/connect`, with a read-only allowlist, as `clickup` does.
   Other tools read that file too.

   **A spike ruled out the alternative** (2026-10-08, Claude Code 2.1.286, `claude mcp list` on a
   plugin loaded with `CLAUDE_CODE_PLUGIN_DIRS`). The idea was that `adf-connect` would carry the
   server catalog, each server off until a project's settings `env` fills in its URL. What happened:
   - A settings file's `env` does fill a plugin server's `url`: `"${ADF_SPIKE_URL:-}"` expanded from a
     `--settings` file. An untrusted folder's project settings didn't apply, as expected; a trusted
     project's committed settings are expected to behave like the `--settings` file, which wasn't
     observed.
   - A server whose variable is unset is an error, not "not configured". `${VAR:-}` expanding to empty
     reports `Plugin … has an invalid MCP url`. Only a literal `"url": ""` shows `Not configured`.

   So every project with the plugin on would show a failed server for each service it doesn't use.

   A guard that makes every MCP write ask, whatever a project's allow list says, belongs to the
   process, not to `adf-connect`. Confirming outward actions is the core's rule (0005, 0006), and
   committed installs need it too. It's planned as a core hook.

6. **Vendor plugins are recommended, not rebuilt or depended on.** The reasons are 0013's: updates
   outside our changelog, and overlapping skills.

7. **The core is renamed `adf`, a major release, v2.0.0.** It is typed most, so `/adf:triage`
   instead of `/aplyca-adf:triage`. It also avoids "the workflow plugin's workflows". The release
   adds `"renames": {"aplyca-framework": "aplyca-adf", "aplyca-adf": "adf"}` to the marketplace.
   `/aplyca-adf:upgrade` does what `renames` doesn't:
   - moves the read rule to the plugin's new folder;
   - renames the commands in `CLAUDE.md`'s names note and `DEV-SETUP.md`;
   - moves the pin and the stamp.

   As in v1.0.0's rename from `aplyca-framework`, each developer runs `/plugin install adf@aplyca`
   once.

8. **Mods are a later layer.** Each plugin can carry mods for its concern:
   - **`adf`:** a band with the lane, spec folder, phase, and gate; buttons for the approval gate and
     the local check; zero-token `/status` and cost panes.
   - **`adf-dev`:** a pane for the worktree's Docker stack, and a hold on `docker compose down -v`
     that lists the volumes it would delete.
   - **`adf-connect`:** the pull request's CI checks and the linked tracker task.

   They only add to the process: the files and hooks keep working in every tool, because mods draw
   only in the terminal and the desktop app. Ours never approve a tool call.

**Where the requested additions go:**

| Addition | Module | Plugin |
|---|---|---|
| GitHub Issues as the tracker | — (the `gh` CLI, with the skeleton's permissions) | — |
| GitLab | `gitlab`: MR template, GitLab CI secret detection and branch policy, a `glab` permission fragment. GitLab MCP through `/connect`. Also a core fix: `guard-git.sh` drafts `glab mr create` | `adf` (the guard), `adf-connect` |
| Jira, Linear | None needed: `/connect` writes the project's server | `adf-connect` |
| Supabase, Vercel, Contentful | None needed: `/connect` writes the project's MCP server with safe defaults (Supabase `read_only=true`, a non-production project) and a read-only allowlist, and mentions the vendor plugin where one exists | `adf-connect` |
| Ibexa | Deferred while `ibexa/mcp` is experimental | — |
| Docker development environment | `docker`, built now | `adf-dev` |
| Performance, frontend | Modules whose skills and reviewer agents plug into existing phases — `/review` calling a specialty reviewer, the local check — never a second workflow (0013) | `adf-dev` |

## Consequences

- **Positive:**
  - Three plugins to explain, by what they're for, however many modules there are.
  - `/dispatch` simply belongs to the process plugin, so there's no exception.
  - One pinned `ref` covers every plugin, and the drift check keeps each one equal to its sources.
- **Negative / cost:**
  - **A plugin is all or nothing.** A project with `adf-dev` on lists every development skill,
    including those of modules it doesn't have; they stop when called. Keep the development and
    connection skills few, with short descriptions. `/dev-env` is about 500 characters of listing,
    roughly 125 tokens.
  - **Every plugin gets a new version at every release,** changed or not.
  - **A project pinned to a release older than a plugin can't find it.** Claude Code keeps one
    marketplace entry per user, and it follows whichever project declared it last (0016).
  - **The core rename is a major release that every team acts on.**
  - **Not verified at runtime yet:** these were checked against the docs and the build only, not in a
    live session. Confirm them before the release.
    - That `adf-dev` loads from `enabledPlugins` alone.
    - That a bare `/dev-env` reaches `adf-dev:dev-env`.
    - The listing cost, measured with `/context`.

## Alternatives considered

- **Everything in `aplyca-adf`** (0020's rule for every module). Every packaged project lists every
  module's skills, and the listing budget fills.
- **One plugin per module** (`adf-docker`, `adf-perf`, …), the earlier draft of this record. It's the
  finest choice, but every module adds a plugin to explain, turn on, allow, and pin.
- **MCP server definitions in a shared tools plugin.** Every server would start in every project that
  turns it on, endpoints can't be set per project, and the allowlists would still be committed.
  Revisit if the empty-`url` pattern works.
- **A separate repository and marketplace for the new plugins.** It would add a second pin and a
  second folder trust to every project, repeat 0016's one-entry-per-user problem, and need a second
  release process.
- **Independent versions per plugin** (`<plugin>--v<version>` tags). That's more numbers to reason
  about, while a project's pinned `ref` fixes them together anyway.
- **Depending on vendor plugins.** Their updates arrive outside our changelog, and not every stack has
  one.
- **Keeping the core name `aplyca-adf`.** No migration, but the longest prefix stays on the commands
  typed most. **`adf-workflow`** was also weighed and rejected: it collides with the workflows the
  plugin ships.
