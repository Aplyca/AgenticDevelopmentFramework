# 0045: An upgrade runs a script from the new release, and the developer approves only what needs a person

- **Status:** accepted
- **Date:** 2026-10-18
- **Amends:** [0027](0027-worktree-scripts-as-plugin-commands.md) — what `bin/` carries and where it
  comes from; [0028](0028-plugins-are-the-source.md) — how an upgrade diffs a committed install's
  machinery

## Context

`/adf:upgrade` is a procedure an agent follows by hand. An adopting project on the packaged install,
with six modules, moved from v2.2.0 to v2.4.0
([#86](https://github.com/aplyca/AgenticDevelopmentFramework/issues/86)):

- **The agent found the releases by hand:** `gh release list`, a full clone,
  `git rev-parse 'vX.Y.Z^{commit}'`, and an `awk` over `CHANGELOG.md`.
- **It merged eight files one at a time** with `git show OLD:path`, `git show NEW:path`, and
  `git merge-file`. Six merged cleanly. `AGENTS.md` and `.claude/rules/deployment.md` had two
  conflicting hunks each.
- **The rest was mechanical too:** rerunning the `docker` and `e2e` installers, moving the
  marketplace's `ref` and adding `autoUpdate` (0041), dropping allow rules a broader one now covered,
  `link-reference-docs.py --packaged`, and the restamp.
- **The developer approved a per-file plan** whose rows were mostly "clean merge". Two conflicts and
  the new ask rules for the project's tasks (`dev-env`'s `SPECIFICATION.md` C9 and C10) needed a
  person.
- **The hook smoke test failed with `unbound variable`.** The hooks use `set -u`, and Claude Code
  always sets `CLAUDE_PLUGIN_ROOT` and `CLAUDE_PROJECT_DIR`; the agent hadn't exported them. That's
  a gap in the test, not in the hooks.

Each step costs agent calls and a chance to slip, and none of them needs judgment. A design review on
the issue found what a script has to get right before it can take them over:

- **The pinned plugin is the old release.** An `adf-upgrade` command in `bin/` is code from OLD
  upgrading to NEW, so it can't know the moves or migrations NEW added. The skill already reruns the
  module installers from NEW for this reason. The skill itself is old too.
- **`bin/` is generated** (0027): every command there is a module's script, built by
  `scripts/build-plugins.sh`. An upgrade command isn't a module's, and a committed install may not
  have the plugin's commands on its path.
- **`git show OLD:path` isn't always the merge base.** It is for `skeleton/` and
  `modules/*/files/`. A committed install's machinery comes from `build-committed.py` (0028), so both
  sides have to be built. Renamed folders (`scripts/agent` → `ops/agent`), files the project deleted,
  and new files are most of the work; `git merge-file` is the easy part.
- **Release-specific steps don't belong in one script.** "Add `autoUpdate`" is a step of one release.
  A single script would collect every release's special case.
- **"Covered" allow rules need a narrow definition.** A permission change is exactly what the
  developer should still see.
- **A clean merge can still be wrong,** a duplicated section in `AGENTS.md` for one, so the reviewer
  needs to know where to look.

## Decision

### 1. A thin command in the plugin, the real script in the framework

- **`adf-upgrade [<tag>] [--dry-run] [--offline] [-- <script options>]`** is a command in
  `plugins/adf/bin/`, on the Bash tool's PATH while `adf` is on, as `adf-worktree-new` is (0027). It
  does three things and nothing else:
  1. **Finds a framework checkout with history.** In order: `ADF_FRAMEWORK`, a checkout the developer
     names; the marketplace's `installLocation`, when the marketplace was added from a local clone
     with full history; otherwise a bare clone cached per user at
     `${XDG_CACHE_HOME:-$HOME/.cache}/adf/framework.git`, from the framework's GitHub repository (or
     `ADF_FRAMEWORK_URL`, for a fork). It runs `git fetch --tags --prune` there, unless `--offline`.
     It never checks out anything in the checkout: a bare clone has no working tree to dirty, and a
     developer's own clone keeps its branch.
  2. **Resolves NEW:** `<tag>`, or the newest `v*` tag. `--unreleased <ref>` runs a commit that isn't
     a release, for working on the framework, and the stamp then carries its SHA alone.
  3. **Runs the script from NEW:** `git archive <NEW>` into a temporary folder, then
     `python3 <tree>/scripts/upgrade.py <repo> --history <checkout> --protocol 1`, passing every
     other option through. The folder is removed afterwards.
