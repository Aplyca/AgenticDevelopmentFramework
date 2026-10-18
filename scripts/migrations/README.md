# Migrations

A release-specific step of an upgrade, as a script (decision 0046). What every upgrade does stays in
`scripts/upgrade.py`, and so does what a module declares as data: a folder its `module.json` says it
moved from (`moved_from`, decision 0032) moves on any upgrade that finds it. `scripts/upgrade.py` runs every
migration from the project's old release through the new one: `v<X.Y.Z>/NN-<slug>.py`, in version
order, then by `NN`. Work not yet released keeps its migrations in `unreleased/`, which the release
renames to its version when it writes the changelog's heading (decision 0017).

Each migration:

- declares `PHASE = "before"` (moves and splits, before the files merge) or `"after"` (settings,
  after the merges and the module installers);
- defines `run(ctx)`, which returns `("applied" | "done" | "needs", "<text for the report>")`:
  - **applied** — it changed the project;
  - **done** — the project was already in that state, or the step doesn't apply to it;
  - **needs** — the part that needs judgment, with what the developer has to decide. Never a guess;
- is **idempotent**: it reads the project's state first, and a second run returns `done`;
- writes only through `ctx` (`ctx.write`, `ctx.delete`, `ctx.move`, `ctx.save_settings`), so a dry
  run changes nothing, and `ctx.claim(path)` for a path it owns without writing it — the file step
  leaves the paths a migration wrote or claimed alone;
- is named by its CHANGELOG entry's **Migration** text — the static checks fail on a Migration bullet
  that names neither a script nor "by hand", and on a script no entry names;
- has a functional test in `evals/static/test-upgrade.sh`: a fixture before, the state after, and a
  second run that changes nothing.

`ctx` carries `repo`, `install` (`packaged` or `committed`), `packaged`, `modules`, `old` and `new`
(each with `tag`, `commit`, and `tree`), `dry_run`, `settings()`, `old_file(<framework path>)`,
`new_file(<framework path>)`, `new_machinery(<project path>)`, `grep(<pattern>)`, and
`follow_up(command, why, source, plugin)`.
