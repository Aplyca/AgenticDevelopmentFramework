# 0041: The pinned marketplace auto-updates, and an upgrade names the commands for each machine

- **Status:** accepted
- **Date:** 2026-10-15
- **Amends:** [0016](0016-packaged-install.md) — what the pin does on each machine

## Context

Decision 0016 made the marketplace's `"ref"` the project's release: `/adf:upgrade` moves it in a
pull request, and the plugin "follows" it. On a developer's machine it didn't.

- **Moving the pin updated nothing installed.** Claude Code computes a plugin's version from its
  manifest, and it auto-updates only the marketplaces whose entry turns `autoUpdate` on — for a
  third-party marketplace, none by default. A teammate stayed on the old release until they ran
  `claude plugin update`, one plugin at a time.
- **`docs/SETUP.md` § Updating updated only `adf`.** An installed `adf-dev` or `adf-connect` stayed
  where it was.
- **A plugin an upgrade turned on wasn't installed.** `/adf:upgrade` writes
  `"adf-dev@aplyca": true` and its read rule, and nothing told the developer to install it. In an
  adopting project, the upgrade merged, and the new plugin wasn't there.
- **The session that runs the upgrade** keeps the release it loaded until `/reload-plugins`.

## Decision

- **The `aplyca` marketplace entry carries `"autoUpdate": true`,** beside its `"ref"`. `/adf:adopt`
  writes it, and `/adf:upgrade` adds it when the entry lacks it. Once a pin change merges, Claude
  Code updates the plugins installed from `aplyca` in each teammate's next session, a few minutes
  after its first message, and asks them to `/reload-plugins`. It never goes past the pin.
- **`/adf:upgrade` ends with the commands for each machine,** in its report and the PR body: refresh
  the marketplace, `claude plugin install <plugin>@aplyca --scope project` for each plugin it turned
  on, `claude plugin update <plugin>@aplyca` for each one already on, then `/reload-plugins`. They
  do at once what `autoUpdate` does later, and install what it can't.
- **`docs/SETUP.md` § Updating updates every plugin the project turns on.**
- **The upgrade still runs no install itself.** It changes the project's files, in a draft pull
  request someone reviews. What each machine has installed stays each developer's, and an install
  before the merge would run the new release ahead of the review.

## Consequences

- **Positive:**
  - Merging an upgrade moves every teammate to the release, with no command.
  - A plugin an upgrade turns on comes with the command that installs it.
- **Negative / cost:**
  - **Merging is the moment of decision.** Teammates get the release from the merge, not when each
    of them chooses. That's already the pin's purpose: the release is reviewed in the pull request.
  - **Auto-update waits** for a session's first message and up to ten minutes more. The commands
    are the faster route.
  - **One marketplace, per user.** Claude Code keeps one copy of `aplyca` for every project on a
    machine, so two projects pinned to different releases still move it back and forth (0016).

## Alternatives considered

- **Install from `/adf:upgrade`.** Declined. It would change the developer's machine from a session
  whose changes haven't been reviewed, and the session would still need `/reload-plugins`.
- **Leave updating to each developer.** Declined. That's what left an adopting project's
  teammates on the old release, and a plugin the upgrade turned on missing.
