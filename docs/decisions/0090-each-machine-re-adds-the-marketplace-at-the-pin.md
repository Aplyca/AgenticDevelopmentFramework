# 0090: Each machine adds the marketplace again at the new pin

- **Status:** accepted
- **Date:** 2026-11-19
- **Amends:** [0041](0041-the-pin-updates-every-machine.md) — a moved pin doesn't reach a machine
  through `autoUpdate` or `claude plugin update`; the commands for each machine add the marketplace
  at the new pin, restore the settings they rewrite, and check the versions

## Context

Decision 0041 said that once a pin change merges, `"autoUpdate": true` updates each teammate's
plugins to the new release, and that the upgrade's commands for each machine (`marketplace update`,
then `plugin update`) do the same at once. A field report
([issue 174](https://github.com/aplyca/AgenticDevelopmentFramework/issues/174)) showed otherwise. An
adopting project upgraded from v2.9.0 to v2.10.0 and ran those commands after the merge. `adf` and
`adf-dev` stayed at 2.9.0, with 2.9.0 reported as the latest, and no error.

Reproduced on Claude Code 2.1.303 with a scratch configuration (`CLAUDE_CONFIG_DIR`), so no real
registration changed:

- **One registration per machine, at its first ref.** Claude Code records the marketplace in
  `known_marketplaces.json` with the source and ref it was first added with. The project's settings
  moved from `v2.10.0` to `v2.10.1`, and `claude plugin marketplace list --json` still showed
  `v2.10.0`.
- **Refreshing keeps that ref.** `claude plugin marketplace update aplyca` succeeded, and
  `claude plugin update adf@aplyca` answered "already at the latest version (2.10.0)". Claude Code's
  documentation says the same: a marketplace with a ref updates to the latest commit of that ref.
  `autoUpdate` runs the same refresh. Whether a session's start re-points a marketplace whose ref
  alone changed couldn't be tested with a scratch configuration, since that needs a signed-in session. The field report and an upstream report
  (anthropics/claude-code#76467) say it doesn't.
- **An add at the new ref re-points it.** From the project's folder,
  `claude plugin marketplace add aplyca/AgenticDevelopmentFramework#v2.10.1 --scope project` printed
  that the marketplace "now points at" `v2.10.1`, and that its installed plugins update from the new
  source. `claude plugin update adf@aplyca` then went from 2.10.0 to 2.10.1. Nothing was uninstalled,
  and the user's settings weren't written. The same add at the same ref is a no-op.
- **The commands rewrite the committed settings.** The add rewrote `.claude/settings.json`: it
  reformatted the file and dropped `"autoUpdate": true`. `claude plugin install … --scope project`
  reordered it even for a plugin the file already turned on.
- **The way out the report found costs more.** `claude plugin marketplace remove aplyca` uninstalls
  every plugin from the marketplace and rewrites the project's settings. An add without `--scope`
  declares the marketplace in the user's settings at that ref. Run from the project's folder,
  `claude plugin marketplace remove aplyca --scope user` drops that user-level declaration and leaves
  the plugins installed, because the project still declares the marketplace.

## Decision

- **The commands for each machine add the marketplace at the new pin.** Run from the project's
  folder, after the merge:

  ```bash
  claude plugin marketplace add aplyca/AgenticDevelopmentFramework#v<X.Y.Z> --scope project
  claude plugin install <plugin>@aplyca --scope project   # each plugin the upgrade turned on
  claude plugin update <plugin>@aplyca                    # each plugin already on
  git restore .claude/settings.json                       # the commands above rewrite it
  claude plugin list                                      # each plugin shows Version: <X.Y.Z>
  ```

  then `/reload-plugins`. `scripts/upgrade.py` writes them into the report's **On each machine**,
  as one shell block. It takes the add's source from the project's `aplyca` entry: the `repo` of a
  `github` source, or the `url` of a `git` one. When the pin doesn't move (an unreleased head) or the
  marketplace is a local directory, the first line stays `claude plugin marketplace update aplyca`.
- **The same add replaces the refresh where a teammate joins.** The joining note (`README.md`, the
  skeleton's `DEV-SETUP.md`) adds the marketplace at the project's `"ref"` instead of refreshing it.
- **`"autoUpdate": true` stays.** It keeps a machine's plugins current with the ref it registered
  (a branch pin, a marketplace's own updates), and the docs no longer say it carries a moved pin.
- **The upgrade still installs nothing itself** (0041): the commands are the developer's, after the
  review and the merge.

## Consequences

- **Positive:**
  - The commands leave the machine at the release the merged settings pin, and the last one shows
    it.
  - No plugin is uninstalled, and no user-level declaration is left to shadow the next upgrade.
  - The add works on a machine at the old ref, at the new one already, or with no registration at
    all, so the report doesn't need to know each machine's state.
- **Negative / cost:**
  - **One more command, and a restore.** The developer has to run `git restore` on a file the
    commands rewrote, or leave a reformatted settings file without `autoUpdate` in their checkout.
  - **Merging no longer moves anyone on its own.** Until a developer runs the commands, their machine
    stays on the old release. That was already true; 0041's claim hid it.
  - **One registration per machine** (0016). A machine with two projects pinned to different releases
    follows whichever ran the add last.
  - **It rests on Claude Code's behavior on 2.1.303,** which the documentation doesn't describe: it
    documents a repeat add as a no-op. If a later version re-points a marketplace from the settings
    alone, the add becomes a harmless repeat.

## Alternatives considered

- **Remove the marketplace and add it again** (the sequence in the field report). Declined: it
  uninstalls every plugin from the marketplace, deletes their saved data, and rewrites the committed
  settings.
- **Compare the machine's ref with the pin first** (`claude plugin marketplace list --json`) and give
  the add only when they differ. Declined: the report is written on one machine and read on all of
  them, and the add is harmless when the refs already match.
- **A command in the plugin that does it all.** Declined for now. The plugin on the machine is the
  old release, so a new command would reach developers only one upgrade later. It would also have to
  run outside a session, where the plugin's commands aren't on the path.
- **Edit `known_marketplaces.json` by hand.** Declined: an undocumented file that Claude Code owns.
