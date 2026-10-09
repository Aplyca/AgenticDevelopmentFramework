---
name: upgrade
description: Upgrade a repository that already adopted the Aplyca framework skeleton (and any optional modules) to a newer version, using the three-bucket file taxonomy (overwrite / merge / project-owned), OLD_SHA → NEW_SHA diff discipline, and the changelog's migration steps — and offer the optional modules the project doesn't have yet. Use when asked to upgrade, sync, or update the agentic framework or skeleton in a repo.
---

# Upgrade an adopted repository to a newer skeleton version

Automates `docs/UPGRADING.md` from the framework repo. Read that document for the full rationale;
this skill is the executable procedure. The upgrade is deliberate and file-by-file — there is no
blind sync.

## Ground rules

- **Never commit to the default branch.** Work on a feature branch (suggest
  `chore/skeleton-upgrade-<NEW_SHA>`); deliver a reviewable draft PR.
- **In a hub repository, work in a worktree.** When the parallel-agents module is installed
  (`scripts/agent/worktree-new.sh` exists), the main checkout is the hub and the protect-hub hook
  stops edits there. Run this from a session in a worktree of its own — dispatch it like any task
  (`scripts/agent/worktree-new.sh chore/skeleton-upgrade-<NEW_SHA> --no-start`) — and if you were
  started in the main checkout, say so and stop.
- **Plan before touching.** No file is modified until the user approves the per-file plan.
- **Modules are offered, never imposed.** Recommend the ones the facts support; the developer chooses.
- **An upgrade needs a nameable benefit.** If the user can't name one, say so and suggest
  cherry-picking the one or two changes they actually want.

## Step 1 — Establish OLD_SHA and the installed modules

Read the baseline from the stamp on the first line of the target's `AGENTS.md` — of `CLAUDE.md` in a
project adopted before v2.0.0 (decision 0024):
`<!-- Skeleton source: <vX.Y.Z> · <SHA> (<date>) · modules: <list> -->`. OLD_SHA is the commit; stamps
from before v1.0.0 have no version (and older ones no `modules:` part —
treat it as `none`, and check for module files on disk: `.github/pull_request_template.md`,
`.githooks/pre-push`, `scripts/agent/`, a `clickup` server in `.mcp.json`, the docker rules in
`.claude/settings.json`).

For the `clickup` module, rerun `modules/clickup/install.sh <repo>` from NEW_SHA instead of copying:
it merges new read-only patterns into `.claude/settings.json` and keeps everything else. For
`docker`, rerun `modules/docker/install.sh <repo>` the same way, besides its file changes.

If the line is missing, infer the baseline from `git log` on skeleton-derived files (rules, skills,
agents) and confirm the inferred SHA with the user before proceeding.

**The install** (decision 0016): `· install: packaged` in the stamp, or the plugin in
`enabledPlugins` — `adf@aplyca`, or one of its old names, `aplyca-adf@aplyca` (until v2.0.0) or
`aplyca-framework@aplyca` (until v1.0.0) — means the skills, agents, workflows, and hook scripts come
from the pinned plugin. Otherwise the install is committed.

## Step 2 — Locate the framework source and NEW_SHA

A framework checkout with its full history: the marketplace's `installLocation` (in
`claude plugin marketplace list --json`) when the marketplace was added from a local checkout of the
framework repository, else a **full** clone of `https://github.com/aplyca/AgenticDevelopmentFramework`
(not shallow — the diff needs history). A marketplace added from GitHub sits at the release the
project pins, so it can't show what's newer.

A project moves **from release to release** (decision 0017): NEW_SHA is the commit of the newest
release tag (`git -C <framework-root> tag --list 'v*' --sort=-v:refname | head -1`), unless the
developer asks for the unreleased head: `git -C <framework-root> rev-parse --short '<tag>^{commit}'`.
Not `git rev-parse <tag>`, which gives an annotated tag's own ID — never a commit, so wrong in the
stamp and the branch name. Say whether the jump crosses a major version — those carry
steps the team has to take.

