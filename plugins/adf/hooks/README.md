# Claude Code hooks

Instructions in `AGENTS.md` are context: an agent reads them and usually follows them. These
hooks are the rules that must hold **every** time, so they run as code at fixed points instead of
depending on what the model decides. They are wired in `../settings.json`.

| Hook | Event | What it does |
|---|---|---|
| `session-context.sh` | SessionStart | Adds a few lines to the session: main checkout or worktree, branch, uncommitted changes, the spec folder for the branch and its status, and — with the parallel-agents module — in the main checkout, triage first and then `/adf:dispatch` to the task's worktree beside it, in a worktree, one task per session, and what a worktree the scripts didn't set up lacks (a task branch name, the env file, the scripts' setup); on the base branch, how many commits it is behind origin's, as of the last fetch |
| `pr-state.sh` | SessionStart, UserPromptSubmit, Stop (`asyncRewake`) | Says once when the branch's pull request merged (offer `/adf:wrap-up`) or closed without merging (ask whether the task is dropped), so a session the developer comes back to moves to done (decision 0047). Asks the host's CLI — `glab` first when `origin` is on GitLab, `gh` first otherwise, and the other when the first can't answer — at session start and at most every five minutes after (five seconds a call at most, where `timeout` is installed), on a work branch only; remembers the last state in the checkout's git dir. At Stop it runs in the background and watches an open pull request every five minutes for `PR_WATCH_HOURS` (default 8) after the turn; a merge or close exits 2, which wakes the idle session (decision 0087). One watcher per checkout: a newer turn's replaces it. Without `gh` or `glab` it does nothing. Empty `PR_WATCH_HOURS` turns off the watch; empty `PR_STATE` turns off both |
| `session-title.sh` | UserPromptSubmit | Names a session after its task — in a terminal, where no tool renames one, and in the desktop app when the triage was made without `/adf:triage`, which renames it there itself: once a reply states the triage (`Triage — <task title> (<link>)`, or the one-line `Fast lane — <request>; …`), the next prompt sets the session's title to the task's title alone, without the lane or link, once per session. In a terminal a title already set (`/rename`, `--name`) stays. In the desktop app the app takes the title only over the one it made from the first prompt, so a title the developer or the agent set stays. Empty `SESSION_TITLE` turns it off |
| `guard-git.sh` | PreToolUse · Bash | Blocks `--no-verify` (and `git commit -n`), commits on protected branches, pushes, force-pushes, or deletes targeting protected branches, and a pull request or merge request that isn't opened as a draft. Asks before any tag push — `--tags`, `--follow-tags`, or a tag by name or ref (0038) — and before a `git config` change, letting a read run (0088). A folder or a `git config` form it can't read stays silent, unless the form names `core.hooksPath` (0096) |
| `protect-paths.sh` | PreToolUse · Edit/Write | Blocks hand-edits to generated files (lockfiles, generated types) and modifications to existing files in append-only history (migrations) |
| `careful-paths.sh` | PreToolUse · Edit/Write | The first edit in each sensitive area (`CAREFUL_GLOBS`) is stopped once per session, so the agent confirms the change is in the careful or full lane before going on — unless the latest lane its replies name is careful or full already. Subagents are exempt. Empty `CAREFUL_GLOBS` turns it off |
| `triage-first.sh` | PreToolUse · Edit/Write, Bash | A nudge: if the session's reply text holds no triage yet — no lane, no `Triage —` heading — the first edit to a file in the project or the first new branch (`git switch -c`, `git checkout -b`, `git branch <name>`, `git worktree add`) is stopped once with a reminder to write the triage where the developer can read it (`AGENTS.md` § Triage first). Files outside the project (memory notes, plans, scratch files), quoted text in a command, and subagents are exempt. Empty `TRIAGE_FIRST` turns it off |
| `protect-hub.sh` | PreToolUse · Edit/Write | With the parallel-agents module installed, stops every file edit in the main checkout, so each task moves to its own worktree first, and lets edits in worktrees through. Without the module it does nothing. Empty `HUB_READONLY` turns it off. Writes made through Bash aren't seen |
| `approve-worktree-move.sh` | PreToolUse · `EnterWorktree`, and the desktop app's `change_directory` | Approves a session's move into a linked worktree of the same repository — a session's move into its task's worktree (`/adf:dispatch`), from the main checkout or the app's own worktree — so Claude Code's permission check doesn't ask. Any other folder still prompts. The app's own folder-trust check isn't a permission, and no hook answers it: see [Moving into a worktree](#moving-into-a-worktree). Empty `APPROVE_WORKTREE_MOVE` turns it off |
| `approve-status-move.sh` | PreToolUse · MCP tools | Approves a call to the tracker tool `APPROVE_STATUS_MOVE` names when it carries nothing but the fields in `STATUS_MOVE_FIELDS` — the task's identifier and its status — so the status moves the agent makes on its own (in progress, in review, delivered) don't prompt (decision 0076). Says nothing about any other call, which still prompts: a comment or any other post, and an update that also touches an assignee, a date, or the description. It reads the call, not whose task it is or which way the status moves. Empty `APPROVE_STATUS_MOVE` turns it off |
| `check-env-declared.sh` | PostToolUse · Edit/Write | After an edit, reports environment variables the edit's new text reads that the env template (`.env.example` or similar) doesn't declare, so Claude declares them; one the file already read doesn't come back on every edit, and one the platform sets goes in `ENV_IGNORE`. With no env template in the repository it does nothing — add one, or set `ENV_TEMPLATE` |

Pushing a work branch, and opening, editing, commenting on, or marking ready its pull request, run
without a prompt (decisions 0033, 0070), and so do issue writes (0038). Merging or reviewing a pull
request, and releases, aren't blocked here — `permissions.ask` in the project's `.claude/settings.json` makes a human
confirm each one.

## Configure

Edit **`config.sh`** — protected branches, append-only and generated paths, sensitive paths, the
tracker's status tool, the env template, ignored variables. The scripts read it on every run, as data: one `KEY="value"` line per
setting, and nothing in it runs. You don't edit the scripts (they are framework-owned and replaced on
upgrade), nor their helpers: `_lib.sh`, and `json-get`, `tool-input-keys`, `transcript-text`, and `session-title`, which
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

A session moves into its task's worktree with `EnterWorktree`, in the desktop app too: the app
refuses `change_directory` for a session in its own worktree, which every chip's is, or in a folder
another session shares (decision 0085). The approve-worktree-move hook answers Claude Code's
permission check for either tool. `EnterWorktree` enters a task's worktree under `.claude/worktrees/`
(decision 0083) with no other prompt, and the app keeps showing the session in the folder it started
in.

`change_directory`, where the app allows it, has a second check of the app's own: it asks before it
moves a session into a folder outside every folder you trusted ("This folder isn't in a workspace
you've trusted"), and a hook can't answer it. Trusting the main checkout covers its worktrees.

## Disable or extend

- Turn one off by removing its entry from `../settings.json` (`/hooks` shows what is active).
- Add a project-specific hook as a new script here, wired the same way. Read the event JSON from
  stdin (`tool_input.command`, `tool_input.file_path`, `cwd`), and source `_lib.sh` for the
  helpers. Keep hooks fast — they run on every matching tool call.
