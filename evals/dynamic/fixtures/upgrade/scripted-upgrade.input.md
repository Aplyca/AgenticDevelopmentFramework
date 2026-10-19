# Input — upgrade: the scripted upgrade of a packaged project

<!-- run: plugin-dir -->

This fixture verifies `/adf:upgrade` on a project at v2.3.0 (decision 0046): it runs `adf-upgrade
--dry-run`, hands over to the new release's skill, runs the upgrade, keeps the team's customizations,
asks about only what needs a person (the modules, a task that deletes data, the permission changes),
commits on its own branch, and writes a pull request body from the report — each clean merge with its
hunk count, and the follow-ups. It pushes nothing.

## Repository context to give the AI

A project adopted at v2.3.0 on the packaged install with the `docker` module: the skeleton, the
`adf` plugin turned on and pinned to `v2.3.0`, the stamp, a Makefile whose `wipe-db` task deletes
data, `Bash(make *)` allowed beside two rules it covers, and the team's lines in `AGENTS.md` and
`.claude/rules/deployment.md` — all committed on `main`. The plugin is loaded from this checkout for
the session only (`--plugin-dir`), and `ADF_FRAMEWORK` names the checkout, so `adf-upgrade` needs no
network. There is no remote.

## Prompt to give the AI

```
/adf:upgrade
```

## Follow-up

```
No new modules; the benefit is the fixes since v2.3.0. Go ahead with the run. Approve the conflict
resolutions you proposed, if any, and the permission changes, including an ask rule for any project
task that deletes data. Commit on the branch and show me the pull request body. Don't push.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite upgrade --cases scripted-upgrade --models sonnet`.
2. `inspect.sh` checks the end state and the order of the commands, and prints ✓ or ✘.
3. Compare against `scripted-upgrade.expected.md`.
