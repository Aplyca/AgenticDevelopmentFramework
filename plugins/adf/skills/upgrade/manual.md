# The manual procedure — what the script refuses

`/adf:upgrade` reads this when its dry run refuses: "Below v2.0.0", or a release that "predates the
scripted upgrade". Steps 1–6 do by hand what the script does. What to offer, Bucket 2's merge, the
project's tasks, and Step 6 are in `SKILL.md` beside this file. A project below v2.0.0 also reads
`<this skill's base directory>/before-v2.md`.

## Step 1 — Establish OLD_SHA and the installed modules

Read the baseline from the stamp on the first line of the target's `AGENTS.md` — of `CLAUDE.md` in a
project adopted before v2.0.0 (decision 0024):
`<!-- Skeleton source: <vX.Y.Z> · <SHA> (<date>) · modules: <list> -->`. OLD_SHA is the commit; stamps
from before v1.0.0 have no version (and older ones no `modules:` part —
treat it as `none`, and check for module files on disk: `.github/pull_request_template.md`,
`.githooks/pre-push`, `ops/agent/` or `scripts/agent/`, a `clickup` server in `.mcp.json`, the docker or
e2e rules in `.claude/settings.json`).

For the `clickup` module, rerun `modules/clickup/install.sh <repo>` from NEW_SHA instead of copying:
it merges new read-only patterns into `.claude/settings.json` and keeps everything else. For
`docker`, `e2e`, and `unit`, rerun `modules/docker/install.sh <repo>`, `modules/e2e/install.sh <repo>`, and
`modules/unit/install.sh <repo>` the same way, besides their file changes. Before the docker installer
runs, read the project's tasks as `SKILL.md` § *The project's tasks, with `docker`* says.

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

**Offer the modules the project doesn't have, the other install, and the plugin setting** as
`SKILL.md` § *What to offer* says. When the developer chooses `parallel-agents`, the whole upgrade
runs in a worktree of its own, as that section says.

**Below v2.0.0,** the moves in `<this skill's base directory>/before-v2.md` join this upgrade: the
plugin's old names, `CLAUDE.md` to `AGENTS.md`, and no `GEMINI.md`.

## Step 3 — Classify every changed file

`git -C <framework-root> diff --name-status OLD_SHA NEW_SHA -- skeleton/ modules/<each installed module>/files/`
gives the changed set of the project's own layer (module paths map into the repo by dropping
`modules/<name>/files/`).

**A committed project's machinery** — skills, agents, workflows, hook scripts, reference docs — has
its source in the plugins from v2.0.0 (decision 0028), so that diff doesn't show it. Write it at both
releases, each into an empty folder outside the target, and diff those:

- **NEW:** `python3 <framework-root>/scripts/build-committed.py <new> --modules <installed modules>`.
- **OLD,** from a worktree of the framework at OLD_SHA: the same command when that release has
  `scripts/build-committed.py`; before v2.0.0 it has none, and its machinery is `skeleton/.claude/`
  (all but `rules/`, `settings.json`, and `hooks/config.sh`), the four reference docs in
  `skeleton/docs/`, and each installed module's `files/.claude/skills/`.

`diff -rq <old> <new>` adds those files to the changed set, at the same paths in the project, and
`<new>` is where Bucket 1 copies them from. In a packaged project, skip all this, and leave out of the
changed set what the plugins carry — `.claude/skills/` (a module's skill too, when
the new release's plugin has it in `<framework-root>/plugins/adf/skills/`, as it has
`dispatch` from decision 0020 on, or in the plugin its `module.json` names, such as
`<framework-root>/plugins/adf-dev/`, decision 0023), `.claude/agents/`, `.claude/workflows/`, `.claude/hooks/` except `config.sh`,
a module's scripts the new release's plugin carries as commands (its `module.json`'s `commands`, in
`<framework-root>/plugins/adf/bin/` — the parallel-agents scripts but `worktree.conf`, decision 0027),
and, when the new release carries them in `<framework-root>/plugins/adf/docs/`, the reference docs in
`docs/` (decision 0019) — and never add a `hooks` block to the settings. Classify per the taxonomy in `docs/UPGRADING.md`:

| Bucket | Which files | Action |
|---|---|---|
| **Safe to overwrite** | The `overwrite` globs in `<framework-root>/scripts/upgrade-buckets.json` | Copy verbatim from the new version |
| **Merge required** | The `merge` globs there — checked first, so a path in both merges | 3-way merge: reapply the project's customizations on top of the new template |
| **Project-owned** | The `project-owned` globs there; spec folders, ADRs, PDRs, project docs | Never touched |

