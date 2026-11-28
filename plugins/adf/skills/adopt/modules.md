# Modules at adoption

`/adf:adopt` reads this for the modules the developer chose (Steps 3 and 4), and for a project
already adopted (Step 1).

## Already adopted (Step 1)

Don't re-adopt: offer to install modules (steps 3–4 for the chosen modules only, then update the
`modules:` list in the stamp) or point to `/adf:upgrade`. When the parallel-agents module is already
installed, the main checkout takes no edits: started there, run `/adf:dispatch` with
`chore/add-modules` as the branch, without asking first. It creates the task's worktree under
`.claude/worktrees/` and moves this session there, where you go on.

## Installing them (Step 3)

Install each chosen one as its § Installing a module says: `cp -Rn modules/<name>/files/. <repo>/`,
then merge by hand each of the module's files that already existed; `clickup` by
`modules/clickup/install.sh`; `docker`, `e2e`, and `unit` by their installers
(`modules/docker/install.sh`, `modules/e2e/install.sh`, `modules/unit/install.sh`), `docker`'s
first.

**Turn on the plugin that carries a module** in a packaged install when it isn't `adf` — its
`module.json` names it (§ Modules and plugins): `"<plugin>@aplyca": true` in `enabledPlugins` and
`Read(~/.claude/plugins/cache/aplyca/<plugin>/**)` in `permissions.allow`, once however many of its
modules the project has; and leave out the scripts it carries as commands — for `parallel-agents`,
every file in `ops/agent/` but `worktree.conf`, the project's settings. A committed install writes
the skills with `build-committed.py` (Step 3) and leaves that plugin off.

Their `set up` runs are follow-ups (Step 7).

## Filling in their settings (Step 4)

- **`github`:** the PR template's quality and constitution checklists; `branch-policy.yml`
  (`GUARDED_BASE`, `ALLOWED_HEADS` or `FORBIDDEN_HEADS`).
- **`gitlab`:** the merge request template, `issue_templates/Default.md`'s tracker link, and the
  `ADF_` variables in `.gitlab-ci.yml`.
- **`git-hooks`:** `FAST_CHECKS` in `.githooks/pre-push`.
- **`parallel-agents`:** `ops/agent/worktree.conf`; the `AGENTS.md` "Parallel sessions" line per the
  module's `MODULE.md`, and its Quick reference lines — packaged, the commands' names
  (`adf-worktree-new`, `adf-worktree-ls`, `adf-worktree-rm`), as `DEV-SETUP.md` has the skills' full
  names; `LOCAL_URL` in `.claude/hooks/config.sh` with `${APP_PORT}` in it, or left
  empty to let `READY_URL` serve.
- **`clickup`:** in `docs/TRACKER-INTEGRATION.md`, the values its `MODULE.md` § Customize lists (task
  links, statuses via `clickup_get_task` with `expand_statuses: true`, where PR links go).
- **`docker`:** the pull request's first follow-up is `/dev-env set up` (packaged:
  `/adf-dev:dev-env set up`) in a new session, once the stamp names the module — it writes the stack
  to the local environment specification it carries (its templates are an example of it), or audits
  the existing one against it and proposes the move, and fills `DEV-SETUP.md`, the Quick reference's
  start, stop, and one-file lines, `LOCAL_URL`, and `deployment.md`'s `paths:` from what it verifies.
- **`e2e`:** the next follow-up is `/e2e set up` (packaged: `/adf-dev:e2e set up`), after
  `/dev-env set up` when the project has `docker`: the developer picks the critical flows, and it
  writes the suite and their smoke tests.
- **`unit`:** the follow-up is `/unit set up` (packaged: `/adf-dev:unit set up`): the developer
  picks the feature suites, and it writes the configuration, the tier scripts, and
  `docs/TEST-SUITES.md`.
- **`time-tracking`:** fill `docs/TIME-TRACKING.md` — the tracker's time-entry tools, the labels —
  from the tracker's real tools, or leave a `TODO(team)` for each.
- **`end-user-docs`:** fill `docs/END-USER-DOCS.md` — the doc tool, the end-user doc, the drafts
  location, its page tools, the end users and their language — from what the team says and the
  tool's real tools, or leave a `TODO(team)` for each.

## Checking them (Step 6)

- [ ] Each installed module passes its own `MODULE.md` § Verify (`<framework-root>/modules/<name>/MODULE.md`)
- [ ] Packaged, with a module whose skills another plugin carries (`adf-dev`): that plugin is turned on with its read rule, the module's skills aren't committed, and `/<plugin>:<skill>` is offered in a new session
