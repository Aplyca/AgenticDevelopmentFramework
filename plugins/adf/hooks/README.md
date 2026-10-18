# Claude Code hooks

Instructions in `AGENTS.md` are context: an agent reads them and usually follows them. These
hooks are the rules that must hold **every** time, so they run as code at fixed points instead of
depending on what the model decides. They are wired in `../settings.json`.

| Hook | Event | What it does |
|---|---|---|
| `session-context.sh` | SessionStart | Adds a few lines to the session: main checkout or worktree, branch, uncommitted changes, the spec folder for the branch and its status, and — with the parallel-agents module — in the main checkout, triage first and then `/adf:dispatch` to the task's worktree beside it, in a worktree, one task per session, and what a worktree the scripts didn't set up lacks (a task branch name, the env file, the scripts' setup); on the base branch, how many commits it is behind origin's, as of the last fetch; once per session, when a newer framework release is out than the stamp's on `AGENTS.md` (asked at most once a day, cached in `~/.cache/adf/`, silent offline; `UPDATE_CHECK` turns it off) |
| `guard-git.sh` | PreToolUse · Bash | Blocks `--no-verify` (and `git commit -n`), commits on protected branches, and pushes, force-pushes, or deletes targeting protected branches |
| `protect-paths.sh` | PreToolUse · Edit/Write | Blocks hand-edits to generated files (lockfiles, generated types) and modifications to existing files in append-only history (migrations) |
| `careful-paths.sh` | PreToolUse · Edit/Write | The first edit in each sensitive area (`CAREFUL_GLOBS`) is stopped once per session, so the agent confirms the change is in the careful or full lane before going on. Empty `CAREFUL_GLOBS` turns it off |
| `triage-first.sh` | PreToolUse · Edit/Write, Bash | A nudge: if the session's reply text states no lane yet, the first file edit or new branch (`git switch -c`, `git checkout -b`, `git branch <name>`, `git worktree add`) is stopped once with a reminder to write the triage where the developer can read it (`AGENTS.md` § Triage first). Subagents are exempt. Empty `TRIAGE_FIRST` turns it off |
| `protect-hub.sh` | PreToolUse · Edit/Write | With the parallel-agents module installed, stops every file edit in the main checkout, so each task moves to its own worktree first, and lets edits in worktrees through. Without the module it does nothing. Empty `HUB_READONLY` turns it off. Writes made through Bash aren't seen |
| `approve-worktree-move.sh` | PreToolUse · the desktop app's `change_directory` | Approves a session's move into a linked worktree of the same repository — a session's move from the main checkout into its task's worktree (`/adf:dispatch`) — so the app doesn't ask. Any other folder still prompts. Empty `APPROVE_WORKTREE_MOVE` turns it off |
| `check-env-declared.sh` | PostToolUse · Edit/Write | After an edit, reports environment variables the file reads that the env template (`.env.example` or similar) doesn't declare, so Claude declares them. With no env template in the repository it does nothing — add one, or set `ENV_TEMPLATE` |

Pushing a work branch, and opening, editing, or commenting on its draft pull request, run without a
prompt (decision 0033), and so do issue writes (0038). Readying, merging, or reviewing a pull request,
and releases, aren't blocked here — `permissions.ask` in the project's `.claude/settings.json` makes a human
confirm each one.

## Configure

Edit **`config.sh`** — protected branches, append-only and generated paths, sensitive paths, the
env template, ignored variables. The scripts read it on every run, as data: one `KEY="value"` line per
setting, and nothing in it runs. You don't edit the scripts (they are framework-owned and replaced on
upgrade), nor their helpers: `_lib.sh`, and `json-get` and `transcript-text`, which read the event and
the session transcript with `jq` (`.jq`) or, without it, `python3` (`.py`).

## Requirements and behavior

- `bash`, `git`, and `jq` (or `python3` as a fallback) on the PATH. If neither JSON parser is
  available, a hook prints a notice and lets the action through rather than blocking everything.
- Exit code 2 blocks a PreToolUse call and shows the reason to Claude; for PostToolUse the edit has
  already happened and the message goes to Claude to act on.
- The git guard matches the command text an agent writes. A deliberately disguised command can get
  past it — it is a guardrail against mistakes, not a security boundary. The real boundaries are
  branch protection on the Git host and human review.
- Hooks in project settings run only after you trust the folder.

## Disable or extend

- Turn one off by removing its entry from `../settings.json` (`/hooks` shows what is active).
- Add a project-specific hook as a new script here, wired the same way. Read the event JSON from
  stdin (`tool_input.command`, `tool_input.file_path`, `cwd`), and source `_lib.sh` for the
  helpers. Keep hooks fast — they run on every matching tool call.
