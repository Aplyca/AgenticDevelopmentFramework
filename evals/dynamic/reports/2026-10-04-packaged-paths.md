# Session evals — the packaged install's two ways in — 2026-10-04

Two new cases, run against real headless Claude Code sessions (v2.1.286) on `sonnet` (Sonnet 5.5)
with the `aplyca-adf` plugin loaded from a checkout (`--plugin-dir`): the adopt suite's `packaged`
(`/aplyca-adf:adopt` on a new project, choosing the packaged install) and the upgrade suite's
`switch-to-packaged` (`/aplyca-adf:upgrade` moving a committed adoption at v1.0.0 to the newest
release and switching it to the packaged install). Neither path had run before. `inspect.sh` checked
each end state with `check-packaged.sh`, and each transcript was read against its `.expected.md`.

| Run | Case | Turns | Checks | Cost |
|---|---|---|---|---|
| 1 | `packaged` | 16 | 8 of 8 | $0.83 |
| 1 | `switch-to-packaged` | 16 | 10 of 10 — but see the stamp below | $0.81 |
| 2 — after the fix | `switch-to-packaged` | 40 | 10 of 10, with the stricter stamp check | $1.20 |

## Adopting on the packaged install

| Invariant | Sonnet |
|---|---|
| Recognizes a new project and asks one round, including committed or packaged, with recommendations | ✓ twelve questions, packaged recommended for a Claude Code-only team |
| Copies nothing before the answers | ✓ |
| `main` holds only the first commit; the adoption is on its own branch | ✓ `docs/agentic-adoption` |
| Stamp: the newest release, its commit, `install: packaged` | ✓ `v1.0.6 · ab56cb6` |
| No framework machinery committed; `.claude/hooks/` holds only `config.sh` | ✓ |
| Settings: no `hooks` block, pinned to `v1.0.6`, `aplyca-adf` on | ✓ |
| Names note in `CLAUDE.md`; full names in `DEV-SETUP.md` | ✓ |
| PDR-0001 records the packaged install | ✓ (status proposed, until the adoption is approved) |
| Verifies the plugin's hook scripts, not the project's | ✓ push to `main`, `--no-verify`, a lockfile edit: exit 2; `git status`: 0 |
| No outward action | ✓ the PR body shown; no remote |

## Switching a committed project to the packaged install

| Invariant | Run 1 | Run 2 |
|---|---|---|
| Reads the stamp and moves to the newest release, saying whether it crosses a major | ✓ v1.0.0 → v1.0.6, no major | ✓ |
| Presents the plan first and offers the switch; changes nothing before the answer | ✓ a per-file table, every removed file confirmed unchanged since adoption | ✓ |
| Stamp, branch, and commit message name the release's commit | ✘ `130753a`, the annotated tag's own ID | ✓ `ab56cb6` |
| Machinery and the `hooks` block removed; pinned to `v1.0.6`; names note and full names | ✓ | ✓ |
| PDR-0002 records the switch; PDR-0001 marked amended; index row | ✓ | ✓ |
| `main` untouched; everything committed; nothing pushed | ✓ | ✓ |

## What the runs found

- **The upgrade stamped an annotated tag's ID instead of the release's commit.** `/upgrade` said
  "NEW_SHA is the commit of the newest release tag" without the command, and the session ran
  `git rev-parse v1.0.6`, which gives the tag object (`130753a`), not the commit (`ab56cb6`). The
  skill now names `git rev-parse --short '<tag>^{commit}'`, as does `/adopt` for the packaged stamp,
  and `check-packaged.sh` checks the stamp's commit — it marks run 1 ✘. Run 2 stamped `ab56cb6`.
- **The packaged smoke test in `docs/SETUP.md` lacked `CLAUDE_PLUGIN_ROOT`,** which the plugin's hooks
  need since v1.0.2 to load `_lib.sh`. Both sessions noticed and set it; the doc now does.
- **Open — not fixed here:** `/adopt` copies the skeleton from the framework source as it is, which
  can be past the release it pins. Here the skeleton was identical between v1.0.6 and the source, so
  nothing differed; in general a packaged project's committed layer could be newer than its pinned
  plugin. Adopting from the release tag would close it.
- Both sessions found the framework through the runner's `--add-dir` copy of the checkout, a
  development setup. A real install finds it through the marketplace or a clone.