- **The cache isn't in the plugin's data folder.** The Bash tool gets no `CLAUDE_PLUGIN_ROOT` or
  `CLAUDE_PLUGIN_DATA` (0027, finding 4), and a committed install runs the script without the plugin.
- **Old wrappers keep working.** The wrapper is old code as well, so its contract with the script is
  fixed and small: a project, a history checkout, a protocol number, and options passed through. A
  new option reaches the script through an old wrapper. A script that drops a protocol says to update
  the plugin first and stops.
- **The real script is `scripts/upgrade.py` in the framework repository,** beside
  `build-committed.py` and `link-reference-docs.py`, which it calls. It upgrades a project to **its
  own release**: NEW is the tree it runs from, and a checkout whose `HEAD` isn't that release's tag
  needs `--unreleased`. A committed install, or another AI tool where the plugin's commands aren't on
  the path, runs it directly from a checkout at the release:
  `python3 <framework>/scripts/upgrade.py <repo> [--dry-run]`. `docs/UPGRADING.md` documents that
  route.
- **The wrapper's source is `scripts/adf-upgrade.sh`,** written by hand. `scripts/build-plugins.sh`
  gains a second kind of command beside the modules': a framework command, listed in the build
  (`FRAMEWORK_COMMANDS = {"adf-upgrade": "scripts/adf-upgrade.sh"}`) and copied to
  `plugins/adf/bin/adf-upgrade` under the generated header. The checks 0027 set apply to it: the
  name starts with the plugin's, it loads nothing beside itself, and `.generated` still lists `bin`,
  so the drift check covers it. It has no project-side copy for a committed install to run instead:
  the committed route is the script itself.
- **The script's floor is v2.0.0,** the first release whose plugins are the source (0028) and whose
  stamp lives in `AGENTS.md` (0024). Below it, the script says so and stops, and the skill's manual
  procedure moves the project to v2.0.0 first.
- **Preconditions.** The real run refuses a dirty working tree, the default branch, and a hub's main
  checkout; the dry run touches nothing and runs anywhere. It exits 0 when it ran — the report says
  what needs a person — 2 when it refused, and 1 on an error.

### 2. Old and new copies, per install

The script builds three trees, OLD, NEW, and the project's, at the same paths, and acts on each path
by its bucket.

- **The project's own layer, either install:** `git show <OLD>:<source>` and
  `git show <NEW>:<source>` for each path in `skeleton/` and in `modules/<installed>/files/`, mapped
  into the project by dropping the prefix. A module chosen in this upgrade has no OLD.
- **A committed install's machinery:** `build-committed.py` from each release's own tree, each into an
  empty folder, with the stamp's modules for OLD and the installed and chosen ones for NEW. A packaged
  install skips the machinery, as Step 3 of the skill does today.
- **The buckets move into the script as data,** at NEW: the taxonomy in `docs/UPGRADING.md` becomes a
  table the script reads, and the static checks keep the two equal. A path the table doesn't name is
  **merge required**, the safe default.
- **Per path:**

  | Upstream (OLD → NEW) | The project's copy | Action |
  |---|---|---|
  | changed, safe to overwrite | equal to OLD | write NEW |
  | changed, safe to overwrite | edited | 3-way merge, listed as edited machinery |
  | changed, merge required | any | `git merge-file` (labels `project`, `vOLD`, `vNEW`): clean, or conflicts left marked |
  | changed | deleted by the project | nothing; listed for the developer |
  | added | absent | write NEW (additive) |
  | added | present | nothing; NEW saved beside the report and listed |
  | deleted | equal to OLD | delete |
  | deleted | edited | keep; listed |
  | renamed (`git diff -M` on the source) | at the old path only | `git mv`, then the changed rule with OLD's old path as the base |
  | renamed | at both paths | nothing; listed |

  Project-owned paths are never read. Binary files are written or listed, never merged. Executable
  bits follow NEW.