Read `CHANGELOG.md` entries between OLD_SHA and NEW_SHA. Each entry's **Upgrade impact** pre-classifies
changes into the buckets below, and some entries carry **Migration** steps that must happen even for
files the project customized. Summarize for the user what the upgrade brings before doing anything.

**Offer the modules the project doesn't have.** List the modules at NEW_SHA (`modules/README.md`)
that aren't installed — a project adopted before modules existed has none — and recommend from the
repository's facts, by the same rules as `/adopt` Step 3:

- `github` — the repository is on GitHub
- `git-hooks` — the team wants local gates that every git client runs
- `clickup` — requirements arrive as ClickUp tasks (`app.clickup.com` links in pull requests, commits,
  or the README; a `clickup` server in `.mcp.json`)
- `parallel-agents` — several agent sessions may work on the repository at once: each task gets its
  own worktree, branch, pull request, and session, and the main checkout only dispatches
- `docker` — the local stack runs on Docker Compose (a Compose file or a Dockerfile), or the team
  wants a containerized local environment: `/dev-env` sets it up, gives each worktree its own stack,
  and diagnoses or resets it; destructive docker commands ask first

Say why each recommendation fits, and what each one costs. The chosen ones join this upgrade. On a
release with `adf-connect` (decision 0023), offer it the same way when the project works with a
tracker other than GitHub Issues or ClickUp, or with services agents should read: turn on
`"adf-connect@aplyca": true` in `enabledPlugins`, and list `/adf-connect:connect <service>` as a
follow-up.

**If the developer chooses `parallel-agents`,** do the whole upgrade in a worktree of its own, created
with plain git since the module's script isn't there yet:
`git worktree add -b chore/skeleton-upgrade-<NEW_SHA> ../chore-skeleton-upgrade-<NEW_SHA> <base>`.
Edit files under that path and run git with `-C <that path>`. Once the module is installed, the
protect-hub hook stops edits in the main checkout, so the main checkout stays a clean hub from the
first commit.

Uncommitted changes in the main checkout don't follow into the worktree. Check `git status` there
before creating it. The usual one is the plugin setting the install left in `.claude/settings.json`:
make the same change in the worktree, then restore the main checkout's copy
(`git restore .claude/settings.json`), so the hub starts clean and the first pull after the merge
doesn't stop on it. List both moves in the plan. Anything else uncommitted there is the developer's:
ask, and never discard it.

**Offer the other install, when it fits** (decisions 0016, 0018; `docs/SETUP.md` § Packaged install):

- **Committed → packaged** — recommend it to a team that works in Claude Code only, since packaged is
  the default for new projects: remove the skills (a module's `/dispatch` included, when the plugin
  carries it), agents, workflows, hook scripts, and reference docs the plugin carries — only those
  unchanged since OLD_SHA;
  one the team edited stays, under a name of its own, or goes upstream — and the `hooks` block. Add
  the pinned marketplace and `adf`, the names note in `.claude/rules/claude-code.md`, the full names in
  `DEV-SETUP.md`'s key commands, and `install: packaged` in the stamp, then add the plugin's read
  rule and run `link-reference-docs.py --packaged`, both in Step 5. An installed module whose
  `module.json` names another plugin (`adf-dev`, decision 0023) switches the same way: its
  committed skills go, and that plugin is turned on with its read rule.
