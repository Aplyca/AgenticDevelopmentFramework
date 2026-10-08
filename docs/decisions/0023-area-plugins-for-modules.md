# 0023: Integrations and specialties ship as modules; a module may carry its own opt-in plugin, `adf-<module>`

- **Status:** accepted
- **Date:** 2026-10-08
- **Amends:** [0009](0009-optional-modules.md) — what a module may be about, and that it may carry a
  plugin; [0016](0016-packaged-install.md) — the marketplace lists more than `aplyca-adf`;
  [0017](0017-semantic-versioning.md) — one version for every plugin in the marketplace;
  [0020](0020-every-task-through-dispatch.md) — where a module's skills go

## Context

Three kinds of addition were requested:

- **Issue trackers:** GitHub, GitLab.
- **MCP servers for the services a project's stack uses:** Contentful, Ibexa, Supabase, Vercel.
- **Skills for technical specialties:** a Docker development environment, frontend, performance.

The questions were whether they belong in this repository, and whether they should be plugins.

**What a project edits is committed; machinery no project edits is packaged.** Decisions 0016 and 0019
already sort the skeleton this way. A project's MCP endpoints, permission rules, CI templates, and
stack rules are its own configuration. Skills, agents, and hooks are machinery. A plugin can't carry
the first kind anyway. Claude Code's plugin reference (2.1.286) lists what a plugin ships:

- skills, commands, agents, hooks;
- MCP and LSP servers;
- output styles, workflows, themes, monitors, executables;
- `userConfig`;
- a `settings.json` in which only `agent` and `subagentStatusLine` take effect.

Permission rules and rules files aren't on that list (0016, clarified 2026-10-07).

**Each addition is used by some projects and not others.** Decision 0020 put a module's skills in
`aplyca-adf`, so every packaged project lists them, with or without the module. 0020 counted that cost
for one skill, `/dispatch`. It doesn't scale to a family of specialty skills:

- Every enabled skill's description is in context on every turn.
- The whole listing has a budget of 1% of the model's context window; past it, descriptions are
  dropped, starting with the least-used skills (code.claude.com/docs/en/skills).
- Decision 0016 measured the 25 duplicate listings of a committed project at about 2,600 tokens.

**What Claude Code supports** (code.claude.com/docs/en/plugins, checked 2026-10-08):

- **Many plugins in one marketplace repository.** The `anthropics` repositories and `wshobson/agents`
  (94 plugins) are built that way. A plugin listed by a relative path (`./plugins/x`) loads from the
  marketplace's copy with no install step, so a project turns it on with `enabledPlugins` alone.
- **Per-plugin version tags** (`<plugin>--v<version>`).
- **`dependencies` between plugins,** across marketplaces too, once the root marketplace lists the
  other in `allowCrossMarketplaceDependenciesOn`.
- **Reading a plugin's own files asks first** unless a `Read` rule allows its cache folder (0019).

**Vendors already ship some of this.** Anthropic's official marketplace (`claude-plugins-official`)
has plugins for GitHub, GitLab, Supabase, and Vercel, each bundling its MCP server. Contentful has a
hosted MCP server (`mcp.contentful.com`, OAuth) and no plugin. Ibexa's `ibexa/mcp` package is a
framework for defining your own servers, marked experimental, with no hosted server.

## Decision

1. **One test for every integration or specialty.** Where it goes depends on two questions:

   | | Every project | Opt-in |
   |---|---|---|
   | **The project edits it:** MCP endpoints, permission fragments, CI templates, stack rules | `skeleton/` | a module's `files/` |
   | **No project edits it:** skills, agents, hooks | `aplyca-adf` | the module's own plugin, `adf-<module>` |

2. **A module may be about a stack, a service, or a specialty,** not only a Git host or a way of
   working (0009). It may name a public product (Docker, Supabase); it never carries one project's
   setup.

3. **A module may carry its own opt-in plugin.**
   - **How it opts in.** It declares the plugin with a `plugin.json` beside its `MODULE.md`, outside
     `files/`. The manifest takes `name` (`adf-<module>`), `description`, `category`, and `keywords`.
   - **How the plugin is made.** `scripts/build-plugins.sh` generates it from the module's
     `files/.claude/skills` and `files/.claude/agents` into `plugins/adf-<module>/`, and lists it in
     the `aplyca` marketplace.
   - **The module stays the one source.** A committed install copies its skills, so the tools that
     read `.claude/skills` or `.agents/skills` keep them. A packaged install turns the plugin on, with
     `"adf-<module>@aplyca": true` in `enabledPlugins` and
     `Read(~/.claude/plugins/cache/aplyca/adf-<module>/**)` in `permissions.allow`.
   - **The plugin acts only where it belongs.** Its skills hand over to the committed copy unless the
     project is packaged, and stop where the stamp doesn't name the module.
   - **What a module plugin doesn't carry yet:** hooks and workflows.

4. **`/dispatch` stays in `aplyca-adf`.** Moving it to a plugin of its own would rename what people
   type, a breaking change (MAJOR under 0017), so it waits for the next major release. The build fails
   for any other module that ships skills without a `plugin.json`.