- **Folder moves are migrations, not renames.** A module that moved its folder names the old one in
  `module.json`'s `moved_from` (0032), and that release's migration does the `git mv` before any
  merge runs, so the merges see the new paths. A committed install's machinery has no rename
  detection: two builds show a delete and an add, and the delete rule keeps an edited copy.
- **Module installers rerun from NEW** (`clickup`, `docker`, `e2e`), after the merges, as today.

### 3. Per-release migrations

- **A release-specific step is a migration script:** `scripts/migrations/v<X.Y.Z>/NN-<slug>.py`.
  Work not yet released keeps its migrations in `scripts/migrations/unreleased/`, and the release
  renames the folder when it writes the changelog's heading (0017).
- **The CHANGELOG entry's Migration text names its script,** and the static checks fail on a
  Migration bullet, in an entry from the first release with the script on, that names neither a
  script nor "by hand".
- **Each one is idempotent.** It reads the project's state first and returns one of: applied, already
  done, or needs the developer, with the text to show. It declares whether it runs before the merges
  (moves, splits) or after (settings).
- **The script runs every migration after OLD up to NEW,** in version order, then by `NN`.
- **What every upgrade does stays in the script:** setting `ref`, the reference links, the restamp,
  the checks. `autoUpdate` (0041), the `ops/agent/` move (0032), and the `PARALLEL-AGENTS.md` split
  (0044) become migrations of their releases. The part of a migration that needs judgment — an edited
  copy of the guide, a task C9 names — returns "needs the developer", never a guess.
- **Each migration has a functional test** in `evals/`: a fixture before, the state after, and a
  second run that changes nothing.

### 4. Dropping covered allow rules

The script removes an allow rule only when all of these hold:

- **Both rules are in the same `permissions.allow` list,** in the committed `.claude/settings.json`.
  Never `settings.local.json`, the user's settings, or two different files.
- **The broader rule is `Bash(<prefix> *)`,** or its `:*` spelling, and `<prefix>` has no wildcard.
- **The covered rule is `Bash(<prefix> …)`:** its specifier starts with `<prefix>` and a space.
  `Bash(make *)` covers `Bash(make test)` and `Bash(make test *)`. It doesn't cover `Bash(make)` or
  `Bash(makefile-lint)`.
- **Only `Bash`.** `Read`, `Edit`, and `WebFetch` rules match paths and domains by other rules, and
  aren't touched.
- **Never `ask` or `deny`.** Deny and ask win over allow, so dropping an allow rule a broader allow
  covers changes nothing that runs. That's why it needs no approval. Every other permission change
  does.

The report lists each dropped rule beside the rule that covers it.

### 5. The smaller approval gate

This amends the **"Plan before touching"** ground rule of `/adf:upgrade`
(`plugins/adf/skills/upgrade/SKILL.md`), and replaces its Step 4, "Present the plan":

> **Approve what needs a person.** The upgrade changes files only on its own branch, and the draft
> pull request is the full record. Clean merges and scripted steps apply without a plan row. The
> developer approves the module choices, each conflict's resolution, and each permission-rule
> change, before anything is committed.

The skill's flow becomes:

1. **Dry run** on the branch's starting point. The report shows the releases, what they bring, the
   modules not installed with the skill's recommendation, and what will need a person. The developer
   names the benefit and chooses modules. That's the first approval.
2. **The run** applies everything clean, leaves conflicts marked, and writes the report.
3. **The skill keeps the judgment:** it proposes a resolution for each conflict, checks the project's
   tasks against new ask rules (C9, C10), and works through what the migrations returned.
4. **One approval** covers the conflict resolutions, the permission changes (each added or removed
   rule that changes what runs without a prompt, from an installer, a migration, or the skill), and
   the draft pull request. A rejected rule is reverted before the commit. An upgrade with no
   conflicts and no permission changes asks once for the modules and once for the pull request.

