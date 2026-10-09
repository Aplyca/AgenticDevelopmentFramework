# Input — upgrade from v1: a committed project moves from v1.4.0 to v2.0.0

<!-- run: plugin-dir v1.4.0 -->

This fixture rehearses the upgrade a v1 team on the committed install runs. It loads the plugin as
v1.4.0 shipped it, `aplyca-adf`, the project's pinned release, and runs that release's `/upgrade` to
the newest release tag. The newest release is a major one: the plugin is renamed
`adf`, and `CLAUDE.md` and `GEMINI.md` go away. `/upgrade` carries out the migrations in the order the
release's changelog section gives, on its own branch, and leaves the pull request for the developer.

## Repository context to give the AI

A project adopted at v1.4.0 on the committed install, for a team on several AI tools: the skeleton
from that tag with its Cursor and Gemini layers, its hooks wired in `.claude/settings.json`, the
`aplyca-adf` plugin turned on and pinned to `v1.4.0`, PDR-0001, and the stamp on `CLAUDE.md`'s first
line, all committed on `main`. The plugin is loaded from v1.4.0 for the session only
(`--plugin-dir`); the framework's releases are tagged on GitHub. There is no remote.

## Prompt to give the AI

```
/aplyca-adf:upgrade
```

## Follow-up

```
Stay on the committed install: part of the team works in Cursor and Gemini CLI. No new modules. The
decider is the tech lead. Go ahead with the plan; don't push.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite upgrade-from-v1 --cases committed --models sonnet`.
2. `inspect.sh` checks the end state and prints ✓ or ✘.
3. Compare against `committed.expected.md`.
