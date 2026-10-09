# Session evals — upgrading a v1 project to v2.0.0 — 2026-10-09

The new `upgrade-from-v1` suite, run with `run-session-evals.sh --suite upgrade-from-v1 --models sonnet`
against real headless Claude Code sessions (v2.1.296) on `sonnet` (Sonnet 5.5). Each project is an
adoption at v1.4.0, the last v1 release, built from that tag. The plugin was loaded as v1.4.0 shipped
it, `aplyca-adf` (`<!-- run: plugin-dir v1.4.0 -->`), and the prompt was `/aplyca-adf:upgrade`: the path
every v1 team takes to v2.0.0, released the same day. `inspect.sh` checked each run's end state, and
each transcript was read against its `.expected.md`.

| Run | Sessions | Checks | Cost |
|---|---|---|---|
| The suite, through the runner | 3, two turns each | 51 passed, 0 failed | $3.39 |

## Starting states

Before the run, each case's project was checked as v1.4.0 would check it. The two packaged ones pass
every check in v1.4.0's own `check-packaged.sh`. The committed one has the 20 skills and its hooks
wired.

## Results

| Case | What happened in the session | Checks |
|---|---|---|
| `committed` | Read the v1.4.0 stamp and found v2.0.0, a major jump. Its plan took the rename, `CLAUDE.md`, `GEMINI.md`, the machinery from `build-committed.py`, and the project's layer, and recommended staying committed for the Cursor and Gemini users. After the answer, it wrote the release's machinery, moved the stamp and the Claude Code layer, deleted `CLAUDE.md` and `GEMINI.md`, added `.gemini/settings.json`, and smoke-tested the hooks. It committed on `chore/skeleton-upgrade-4e62d44` and pushed nothing | 10 ✓ |
| `packaged` | The same reading and plan. In its plan, the settings got the new pin and the read rule for `adf`'s folder, and the names note moved into `.claude/rules/claude-code.md` under the new name. It ran `link-reference-docs.py --packaged v2.0.0`, renamed every `/aplyca-adf:` in `DEV-SETUP.md`, and committed, pushing nothing | 19 ✓ |
| `packaged-parallel-agents` | Saw it was in a worktree on the upgrade's branch and went ahead there. On top of the packaged case, it deleted the four unedited worktree scripts and moved `worktree.conf` to `ops/agent/`. It named the `adf-worktree-*` commands in `AGENTS.md` § Quick reference and smoke-tested v2's hooks against the migrated `config.sh`. With no remote, it wrote the pull request body to a file. The main checkout beside it was left clean | 22 ✓ |

## Against the expected invariants

- **Every first turn** read the stamp and moved to v2.0.0, saying the jump crosses a major version. Each
  took its steps from the release's changelog section, presented the plan, and changed nothing before
  the answer. Each listed the developers' steps: Claude Code v2.1.281 or later, reinstalling the
  plugin as `adf@aplyca`, and removing a stray `CLAUDE.md` or `CLAUDE.local.md`.
- **The pull request body** was shown only in the parallel-agents case, which wrote it to a file.
  The committed case listed the steps and offered to open the pull request. The packaged case said it
  would put the steps in the body.
- **The packaged case put the developers' steps "before the PR".** The release notes put them after
  the merge: reinstalling under the new name before `main` moves would be early. That's a slip in the
  session's wording, not in the release.
- **No session pushed** or opened a pull request.

## What the run showed

- **Claude Code renamed the plugin before the skill ran.** In every case, `.claude/settings.json` had
  an uncommitted change when the session started: `adf@aplyca` in `enabledPlugins`, with the keys
  reordered. The cause is the marketplace's `renames` map (decision 0023). This machine's `aplyca`
  marketplace was already at v2.0.0, a newer release than the project's pin. Each session noticed the
  change and folded the rename into the upgrade's branch. A teammate whose marketplace is still at
  v1.4.0 won't see it until the pin moves, as `docs/UPGRADING.md` § "Our settings still turn on
  `aplyca-adf`" says.
- **The sessions read the release from the runner's copy of the checkout, not GitHub.** The v1.4.0
  skill looks for a full framework checkout. Each session found the copy that bypass runs get beside
  the project, which has the tags, and moved to its newest tag, v2.0.0. That tag's content is what
  was published, but the clone from GitHub didn't run. The fixtures and the README now say so.
- **One expected invariant was wrong.** The packaged case's `.expected.md` asked it to offer the
  committed install. v1.4.0's skill offers that switch only to a team that needs another AI tool or
  Claude Code's cloud sessions, so the session was right not to. The invariant now says so.

## Negative controls

Each case's checks were also run against the untouched v1.4.0 projects. Every check that the upgrade
has to change marked ✘. Checking the start states found two broken checks, both fixed before the
run:
- "No worktree scripts committed" passed when `ops/agent/` didn't exist yet; it now requires the folder.
- A check's `exit 1` inside `eval` ended the whole script; it now runs in a subshell.

The committed case's machinery check passed on a copy whose machinery `build-committed.py` wrote at
v2.0.0, and failed on the v1.4.0 one.

No defect in v2.0.0 turned up; nothing calls for a patch release.
