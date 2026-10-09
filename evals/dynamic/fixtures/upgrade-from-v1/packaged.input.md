# Input — upgrade from v1: a packaged project moves from v1.4.0 to v2.0.0

<!-- run: plugin-dir v1.4.0 -->

This fixture rehearses the upgrade a v1 team on the packaged install, the default, runs. It loads the
plugin as v1.4.0 shipped it, `aplyca-adf`, the project's pinned release, and runs that release's
`/upgrade` to the newest release tag. The newest release is a major one: the plugin
is renamed `adf`, and `CLAUDE.md` goes away, names note and all. `/upgrade` carries out the migrations
in the order the release's changelog section gives, on its own branch, and leaves the pull request for
the developer.

## Repository context to give the AI

A project adopted at v1.4.0 on the packaged install: the skeleton's project layer, with no framework
machinery, no Cursor or Gemini layer, and no reference docs in `docs/` (its files link them at v1.4.0).
The settings pin the marketplace to `v1.4.0`, turn on `aplyca-adf`, and allow reading its folder, with
no `hooks` block. `CLAUDE.md` holds the packaged names note and the stamp with `install: packaged`,
and `DEV-SETUP.md` gives the commands by their full names. Everything is committed on `main`. The
plugin is loaded from v1.4.0 for the session only (`--plugin-dir`); the framework's releases are
tagged on GitHub. There is no remote.

## Prompt to give the AI

```
/aplyca-adf:upgrade
```

## Follow-up

```
Stay on the packaged install. No new modules. The decider is the tech lead. Go ahead with the plan;
don't push.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite upgrade-from-v1 --cases packaged --models sonnet`.
2. `inspect.sh` checks the end state, with `check-packaged.sh` at the newest release, and prints ✓ or ✘.
3. Compare against `packaged.expected.md`.