A path none of the lists names is a merge. The JSON is what the script reads, so it stays current;
`docs/UPGRADING.md` § File taxonomy explains each bucket.

**Newly chosen modules** are **additive**: copy `modules/<name>/files/` at NEW_SHA without overwriting
(merge a collision such as an existing PR template), except `clickup`, which installs with
`modules/clickup/install.sh <repo>`; `docker`, `e2e`, and `unit` have no files to copy: run
`modules/docker/install.sh <repo>`, `modules/e2e/install.sh <repo>`, or `modules/unit/install.sh <repo>`.
In a packaged project, a module whose skills the release's plugins carry leaves its `.claude/skills/`
out, and the plugin its `module.json` names, when that isn't `adf`, is turned on:
`"<plugin>@aplyca": true` in `enabledPlugins` and `Read(~/.claude/plugins/cache/aplyca/<plugin>/**)` in
`permissions.allow`. Each module's
`MODULE.md` § Customize steps join the plan's
checklist — for `parallel-agents`, `worktree.conf` (only `BASE_BRANCH` and `SETUP_CMD` unless worktrees
run a server) and the "Parallel sessions" line in `AGENTS.md` § Delivery rules; for `docker`, `/dev-env set up`
as a follow-up in a new session once the stamp names the module. A project that already has `docker`
gets the same follow-up whenever the release changed the local environment specification
(`dev-env`'s `SPECIFICATION.md`; the CHANGELOG names it): `/dev-env set up` audits the stack against
it and proposes each gap by requirement ID. Never copy the templates over the project's files — they
are an example of the specification, not the project's stack. For `e2e`, the follow-up is
`/e2e set up`, after `/dev-env set up` when the project has `docker`; a project that already has
`e2e` gets `/e2e audit` when the release changed `e2e`'s `SPECIFICATION.md`. For `unit`, the follow-up
is `/unit set up`, and `/unit audit` when the release changed its `SPECIFICATION.md`.

Files deleted upstream: propose deletion only if the target's copy is unmodified from OLD_SHA;
otherwise flag for the user. Never delete `.agents/skills`: the link to `.claude/skills` left the
skeleton because the Claude Directory accepts no symlinks, and `/adf:adopt` now creates it. Files that moved
(`R` in `--name-status`, e.g. `specs/_template.md` → `specs/_templates/`, or the parallel-agents
module's `scripts/agent/` → `ops/agent/`) follow the changelog's migration notes.

## Step 4 — Present what needs a person

The manual procedure keeps the same gate as the script (decision 0046). Before Step 5, the developer
approves the module choices. After it, before the commit, they approve the conflict resolutions, the
compatibility table, and the permission changes, with the changelog's migration steps, the newly chosen modules' customize
steps, the plugin setting when it's being added, and an install switch with its PDR. List each clean
merge with its hunk count, and the customizations each merge kept (the target file vs the OLD_SHA
version), so the reviewer knows where to look; they need no plan row.

## Step 5 — Execute

- Bucket 1: copy verbatim. Keep executable bits on scripts.
- Bucket 2: as `SKILL.md` § *Bucket 2: reapply the customizations* says.
- Migration steps from the changelog, in order.
- **The parallel-agents module moves to `ops/agent/`** (decision 0032) when the project has
  `scripts/agent/`, in either install — before Bucket 1 copies the scripts, so they land at the new
  path:
  1. `git mv scripts/agent ops/agent` — the whole folder: `worktree.conf`, the committed scripts, and
     any helper the team keeps there.
  2. In `ops/agent/worktree.conf`, any `*_CMD` or `ENV_INFO_CMD` that names `scripts/agent/`.
  3. The comment in `.worktreeinclude`.
  4. `AGENTS.md` § Quick reference: a committed install names `ops/agent/worktree-new.sh` and the
     other two; a packaged one keeps the commands' names (`adf-worktree-new`).
  5. Every other hit of `git grep -n scripts/agent` — docs, CI, settings, a Makefile.
  6. Remove `scripts/` if it's now empty.

  Worktrees branched before the merge keep `scripts/agent/` until they merge; the commands and hooks
  read either folder, so nothing breaks meanwhile.
- With the parallel-agents module (decision 0044), while the project's
  `docs/PARALLEL-AGENTS.md` is still its own copy — it has an `owner:` line and § Shared services —
  split it, in either install, before Bucket 1 copies the guide into a committed one:
  1. Write `docs/SHARED-SERVICES.md` from the module's files at NEW_SHA, and carry over the copy's
     owner line and what the team recorded in § Shared services: everything but the paragraph the
     module's copy had there at OLD_SHA.
  2. Compare the rest of the copy with `modules/parallel-agents/files/docs/PARALLEL-AGENTS.md` at
     OLD_SHA. Unchanged: a packaged project deletes it, and a committed one takes the guide from
     `<new>`. Edited anywhere else: list each edited section for the developer — it moves into
     `docs/SHARED-SERVICES.md`, stays under a name of its own, or goes upstream — and replace or
     delete nothing until they decide.
  3. Wherever the project names § Shared services of `docs/PARALLEL-AGENTS.md`
     (`git grep -n "Shared services"`), name `docs/SHARED-SERVICES.md` instead. Its other mentions of
     the guide stay; in a packaged project, `link-reference-docs.py --packaged` points them at the
     release.
- Newly chosen modules: copy or install them, then their customize steps.
- An install switch, when the developer accepted it: the removals or copies, the settings, the
  names note and the stamp, and its PDR (`<this skill's base directory>/switch-install.md`).
- The plugin setting, when the developer accepted it: merge both entries into `.claude/settings.json`.
- Pin the new release: set the marketplace's `"ref"` in `.claude/settings.json` to `v<X.Y.Z>` (add it
  if the project has none), and add `"autoUpdate": true` to the same `aplyca` entry if it lacks it.
  In a packaged project that one line upgrades the plugin's skills, agents,
  workflows, hooks, and reference docs; in a committed one it keeps the plugin's copies at the same
  release as the committed files. It reaches each machine through the commands in Step 6 (item 5).
- Packaged: run
  `python3 <framework-root>/scripts/link-reference-docs.py <repo> --packaged v<X.Y.Z>`. It points the
  files that name a reference doc at the new release, and lists the other files that still name one
  and the reference docs still in `docs/`. A copy unchanged since OLD_SHA goes; one the team edited
  is the developer's call — under a name of its own, or the committed install. Add
  `Read(~/.claude/plugins/cache/aplyca/adf/**)` to `permissions.allow` in
  `.claude/settings.json` if it isn't there: the plugin's skills and agents read the docs from its
  folder, and Claude Code asks first without it. Add the last sentence of `docs/SETUP.md`'s names
  note to the project's, if it lacks it.
- Packaged, with the parallel-agents module: delete the committed
  `.claude/skills/dispatch/` when it's unchanged since OLD_SHA. One the team edited is the
  developer's call — under a name of its own, or upstream as a change to the framework.
- Packaged, with the parallel-agents module (decision 0027): delete
  `worktree-new.sh`, `worktree-ls.sh`, `worktree-rm.sh`, and `_worktree-lib.sh` from `ops/agent/`
  when none of them changed since OLD_SHA, and keep `worktree.conf`. If the team edited one, the four
  stay together — each script loads `_worktree-lib.sh` from beside it — and the developer decides, as
  for `/dispatch`: while a script stays, its command runs it.
  Name the commands where the project names the scripts — `adf-worktree-new` for
  `ops/agent/worktree-new.sh`, and so on — in `AGENTS.md` § Quick reference and any other doc of
  the project's, and add the commands' sentence of `docs/SETUP.md`'s names note to the project's.
- Packaged, with an installed module whose `module.json` at the new release names a plugin other than
  `adf` (`adf-dev`, decision 0023): turn that plugin on — `"<plugin>@aplyca": true` in
  `enabledPlugins`, `Read(~/.claude/plugins/cache/aplyca/<plugin>/**)` in `permissions.allow` — delete
  each committed skill it carries that's unchanged since OLD_SHA (the same call as `/dispatch` for one
  the team edited), and give its skills their full names in `DEV-SETUP.md` (`/adf-dev:dev-env`).
- Restamp: `Skeleton source:` → `<new version> · NEW_SHA (<date>) · modules: <list>` — the list includes
  the new ones; a packaged project keeps `· install: packaged`.
- The compatibility pass on the merged files, as `SKILL.md`'s scripted step 6 says (decision 0099).
  Its table joins Step 4's approval, before the commit.

## Step 6 — Verify and deliver

`SKILL.md` § *Verify and deliver*, all five items.
