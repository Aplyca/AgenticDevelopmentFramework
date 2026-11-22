---
name: upgrade
description: Upgrade a repository that adopted the framework to a newer release — overwrite, merge, or keep each file, diff OLD_SHA → NEW_SHA, apply the changelog's migration steps — and offer the modules it lacks. Use when asked to upgrade, sync, or update the agentic framework or its skeleton in a repository.
---

# Upgrade an adopted repository to a newer skeleton version

Automates `docs/UPGRADING.md` from the framework repo, which holds the full rationale; this skill
is the executable procedure. The upgrade is deliberate and file-by-file — there is no
blind sync. The reference files this skill names sit beside the copy of it you follow: in the
release's tree once step 2 of *The scripted upgrade* hands over to that copy.

## Ground rules

- **Never commit to the default branch.** Work on a feature branch (suggest
  `chore/skeleton-upgrade-<NEW_SHA>`); deliver a reviewable draft PR.
- **In a hub repository, work in a worktree.** When the parallel-agents module is installed
  (`ops/agent/worktree.conf` exists, or `scripts/agent/worktree.conf` in a project that hasn't moved
  it yet), the main checkout takes no edits: the protect-hub hook stops them. Started there, say so
  and run `/adf:dispatch` with `chore/skeleton-upgrade-<NEW_SHA>` as the branch, without asking
  first: it creates the task's worktree under `.claude/worktrees/` and moves this session there, where
  the upgrade goes on.
- **Approve what needs a person** (decision 0046). The upgrade changes files only on its own branch,
  and the draft pull request is the full record. Clean merges and scripted steps apply without a plan
  row. The developer approves the module choices, each conflict's resolution, and each
  permission-rule change, before anything is committed.
- **Modules are offered, never imposed.** Recommend the ones the facts support; the developer chooses.
- **An upgrade needs a nameable benefit.** If the user can't name one, say so and suggest
  cherry-picking the one or two changes they actually want.

## The scripted upgrade

The deterministic part is a script (decision 0046): `adf-upgrade`, on the Bash tool's PATH
while `adf` is on, fetches a framework checkout and runs the new release's own `scripts/upgrade.py`. A
committed project, where the command may not be on the path, runs
`python3 <framework-root>/scripts/upgrade.py <repo>` from a checkout at the release. Use it first; the
manual procedure (Steps 1–6) is for what it refuses.

1. **Dry run first:** `adf-upgrade [<tag>] --dry-run`. It changes nothing, runs on any branch, and
   prints the report. Exit 2 is a refusal; say what it says: "Below v2.0.0" or "predates the scripted
   upgrade" means the manual procedure below. The report's header names the new commit (NEW_SHA), and
   **Before the real run** lists what the run will refuse — uncommitted changes, the default branch,
   the hub's main checkout.
2. **Hand over to the new release.** This skill is the pinned plugin's, as old as the project. Read
   `plugins/adf/skills/upgrade/SKILL.md` in the release's tree — `adf-upgrade` keeps it at
   `${XDG_CACHE_HOME:-~/.cache}/adf/trees/<NEW commit>/` — and if it differs from this file, follow
   that copy from here on.
3. **What it brings, and the modules.** Summarize the report's Releases for the developer, with a
   nameable benefit (the ground rules). Offer the modules under Needs you → Modules by the rules in
   *What to offer*, and the other install or the plugin setting when they fit. The developer chooses:
   the first approval.
4. **Branch:** `chore/skeleton-upgrade-<NEW_SHA>`. With `parallel-agents` installed or just chosen,
   in a worktree of its own (the ground rules; *What to offer* › *If the developer chooses
   parallel-agents*), and the rest runs there; otherwise in place, `git switch -c`. Commit on it the
   change the install left in `.claude/settings.json` — it comes along with `git switch -c`; into a
   worktree, move it as that paragraph says. Fix whatever else **Before the real run** listed, or stop
   and say what blocks.
5. **Run it:** `adf-upgrade [<tag>] --add-modules <the chosen ones>`. It applies everything clean,
   leaves the conflicts marked, and writes the report to `$(git rev-parse --git-dir)/adf-upgrade/`.