**The skill defers to its new release.** The `/adf:upgrade` that runs is the pinned one, as old as
the wrapper. When NEW's `plugins/adf/skills/upgrade/SKILL.md`, in the archived tree, differs from its
own, it reads that copy and follows it from step 2 on. It's the same tagged release the script comes
from, which the developer chose.

### 6. The report

The script writes `report.md` and the same content as `report.json` to
`$(git rev-parse --git-dir)/adf-upgrade/`, outside the working tree, and prints the Markdown. The PR
body is built from it. Sections, in order:

- **Header:** `vOLD (sha) → vNEW (sha) · install: packaged | committed · modules: <list>`, and
  `dry run` when it is one.
- **Releases:** each version in between, with each CHANGELOG entry's title, its Upgrade impact, and
  whether its Migration is scripted.
- **Needs you:**
  - **Conflicts:** each file with its number of conflicting hunks.
  - **Permission changes:** each rule added or removed, its list, and what added or removed it.
  - **Modules:** the ones not installed.
  - **Files to decide:** the rows of the table in 2 that end in "listed", each with why.
  - **Migrations:** each one that returned "needs the developer", with its text.
- **Applied:**
  - **Clean merges:** each file with its hunk count — the hunks between the project's copy before and
    after — so the reviewer knows where to look.
  - Files overwritten, added, deleted, and renamed.
  - Migrations applied and already done, by version and slug.
  - Installers rerun.
  - Allow rules dropped, each with the rule that covers it.
  - The pin (`ref`, `autoUpdate`), the reference links, and the stamp.
- **Checks:** the settings JSON parses, and each hook's smoke test passes, run with
  `CLAUDE_PLUGIN_ROOT` (NEW's `plugins/adf/` for a packaged install) and `CLAUDE_PROJECT_DIR`
  exported.
- **On each machine:** the commands 0041 names, after the merge.
- **Follow-ups:** the work the release needs after the merge, each in its own session — for example
  `/adf-dev:dev-env set up` when `dev-env`'s `SPECIFICATION.md` changed, or `/adf-dev:e2e audit` for
  `e2e`'s. Each item in `report.json` has `command`, `why`, `source` (the release and entry, the
  migration, or the module), `plugin`, and `when` (`after-merge`). It's the list
  [#89](https://github.com/aplyca/AgenticDevelopmentFramework/issues/89) records for `/adf:wrap-up`
  to offer; that change decides how.

## Consequences

- **Positive:**
  - The deterministic part of an upgrade costs one command, not dozens of agent calls, and runs the
    same way every time.
  - The code that runs is always the new release's: the script, its migrations, and its skill.
  - A committed install, or another AI tool, gets the same upgrade without the plugin.
  - The developer approves what needs a person; the report points the reviewer at each clean merge.
  - Each release's special case lives with its CHANGELOG entry, tested, and runs once.
- **Negative / cost:**
  - **A script to maintain,** with its taxonomy, and a migration and test for each release step that
    can be scripted.
  - **The first upgrade to the release that ships it runs by hand,** from the old skill. The old
    plugin has no wrapper.
  - **A clone per user** in the cache, and the network on every run unless `--offline`.
  - **Running a release's code before review.** The script runs NEW's code on the developer's
    machine before the pull request is reviewed. The skill already ran NEW's installers; the
    developer chose the tag, and nothing lands without the review.
  - **Fewer rows to read.** A clean merge that's wrong reaches the pull request without a plan row;
    the hunk counts are the mitigation.

## Alternatives considered

- **Put the whole upgrade in the plugin's `bin/`.** Declined: the pinned plugin is OLD, so it would
  upgrade with the old release's knowledge, and `bin/` isn't on a committed install's path.
- **Keep the per-file plan** and script only the merges. Declined: the developer still approves rows
  that need no judgment, which is the cost #86 reports.
- **One script with every release's steps.** Declined: it would grow by each release's special case
  and run checks for releases the project passed long ago.
- **Drop any allow rule another rule might cover,** across lists or tools. Declined: only the narrow
  case is provably a no-op, and anything else is a permission change the developer should see.
- **Cache the checkout in the plugin's data folder.** Declined: the Bash tool doesn't get its path,
  and a committed install runs the script without the plugin.