- **Packaged → committed**, when the team adds another AI tool or needs Claude Code's cloud sessions:
  copy the machinery (with the installed modules' skills), the reference docs, and the `hooks` block
  back, remove `install: packaged`, the
  names note, the plugin's read rule, every other `<plugin>@aplyca` (`adf-dev`) with its read rule,
  and the `adf:` and `<plugin>:` prefixes in `DEV-SETUP.md`, and run
  `python3 <framework-root>/scripts/link-reference-docs.py <repo> --committed`.
  Keep `adf` turned on and pinned, for `/adf:upgrade`.
- **Record the switch** — it changes how the team works — as a process decision in the same pull
  request: the next `docs/process/NNNN-<slug>.md` from `docs/process/0000-pdr-template.md`, with its
  row in `docs/process/README.md`. Say why the team switches, what changes for them (the names they
  type, Claude Code only, no cloud sessions — or the reverse), and how to switch back; ask who the
  deciders are. It amends the install chosen at adoption, so mark PDR-0001's status as amended by it.

**The plugin's old names.** The plugin was `aplyca-framework` until v1.0.0 and `aplyca-adf` until
v2.0.0 (decision 0023). When the new release is v2.0.0 or later and the project still names an old
one, rename it in this upgrade — everywhere the project names it:

- **`enabledPlugins`:** `adf@aplyca` replaces the old key. Claude Code may already have rewritten it,
  from the marketplace's `renames` map, as an uncommitted change: commit that.
- **The read rule:** `Read(~/.claude/plugins/cache/aplyca/adf/**)` replaces the old folder's rule.
- **The names people type:** `/aplyca-adf:triage` becomes `/adf:triage` and `@aplyca-adf:code-reviewer`
  becomes `@adf:code-reviewer` — in the names note, `DEV-SETUP.md`'s key commands, and any
  other doc of the project's that names them (search for `aplyca-adf:`).

Give the developer the commands for each machine after the merge: `/plugin install adf@aplyca` once
in a session (a marketplace from GitHub doesn't fetch a renamed plugin on its own), then
`claude plugin uninstall aplyca-adf@aplyca --scope project`. Until the change merges, teammates still
on the old name have the old `/upgrade`.

**From `CLAUDE.md` to `AGENTS.md`** (v2.0.0, decision 0024). When the new release's skeleton has no
`CLAUDE.md` and the project has one, Claude Code reads that file instead of `AGENTS.md`. Move it in
this upgrade:

1. **The stamp** moves to `AGENTS.md`'s first line; the restamp in Step 5 writes it there.
2. **The Claude Code layer** becomes `.claude/rules/claude-code.md`. Take the new skeleton's copy and
   reapply the project's customizations from its `CLAUDE.md`: the sections match, and the packaged
   names note goes with them. This is a Merge.
3. **Anything else the team added to `CLAUDE.md`:** project facts go to `AGENTS.md`, Claude-specific
   instructions to the rule. Show the developer where each part went.
4. **Delete `CLAUDE.md`.**

Tell the team two things:
- **The version floor:** every machine and CI job needs Claude Code v2.1.281 or later.
- **No `CLAUDE.md` or `CLAUDE.local.md` above the repository or in it.** Each developer moves or
  removes theirs, or sets **Project instructions** to `claude-md-and-agents-md` in `/config`. The
  session-context hook warns until they do.

**No `GEMINI.md`** (v2.0.0, decision 0025). When the new release's skeleton has no `GEMINI.md` and the
project has one:

- **Unchanged since OLD_SHA:** delete it. Antigravity reads `AGENTS.md` natively.
- **Customized:** move what's shared into `AGENTS.md` and what only Antigravity needs into
  `.agents/rules/antigravity.md`, with `trigger: always_on` frontmatter. Show the developer where each
  part went, then delete it.
- **The team uses Gemini CLI:** add the skeleton's `.gemini/settings.json`, which points Gemini CLI at
  `AGENTS.md`, or merge its `context.fileName` into an existing one.

**Check where the plugin is turned on.** The upgrade's pull request must leave
`"enabledPlugins": {"adf@aplyca": true}`, with its `aplyca` entry in
`extraKnownMarketplaces`, committed in `.claude/settings.json`:

- **Already committed:** nothing to do.
- **Uncommitted, left by the install:** commit it with this upgrade — in the worktree, for a hub.
- **Missing:** this session got the plugin from a user- or local-scope install. Offer to add both
  entries in this upgrade (the snippet in the plugin's README § For teams), so the plugin is on for
  this project and its team only — and in every worktree of a hub. After the merge, the developer
  removes a user-scope copy with the commands in that README's § Install.

## Step 3 — Classify every changed file

`git -C <framework-root> diff --name-status OLD_SHA NEW_SHA -- skeleton/ modules/<each installed module>/files/`
gives the changed set (module paths map into the repo by dropping `modules/<name>/files/`). In a
packaged project, leave out what the plugins carry — `.claude/skills/` (a module's skill too, when
the new release's plugin has it in `<framework-root>/plugins/adf/skills/`, as it has
`dispatch` from decision 0020 on, or in the plugin its `module.json` names, such as
`<framework-root>/plugins/adf-dev/`, decision 0023), `.claude/agents/`, `.claude/workflows/`, `.claude/hooks/` except `config.sh`, and, when the new
release carries them in `<framework-root>/plugins/adf/docs/`, the reference docs in `docs/`
(decision 0019) — and never add a `hooks` block to the settings. Classify per the taxonomy in `docs/UPGRADING.md`:

| Bucket | Typical contents | Action |
|---|---|---|
| **Safe to overwrite** | `.claude/skills/*`, `.claude/agents/*`, `.claude/workflows/*`, hook scripts and helpers (everything in `.claude/hooks/` but `config.sh`), universal rules, the framework reference docs (`docs/COST-MODEL.md`, `MCP-INTEGRATION.md`, `MEMORY-STRATEGY.md`, `SPEC-MODEL.md`), `specs/_templates/*` (if unmodified), `docs/process/0000-pdr-template.md`, module scripts | Copy verbatim from the new version |
| **Merge required** | `AGENTS.md`, `.claude/rules/claude-code.md`, `.gemini/settings.json`, `CONTRIBUTING.md`, `.claude/settings.json`, `.claude/hooks/config.sh`, customizable rules, `.claudeignore`, `docs/CONSTITUTION.md`, `specs/README.md`, `docs/process/README.md`, `docs/reference/README.md`, `docs/TRACKER-INTEGRATION.md`, `docs/getting-started/DEV-SETUP.md`, module config (`worktree.conf`, the PR template, `branch-policy.yml`, `.githooks/pre-push`) | 3-way merge: reapply the project's customizations on top of the new template |
| **Project-owned** | Spec folders and legacy specs, ADRs, PDRs, project docs, `docs/reference/*` pages, everything the team authored | Never touched |

**Newly chosen modules** are **additive**: copy `modules/<name>/files/` at NEW_SHA without overwriting
(merge a collision such as an existing PR template), except `clickup`, which installs with
`modules/clickup/install.sh <repo>`; `docker` copies, then runs `modules/docker/install.sh <repo>`.
In a packaged project, a module whose skills the release's plugins carry leaves its `.claude/skills/`
out, and the plugin its `module.json` names, when that isn't `adf`, is turned on:
`"<plugin>@aplyca": true` in `enabledPlugins` and `Read(~/.claude/plugins/cache/aplyca/<plugin>/**)` in
`permissions.allow`. Each module's
`MODULE.md` § Customize steps join the plan's
checklist — for `parallel-agents`, `worktree.conf` (only `BASE_BRANCH` and `SETUP_CMD` unless worktrees
run a server) and the dispatcher line in `AGENTS.md` § Delivery rules; for `docker`, `/dev-env set up`
as a follow-up in a new session once the stamp names the module.

Files deleted upstream: propose deletion only if the target's copy is unmodified from OLD_SHA;
otherwise flag for the user. Never delete `.agents/skills`: the link to `.claude/skills` left the
skeleton because the Claude Directory accepts no symlinks, and `/adopt` now creates it. Files that moved (e.g. `specs/_template.md` → `specs/_templates/`)
follow the changelog's migration notes.

## Step 4 — Present the plan

One table: `file → bucket → action → risk note`, plus the changelog's migration steps as their own
checklist, the newly chosen modules with their customize steps, the plugin setting when it's
being added, and an install switch with its PDR. For merge-required files, show which customizations were detected (diff of the target file
vs the OLD_SHA version) and confirm they will survive. Wait for approval.

## Step 5 — Execute

- Bucket 1: copy verbatim. Keep executable bits on scripts.
- Bucket 2: apply the new template, then reapply each detected customization; where the new template
  restructured a section, place the customization where it now belongs and flag it in the PR body.
- Migration steps from the changelog, in order.
- Newly chosen modules: copy or install them, then their customize steps.
- An install switch, when the developer accepted it: the removals or copies, the settings, the
  names note and the stamp, and its PDR.
- The plugin setting, when the developer accepted it: merge both entries into `.claude/settings.json`.
- Pin the new release: set the marketplace's `"ref"` in `.claude/settings.json` to `v<X.Y.Z>` (add it
  if the project has none). In a packaged project that one line upgrades the plugin's skills, agents,
  workflows, hooks, and reference docs; in a committed one it keeps the plugin's copies at the same
  release as the committed files.
- Packaged, on a release that carries the reference docs: run
  `python3 <framework-root>/scripts/link-reference-docs.py <repo> --packaged v<X.Y.Z>`. It points the
  files that name a reference doc at the new release, and lists the other files that still name one
  and the reference docs still in `docs/`. A copy unchanged since OLD_SHA goes; one the team edited
  is the developer's call — under a name of its own, or the committed install. Add
  `Read(~/.claude/plugins/cache/aplyca/adf/**)` to `permissions.allow` in
  `.claude/settings.json` if it isn't there: the plugin's skills and agents read the docs from its
  folder, and Claude Code asks first without it. Add the last sentence of `docs/SETUP.md`'s names
  note to the project's, if it lacks it.
- Packaged, with the parallel-agents module, on a release whose plugin carries `/dispatch`
  (`<framework-root>/plugins/adf/skills/dispatch/`): delete the committed
  `.claude/skills/dispatch/` when it's unchanged since OLD_SHA. One the team edited is the
  developer's call — under a name of its own, or upstream as a change to the framework.
- Packaged, with an installed module whose `module.json` at the new release names a plugin other than
  `adf` (`adf-dev`, decision 0023): turn that plugin on — `"<plugin>@aplyca": true` in
  `enabledPlugins`, `Read(~/.claude/plugins/cache/aplyca/<plugin>/**)` in `permissions.allow` — delete
  each committed skill it carries that's unchanged since OLD_SHA (the same call as `/dispatch` for one
  the team edited), and give its skills their full names in `DEV-SETUP.md` (`/adf-dev:dev-env`).
- Restamp: `Skeleton source:` → `<new version> · NEW_SHA (<date>) · modules: <list>` — the list includes
  the new ones; a packaged project keeps `· install: packaged`.

## Step 6 — Verify and deliver

1. Run the verification from `/adopt` Step 6: settings JSON valid with nested hook entries; hook
   smoke tests (sample events piped to each script — in a packaged project, the plugin's, with
   `CLAUDE_PROJECT_DIR` set); the stamp on `AGENTS.md`'s first line and no `CLAUDE.md`; skill frontmatter
   uses hyphenated keys only. Re-run the target's lint and tests if config files changed. For a newly
   installed module, its own check: `scripts/agent/worktree-ls.sh` lists the worktrees
   (`parallel-agents`); `.mcp.json` and `.claude/settings.json` parse (`clickup`); the PR template
   exists (`github`); `.githooks/pre-push` is executable and `core.hooksPath` is documented (`git-hooks`);
   `.claude/settings.json` parses and its `ask` list holds the docker rules (`docker`). Packaged, for
   a module whose skills another plugin carries: `<plugin>@aplyca` is on with its read rule, and
   none of the module's skills is committed.
2. Commit with a `docs:` or `chore:` prefix, e.g. `chore: upgrade framework skeleton OLD_SHA → NEW_SHA`.
3. PR body: changelog summary, the plan table as executed, migration steps done, customizations
   reapplied, the modules added and why, the plugin setting if added (with the commands that remove a
   user-scope copy), an install switch and its PDR, anything needing human judgment.
4. Push and open the PR **as a draft, only after the user approves**.
