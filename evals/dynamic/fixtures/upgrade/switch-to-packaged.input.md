# Input — upgrade: a committed project switches to the packaged install

<!-- run: plugin-dir -->

This fixture verifies `/upgrade`'s switch from the committed install to the packaged one (decision
0016): it moves the project to the newest release, removes the framework machinery the plugin
carries and the settings' `hooks` block, pins the plugin to that release, stamps `install: packaged`,
adds the names people type, and records the switch as a PDR that amends PDR-0001 — on its own
branch, delivered as a pull request it doesn't push.

## Repository context to give the AI

A project adopted at v1.0.0 on the committed install, for a team that works in Claude Code only: the
skeleton without the Antigravity and Cursor layers, its hooks wired in `.claude/settings.json`, the
`adf` plugin turned on and pinned to `v1.0.0`, PDR-0001, and the stamp — all committed on
`main`. The plugin is loaded from this checkout for the session only (`--plugin-dir`); the
framework's releases are tagged on GitHub. There is no remote.

## Prompt to give the AI

```
/adf:upgrade
```

## Follow-up

```
Yes, switch to the packaged install — the team works in Claude Code only and doesn't need cloud
sessions. No new modules. The decider is the tech lead. Go ahead with the plan; don't push.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite upgrade --cases switch-to-packaged --models sonnet`.
2. `inspect.sh` checks the end state and prints ✓ or ✘.
3. Compare against `switch-to-packaged.expected.md`.
