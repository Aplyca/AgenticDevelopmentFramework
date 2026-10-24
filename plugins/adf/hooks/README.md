# Claude Code hooks

Instructions in `AGENTS.md` are context: an agent reads them and usually follows them. These
hooks are the rules that must hold **every** time, so they run as code at fixed points instead of
depending on what the model decides. They are wired in `../settings.json`.

| Hook | Event | What it does |
|---|---|---|
| `session-context.sh` | SessionStart | Adds a few lines to the session: main checkout or worktree, branch, uncommitted changes, the spec folder for the branch and its status, and — with the parallel-agents module — in the main checkout, triage first and then `/adf:dispatch` to the task's worktree beside it, in a worktree, one task per session, and what a worktree the scripts didn't set up lacks (a task branch name, the env file, the scripts' setup); on the base branch, how many commits it is behind origin's, as of the last fetch |
| `pr-state.sh` | SessionStart, UserPromptSubmit | Says once when the branch's pull request merged (offer `/adf:wrap-up`) or closed without merging (ask whether the task is dropped), so a session the developer comes back to moves to done (decision 0047). Asks `gh` at session start and at most every five minutes after (five seconds at most, where `timeout` is installed), on a work branch only; remembers the last state in the checkout's git dir. Without `gh` it does nothing. Empty `PR_STATE` turns it off |
| `session-title.sh` | UserPromptSubmit | Names a terminal session after its task, as `/adf:triage` does in the desktop app: once a reply states the triage (`Triage — <task title> (<link>)`, or the one-line `Fast lane — <request>; …`), the next prompt sets the session's title to the task's title alone, without the lane or link, once per session. A title already set (`/rename`, `--name`) stays, and in the desktop app, where the agent names the session itself, it does nothing. Empty `SESSION_TITLE` turns it off |
| `guard-git.sh` | PreToolUse · Bash | Blocks `--no-verify` (and `git commit -n`), commits on protected branches, and pushes, force-pushes, or deletes targeting protected branches |
| `protect-paths.sh` | PreToolUse · Edit/Write | Blocks hand-edits to generated files (lockfiles, generated types) and modifications to existing files in append-only history (migrations) |
| `careful-paths.sh` | PreToolUse · Edit/Write | The first edit in each sensitive area (`CAREFUL_GLOBS`) is stopped once per session, so the agent confirms the change is in the careful or full lane before going on. Empty `CAREFUL_GLOBS` turns it off |
| `triage-first.sh` | PreToolUse · Edit/Write, Bash | A nudge: if the session's reply text states no lane yet, the first file edit or new branch (`git switch -c`, `git checkout -b`, `git branch <name>`, `git worktree add`) is stopped once with a reminder to write the triage where the developer can read it (`AGENTS.md` § Triage first). Subagents are exempt. Empty `TRIAGE_FIRST` turns it off |
| `protect-hub.sh` | PreToolUse · Edit/Write | With the parallel-agents module installed, stops every file edit in the main checkout, so each task moves to its own worktree first, and lets edits in worktrees through. Without the module it does nothing. Empty `HUB_READONLY` turns it off. Writes made through Bash aren't seen |
| `approve-worktree-move.sh` | PreToolUse · the desktop app's `change_directory` | Approves a session's move into a linked worktree of the same repository — a session's move from the main checkout into its task's worktree (`/adf:dispatch`) — so Claude Code's permission check doesn't ask. Any other folder still prompts. The app's own folder-trust check isn't a permission, and no hook answers it: see [Moving into a worktree](#moving-into-a-worktree). Empty `APPROVE_WORKTREE_MOVE` turns it off |
| `check-env-declared.sh` | PostToolUse · Edit/Write | After an edit, reports environment variables the file reads that the env template (`.env.example` or similar) doesn't declare, so Claude declares them. With no env template in the repository it does nothing — add one, or set `ENV_TEMPLATE` |

Pushing a work branch, and opening, editing, or commenting on its draft pull request, run without a
prompt (decision 0033), and so do issue writes (0038). Readying, merging, or reviewing a pull request,
and releases, aren't blocked here — `permissions.ask` in the project's `.claude/settings.json` makes a human
confirm each one.

## Configure

Edit **`config.sh`** — protected branches, append-only and generated paths, sensitive paths, the
env template, ignored variables. The scripts read it on every run, as data: one `KEY="value"` line per
setting, and nothing in it runs. You don't edit the scripts (they are framework-owned and replaced on
upgrade), nor their helpers: `_lib.sh`, and `json-get`, `transcript-text`, and `session-title`, which
read the event and the session transcript, and write the session's title, with `jq` (`.jq`) or, without
it, `python3` (`.py`).

## Requirements and behavior

- `bash`, `git`, and `jq` (or `python3` as a fallback) on the PATH. If neither JSON parser is
  available, a hook prints a notice and lets the action through rather than blocking everything.
- Exit code 2 blocks a PreToolUse call and shows the reason to Claude; for PostToolUse the edit has
  already happened and the message goes to Claude to act on.
- The git guard matches the command text an agent writes. A deliberately disguised command can get
  past it — it is a guardrail against mistakes, not a security boundary. The real boundaries are
  branch protection on the Git host and human review.
- Hooks in project settings run only after you trust the folder.

## Moving into a worktree

The desktop app checks a session's move twice. The approve-worktree-move hook answers the first,
Claude Code's permission check. The second is the app's own: it asks before it moves a session into
a folder outside every folder you trusted ("This folder isn't in a workspace you've trusted"), and a
hook can't answer it. The worktrees are siblings of the main checkout, so trusting the main checkout
doesn't cover them, and each new worktree would ask once.

Trust the folder that holds the main checkout and its worktrees, once: open a session on it — in the
desktop app, or `cd` there and run `claude` — and accept the prompt to trust the folder. Its trust
covers every worktree created in it from then on. Trust only a folder that holds this project's
checkouts: everything inside it is trusted too.

## Disable or extend

- Turn one off by removing its entry from `../settings.json` (`/hooks` shows what is active).
- Add a project-specific hook as a new script here, wired the same way. Read the event JSON from
  stdin (`tool_input.command`, `tool_input.file_path`, `cwd`), and source `_lib.sh` for the
  helpers. Keep hooks fast — they run on every matching tool call.