5. **One version for every plugin.** The build copies `aplyca-adf`'s version into each module plugin,
   so a release still sets one number and a project's pinned `ref` covers them all. Per-plugin tags
   and `dependencies` exist but aren't used.

6. **Names are unique across every plugin.** That covers skills, workflows, and agents. A bare
   `/dev-env` must reach one skill, and a committed install puts every module's skills in one
   `.claude/skills/`. `aplyca-adf` never names an opt-in plugin's skill, so the core doesn't depend on
   a plugin a project may not have turned on.

7. **Vendor plugins are recommended, not rebuilt or depended on.** The reasons are 0013's: updates
   outside our changelog, and skills that overlap ours. A stack module commits the project's MCP
   configuration with safe defaults and a read-only allowlist, as `clickup` does. It may recommend the
   vendor's plugin.

8. **The first module plugin is `docker`'s `adf-docker`.** It carries `/dev-env`, which:
   - sets up a Compose stack from verified facts;
   - gives each worktree its own stack with `parallel-agents`;
   - diagnoses a stack signal-first, in `/debug`'s order;
   - resets one smallest step first.

   The module commits a permission fragment. Read-only docker commands run without a prompt, and
   commands that delete containers, volumes, or images ask. Ask rules win over any allow rule, and
   they prompt in auto and bypass modes too (code.claude.com/docs/en/permissions). There is no rule of
   the module's own: the skeleton's `deployment.md` § Docker already loads on Docker and Compose files.

**Where the requested additions go:**

| Addition | Where | Plugin |
|---|---|---|
| GitHub Issues as the tracker | Already works: the `gh` CLI with the permissions in the skeleton's settings | — |
| GitLab | A `gitlab` module: MR template, GitLab CI secret detection and branch policy, a `glab` permission fragment, optional GitLab MCP (`https://gitlab.com/api/v4/mcp`, OAuth). Also a core fix: `guard-git.sh` enforces `--draft` on `gh pr create` and not yet on `glab mr create` | — |
| Jira, Linear | Modules on `clickup`'s pattern, when a team needs one | — |
| Supabase, Vercel | Modules: the project's MCP server with safe defaults (Supabase `read_only=true`, scoped to a non-production project) and a read-only allowlist; the vendor plugin recommended | Only for skills of our own |
| Contentful | A module, the same way; no vendor plugin to recommend | Later, if a skill earns it |
| Ibexa | Deferred while `ibexa/mcp` is experimental | — |
| Docker development environment | `docker`, built now | `adf-docker` |
| Performance, frontend | Modules whose skills and reviewer agents plug into existing phases (`/review` calling a specialty reviewer, the local check) — never a second workflow (0013) | `adf-perf`, `adf-frontend` |

## Consequences

- **Positive:**
  - A project lists only the skills of the modules it chose. `/dev-env` costs about 500 characters
    of listing (roughly 125 tokens), and only where it's turned on.
  - The core stays the same size however many modules there are.
  - One pinned `ref` covers every plugin, and the drift check keeps each plugin equal to its source.
- **Negative / cost:**
  - **More to explain.** A packaged project with the module has two lines more in its settings per
    module plugin, and people type a second prefix (`/adf-docker:dev-env`).
  - **Every plugin gets a new version at every release,** changed or not, and is downloaded again.
  - **A project pinned to a release older than a module plugin can't find it.** Claude Code keeps one
    marketplace entry per user, and it follows whichever project declared it last (0016).
  - **`/dispatch` is the exception** until the next major.
  - **The marketplace lists plugins that work only with their module.** Turned on elsewhere, their
    skills say so and stop.
  - **Not verified at runtime yet:** these were checked against the docs and the build only, not in a
    live session.
    - That a relative-path module plugin loads from `enabledPlugins` alone.
    - That a bare `/dev-env` reaches `adf-docker:dev-env`.
    - The listing cost, to measure with `/context`.

    Confirm them before the release.

## Alternatives considered

- **Everything in `aplyca-adf`** (0020's rule for every module). Every packaged project would list
  every module's skills, and the listing budget fills.
- **A separate repository and marketplace for the area plugins.** It would add a second pin and a
  second folder trust to every project. The one-entry-per-user problem from 0016 would happen twice,
  and there'd be a second release process. Worth revisiting if the area plugins get their own
  maintainers or release cadence.
- **Independent versions per plugin** (`<plugin>--v<version>` tags). That's two numbers to reason
  about, while a project's pinned `ref` fixes them together anyway.
- **Depending on vendor plugins** through cross-marketplace `dependencies`. Their updates arrive
  outside our changelog, Anthropic's marketplace updates automatically, and not every stack has one.
- **Plugins written by hand, packaged only.** Committed installs and other AI tools would lose the
  skills, and there would be two sources to keep in step.
- **`adf-*` plugins that depend on `aplyca-adf`.** `aplyca-adf` is on in every adopted project
  already, and we publish no per-plugin tags for a range to resolve against.
