# Project settings for the Claude Code hooks in this directory.
# The hook scripts read this file as data and never run it: one KEY="value" line per setting, with
# no $-expansions. Edit the values here — the scripts themselves are framework-owned and get replaced
# on upgrade; this file is yours.
# Patterns are shell globs. A pattern without "/" matches a file name at any depth;
# a pattern with "/" matches the path relative to the repository root.

# CUSTOMIZE: branches that never take direct commits or pushes from an agent.
# Add your integration and release branches (e.g. "main staging develop"). Empty disables the check.
PROTECTED_BRANCHES="main master"

# CUSTOMIZE: append-only history — existing files here must never be modified; adding new
# files is fine. E.g. "db/migrations/* db/migrate/* prisma/migrations/*/migration.sql"
APPEND_ONLY_GLOBS=""

# Generated files that must never be hand-edited — regenerate them with their tool.
# Add generated types or clients, e.g. "src/types/database.generated.ts".
GENERATED_GLOBS="package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb poetry.lock uv.lock Pipfile.lock Gemfile.lock composer.lock Cargo.lock go.sum"

# CUSTOMIZE: sensitive areas — paths where any change takes at least the careful lane, whatever its
# size (mirror AGENTS.md § Sensitive areas). The first edit in each area stops once per session so
# the agent confirms the lane. E.g. "src/billing/* src/auth/* supabase/migrations/*". Empty disables.
CAREFUL_GLOBS=""

# The triage — the lane and why — comes before the first change. "1" stops a session's first file
# edit or new branch once, as a reminder, when its reply text states no lane yet. Empty disables.
TRIAGE_FIRST="1"

# With the parallel-agents module installed, each task moves to its own worktree before its first
# edit. "1" stops every file edit in the main checkout (worktrees are unaffected). Without the
# module it has no effect. Empty disables.
HUB_READONLY="1"

# A session moves into its task's worktree (/dispatch) with EnterWorktree, or the desktop app's
# change_directory when asked to. "1" approves that move in Claude Code's permission check when the
# folder is a worktree of this repository; any other folder still prompts. For change_directory, the
# app's own folder-trust check still asks until you trust the folder that holds the main checkout and
# its worktrees. Empty disables.
APPROVE_WORKTREE_MOVE="1"

# CUSTOMIZE: a tracker task's status moves on the agent's own — in progress, in review, delivered —
# but a tracker's write tools stay off the allow list, so each move prompts. Name the tool that
# moves a task's status here — e.g. "mcp__clickup__clickup_update_task" — and a call to it that
# carries nothing but STATUS_MOVE_FIELDS passes without a prompt. Every other call still asks: a
# comment or any other post, and an update that also touches an assignee, a date, or the description.
# Several tools: separate them with spaces. Empty disables.
APPROVE_STATUS_MOVE=""
# The only fields such a call may carry: the task's identifier, then the status field, last.
STATUS_MOVE_FIELDS="task_id status"

# A session hears once when its branch's pull request merged (offer /wrap-up) or closed without
# merging (ask whether the task is dropped). "1" asks gh, or glab on GitLab, at session start and at
# most every five minutes after, on a work branch only; without either it does nothing. Empty disables.
PR_STATE="1"
# While the session sits idle after a turn, the same hook watches an open pull request in the
# background and wakes the session when it merges or closes, so the wrap-up is offered without a
# prompt. It asks every five minutes for this many hours after the turn ends. Empty disables the
# watch; PR_STATE empty disables both.
PR_WATCH_HOURS="8"

# A session is named after its task, as /triage does in the desktop app. "1" sets the title to the
# task's title once a reply states the triage, on the next prompt and once per session; a title you
# set (/rename, --name, or a rename in the desktop app) stays. Empty disables.
SESSION_TITLE="1"

# "1" adds one line to a session's context when a newer framework release is out than the one this
# project is on (the stamp on AGENTS.md's first line) — run /adf:upgrade. The check asks the framework
# repository for its newest release tag at most once a day, caches it outside the repository, and
# says nothing offline. Empty disables.
UPDATE_CHECK="1"

# The env template that declares (names only, no values) every environment variable the code
# reads. Empty = auto-detect .env.example, .env.sample, .env.template or .env.dist at the root.
ENV_TEMPLATE=""

# Variables the runtime or platform provides — never expected in the env template.
ENV_IGNORE="NODE_ENV CI HOME PATH PWD USER SHELL TERM TZ LANG MODE DEV PROD SSR BASE_URL"

# Files never checked for undeclared environment variables.
ENV_CHECK_EXCLUDE="*.test.* *.spec.* *_test.* test_*.py tests/* */tests/* */__tests__/* docs/* *.md"

# Where spec folders live (used for session context).
SPECS_DIR="specs"

# CUSTOMIZE: the local environment's URL — what the agent walks for the local check before the pull
# request. Agents read it; no hook does. ${APP_PORT} is the env file's when it pins one. Empty: the agent uses
# READY_URL from ops/agent/worktree.conf, or `make urls`.
# E.g. 'http://localhost:${APP_PORT}', or "http://localhost:3000" for a fixed port.
LOCAL_URL=""