6. **The judgment is yours:**
   - **Conflicts:** propose a resolution for each, keeping the project's customizations and the new
     release's structure (*Bucket 2* below).
   - **Clean merges:** read each one the report lists with its hunk count — a clean merge can still be
     wrong, a section added twice.
   - **Tasks to fix:** with `docker`, read the project's `Makefile` and mode files for a task C9 or
     C10 names (*The project's tasks*), and propose its fix. A `test` or `lint` that doesn't take
     C3's `t=` or `f=` is a gap for `/dev-env set up`; meanwhile `AGENTS.md` § Quick reference writes
     what it takes.
   - **Files to decide** and **Migrations** that need the developer: the choices they list.
   - **Each new module's** `MODULE.md` § Customize steps; an install switch with its PDR
     (*What to offer*).
7. **One approval** covers the conflict resolutions, the permission changes — each rule the report or
   you added or removed that changes what runs without a prompt — and the draft pull request. Revert a
   rule the developer rejects. Dropped allow rules a broader one covers change nothing that runs, and
   need none.
8. **Deliver** (*Verify and deliver*, 2–5): commit, write the PR body from the report — the
   releases, what needs a person and how it was resolved, each clean merge with its hunk count, the
   migrations, the dropped rules, the checks — and push the draft. Give the developer **On each
   machine** as the report lists it.
   - **Follow-ups ride in the PR body:** copy the report's `## Follow-ups` section into it
     as it stands, the heading and one `- [ ] \`<command>\` — <why> (<source>)` line per item, or
     `- none`. The merged PR is what survives the upgrade branch, and `/adf:wrap-up` reads it from there
     after the merge to offer each one in its own session. Don't rename the heading or reword the lines,
     and don't run the commands during the upgrade.

## What to offer

**Offer the modules the project doesn't have** — a project adopted before modules existed has none —
by `<framework-root>/modules/README.md` § Recommending a module, at NEW_SHA.

Say why each recommendation fits, and what each one costs. The chosen ones join this upgrade. Offer
`adf-connect` (decision 0023) the same way when the project works with a
tracker other than ClickUp or GitHub or GitLab issues, or with services agents should read: turn on
`"adf-connect@aplyca": true` in `enabledPlugins`, and list `/adf-connect:connect <service>` as a
follow-up.

**If the developer chooses `parallel-agents`,** do the whole upgrade in a worktree of its own, created
with plain git since the module's script isn't there yet:
`git worktree add -b chore/skeleton-upgrade-<NEW_SHA> .claude/worktrees/chore-skeleton-upgrade-<NEW_SHA> <base>`,
where the module puts every task's worktree (add `.claude/worktrees/` to `.gitignore` first when it
isn't ignored yet). Edit files under that path and run git with `-C <that path>`. Once the module is
installed, the protect-hub hook stops edits in the main checkout, so the main checkout stays clean
from the first commit.

Uncommitted changes in the main checkout don't follow into the worktree. Check `git status` there
before creating it. The usual one is the plugin setting the install left in `.claude/settings.json`:
make the same change in the worktree, then restore the main checkout's copy
(`git restore .claude/settings.json`), so the hub starts clean and the first pull after the merge
doesn't stop on it. List both moves in the plan. Anything else uncommitted there is the developer's:
ask, and never discard it.

**Offer the other install, when it fits** (decisions 0016, 0018; `docs/SETUP.md` § Packaged install):

- **Committed → packaged** — recommend it to a team that works in Claude Code only, since packaged is
  the default for new projects.
- **Packaged → committed**, when the team adds another AI tool or needs Claude Code's cloud sessions.

Once the developer accepts one, read `<this skill's base directory>/switch-install.md` and follow it:
what goes and what comes back in each direction, and **Record the switch** — a process decision in the
same pull request, which amends PDR-0001.

**Check where the plugin is turned on.** The upgrade's pull request must leave
`"enabledPlugins": {"adf@aplyca": true}`, with its `aplyca` entry in
`extraKnownMarketplaces`, committed in `.claude/settings.json`:

- **Already committed:** nothing to do.
- **Uncommitted, left by the install:** commit it with this upgrade — in the worktree, for a hub.
- **Missing:** this session got the plugin from a user- or local-scope install. Offer to add both
  entries in this upgrade (the snippet in the plugin's README § For teams), so the plugin is on for
  this project and its team only — and in every worktree of a hub. After the merge, the developer
  removes a user-scope copy with the commands in that README's § Install.

## Bucket 2: reapply the customizations

Apply the new template, then reapply each detected customization; where the new template restructured
a section, place the customization where it now belongs and flag it in the PR body.

## The project's tasks, with `docker`

The docker installer adds `Bash(make *)`, so every task runs without a prompt, `reset` and `make run`
included, which in native mode runs on the host (decisions 0078, 0089). Before it does, read the
project's `Makefile` and mode files for a task that follows or waits for input (`dev-env`'s
`SPECIFICATION.md` C9), and list each one in the plan, which fixes the task in the same change.

## Verify and deliver

1. Run the verification from `/adf:adopt` Step 6: settings JSON valid with nested hook entries; hook
   smoke tests (sample events piped to each script — in a packaged project, the plugin's, with
   `CLAUDE_PLUGIN_ROOT` and `CLAUDE_PROJECT_DIR` exported: the hooks use `set -u`); the stamp on `AGENTS.md`'s first line and no `CLAUDE.md`; skill frontmatter
   uses hyphenated keys only. Re-run the target's lint and tests if config files changed. Each newly
   installed module passes its own `<framework-root>/modules/<name>/MODULE.md` § Verify. Packaged, for
   a module whose skills another plugin carries: `<plugin>@aplyca` is on with its read rule, and
   none of the module's skills is committed.
2. Commit with a `docs:` or `chore:` prefix, e.g. `chore: upgrade framework skeleton OLD_SHA → NEW_SHA`.
3. PR body: changelog summary, each file's action with each clean merge's hunk count, migration steps done, customizations
   reapplied, the modules added and why, the plugin setting if added (with the commands that remove a
   user-scope copy), an install switch and its PDR, anything needing human judgment — and a
   `## Follow-ups` section, as the scripted path's step 8 writes it: one
   `- [ ] \`<command>\` — <why> (<source>)` line per follow-up (a new module's `set up`, a service to
   connect), or `- none`.
4. Push and open the PR **as a draft, only after the user approves** — the standing go-ahead for drafts (`AGENTS.md` § Delivery rules) covers task work, and this pull request changes the rules and guardrails that grant it.
5. **Give the developer the commands for each machine,** in the report and the PR body. The commit
   changes settings, not the machines (decision 0090). Claude Code registers the marketplace once per
   machine, at the ref it was first added with. `marketplace update`, `plugin update`, and
   `autoUpdate` keep that ref and report the old release as the latest, so each machine adds the
   marketplace again at the new pin. A plugin this upgrade turned on (`adf-dev`, `adf-connect`) may not
   be installed anywhere yet, and the session that ran the upgrade still runs the old release. From
   the project's folder, after the merge — `install` only for a plugin the merged settings turn on,
   since for one they don't, it writes `.claude/settings.json` itself:

   ```bash
   claude plugin marketplace add aplyca/AgenticDevelopmentFramework#v<X.Y.Z> --scope project   # the marketplace's source in the settings, at the new pin
   claude plugin install <plugin>@aplyca --scope project   # each plugin this upgrade turned on
   claude plugin update <plugin>@aplyca                    # each plugin already on: adf, and adf-dev or adf-connect
   git restore .claude/settings.json                       # the commands above rewrite it: keep the merged file
   claude plugin list                                      # each plugin shows Version: <X.Y.Z>
   ```

   Then `/reload-plugins` in an open session, or a new session. Never `marketplace remove` to re-add:
   it uninstalls the plugins and rewrites the committed settings. A pin that didn't move (an
   unreleased head) needs only `claude plugin marketplace update aplyca` in place of the add.

## The manual procedure

For what the script refuses — "Below v2.0.0", or a release that "predates the scripted upgrade" —
read `<this skill's base directory>/manual.md` and follow its Steps 1–6. A project below v2.0.0 — its
stamp on `CLAUDE.md`, or its settings naming the plugin's old names — reads
`<this skill's base directory>/before-v2.md` along with it.
