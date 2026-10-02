# 0017: Releases follow semantic versioning

- **Status:** accepted
- **Date:** 2026-10-02
- **Supersedes:** the versioning convention in `docs/UPGRADING.md` — "versions are referenced by commit
  SHA + date"

## Context

The framework named its releases by commit: `## 7383422 — 2026-10-01 — <title>`. That fit a framework
that projects only copied in. `/upgrade` diffs from a project's baseline commit to the newest, and a
SHA names that baseline exactly. No project depended on the framework at runtime, so there was no
compatibility promise to signal. `docs/UPGRADING.md` said the framework "doesn't use semver yet".

Two changes make a version number worth having:

- **The framework is now a pinned dependency.** A packaged project pins a release of the `aplyca-adf`
  plugin ([0016](0016-packaged-install.md)). A number like `v1.3.0` sorts, and it tells a team
  whether an upgrade asks anything of them. `release-0a42f12` does neither.
- **One plugin means one version.** The framework, its release tag, and its plugin now share a
  version. Claude Code compares the plugin's version to decide whether there is an update, and
  `claude plugin validate` warns when the version is missing.

The changelog already sorts every change by what it asks of an adopting team: overwrite, merge, or
migration steps. Semantic versioning puts that sorting into the number.

## Decision

From v1.0.0, each release is `vMAJOR.MINOR.PATCH`:

- **MAJOR** — an adopting team has to act: migration steps, a changed workflow rule, or a renamed or
  removed skill, setting, or plugin. Renaming the plugin `aplyca-framework` to `aplyca-adf` is the
  first one.
- **MINOR** — new capabilities that are additive or opt-in: a skill, a module, an install mode.
- **PATCH** — fixes that change no workflow.

Where it shows:

- **The changelog heading:** `## v1.0.0 — 2026-10-02 — <title>`.
- **The tag** `v1.0.0`, on the release pull request's merge commit, which a maintainer pushes after
  the merge. Packaged projects pin the tag.
- **The plugin's `"version"`** in `plugins/aplyca-adf/.claude-plugin/plugin.json`, which changes only
  in a release pull request. A static check holds it equal to the newest release in the changelog.
- **The stamp on `CLAUDE.md`'s first line** keeps the commit, because `/upgrade` diffs from it:
  `<!-- Skeleton source: v1.0.0 · 1a2b3c4 (2026-10-02) · modules: … -->`. Older stamps, with only a
  SHA, still work.

Releases before v1.0.0 keep their SHAs in the changelog. They get no tags.

## Consequences

- **Positive:**
  - A team can read from the number whether an upgrade asks anything of it.
  - Packaged projects pin a readable release, and the tags sort.
  - The plugin's version moves only at releases, so a project that tracks the marketplace gets
    reviewed, released changes — never each merged pull request.
- **Negative / cost:**
  - Each release takes a judgment about which part of the number to bump. The rules above, and the
    upgrade impact each change records, make it a short one.
  - A fix to `/aplyca-adf:upgrade` or `/aplyca-adf:adopt` reaches projects only with a release, so
    patch releases have to be cheap and frequent.
  - Two references for one release: the tag, and the commit in the stamp.

## Alternatives considered

- **Keep SHAs.** They're exact, but they say nothing about compatibility, and a packaged project
  would pin an opaque `release-<SHA>`.
- **Calendar versions** (`2026.10.1`). They sort, but they don't say what an upgrade asks of a team,
  which is the question adopters have.
- **Version the plugin separately from the framework.** Two numbers for one thing, now that the
  plugin is the framework's machinery as well as its installer.
