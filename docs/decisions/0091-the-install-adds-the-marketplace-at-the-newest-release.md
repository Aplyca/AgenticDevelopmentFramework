# 0091: The install adds the marketplace at the newest release

- **Status:** accepted
- **Date:** 2026-11-19
- **Amends:** [0016](0016-packaged-install.md) — the install's first command adds the marketplace at
  the newest release tag, not at the default branch, and `/adf:adopt` checks that the machine's
  copy is at the pin it writes

## Context

[Decision 0090](0090-each-machine-re-adds-the-marketplace-at-the-pin.md) found that Claude Code
registers the `aplyca` marketplace once per machine, at the ref it was first added with. Refreshes
keep that ref. Only an add at another ref moves it. 0090 fixed the commands that run after an
upgrade moves the pin. The first install still ran:

```bash
claude plugin marketplace add aplyca/AgenticDevelopmentFramework --scope project
claude plugin marketplace update aplyca
claude plugin install adf@aplyca --scope project
```

Then `/adf:adopt` wrote `"ref": "v<X.Y.Z>"` into the project's settings. Reproduced on Claude Code
2.1.303, with a scratch configuration (`CLAUDE_CONFIG_DIR`) and scratch projects, so no real
registration changed:

- **The machine stays on the default branch.** After those commands and a pin written the way
  `/adf:adopt` writes it, `claude plugin marketplace list --json` showed `aplyca` with no `ref`, and
  its clone was on `main`. `marketplace update` and `plugin update` kept it there. With
  `"autoUpdate": true`, the machine follows `main`: unreleased changes, not the release the project
  pins and its committed files came from.
- **The version can't show it.** A plugin's version changes only in a release (0017), so between
  releases `main` and the newest tag carry the same version. A local mirror with one commit on
  `main` past the tag showed the effect. `adf` installed from `main` reported 2.10.1 and held the
  unreleased commit.
- **Fixing it after the fact needs a reinstall.** An add at the tag re-pointed that registration.
  `claude plugin update` then answered "already at the latest version (2.10.1)" and kept the
  unreleased files, and `claude plugin install` answered "already installed". Only
  `claude plugin uninstall`, then `claude plugin install`, replaced them with the tag's files.
- **An add at the tag from the start works everywhere.** On a fresh machine, it registered the
  marketplace at the tag, installed the tag's commit, and wrote `"ref"` into the project's settings.
  No `marketplace update` was needed. On a machine registered at an older tag by another project,
  it re-pointed the registration and installed the new release. At the same tag, it was a no-op.
  An empty tag fails: the add refuses `owner/repo#` and registers nothing.

## Decision

- **The install adds the marketplace at the newest release tag.** The install prompt (`README.md`
  and the `adf` plugin's README), `ADOPT.md`, and `docs/SETUP.md` find the tag the way `/adf:adopt`
  Step 1 does, with `git ls-remote`, and add the marketplace at it:

  ```bash
  tag=$(git ls-remote --tags --refs --sort=-v:refname https://github.com/aplyca/AgenticDevelopmentFramework 'v*' | head -1 | cut -d/ -f3)
  claude plugin marketplace add "aplyca/AgenticDevelopmentFramework#$tag" --scope project
  claude plugin install adf@aplyca --scope project
  ```

  The prompt for an agent spells the two steps out (find the tag, then add with it), since an agent
  may run each command in its own shell. The desktop app's instructions add the marketplace the same
  way.
- **`marketplace update` leaves the install.** An add at a tag clones it, re-points an older
  registration to it, or finds it already on disk. There's nothing for a refresh to add.
- **`/adf:adopt` checks the machine's copy.** Step 6 compares `aplyca`'s `ref` in
  `claude plugin marketplace list --json` with the pin it wrote. When they differ, which means an
  install without the tag, the check is a GAP. Its fix, after the merge, adds the marketplace at
  the pin, then uninstalls and installs each plugin the settings turn on, then restores the settings.
  The check reads the ref, not `claude plugin list`'s version, which can't tell the tag from `main`.

## Consequences

- **Positive:**
  - The machine that adopts runs the release the project pins from its first session. The
    settings the install writes already carry that `"ref"`, so `/adf:adopt` writes the same one.
  - The install uses the same add as 0090's commands after an upgrade, and needs no refresh.
- **Negative / cost:**
  - **The install looks the tag up.** The lookup needs `git` and access to GitHub over HTTPS, as
    `/adf:adopt` Step 1 already does. The command line is longer than an add without a ref.
  - **A machine installed with the old commands keeps following `main`** until the fix runs, or until
    the next upgrade's commands (0090) re-point it and a new version replaces the files. The
    CHANGELOG gives the fix.
  - **It rests on Claude Code's behavior on 2.1.303,** like 0090.

## Alternatives considered

- **Leave the install as it was, and have `/adf:adopt` give 0090's commands for each machine.**
  Declined: at the version the machine already has, `claude plugin update` keeps the files from
  `main`, so those commands leave the unreleased code in place. The fix would need an uninstall and
  an install on every adoption, for a state the install can avoid.
- **Write the release into the docs** (`#v2.10.1` in each command) and check it against the
  plugin's version. Declined: five places to change in every release, and a copy of the docs read
  later names an old release.
- **`gh release view` for the tag.** Declined: it needs the GitHub CLI and a login, and
  `git ls-remote` needs neither.
