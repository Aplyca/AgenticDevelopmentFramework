#!/usr/bin/env bash
#
# Functional tests for the skeleton's Claude Code hooks (skeleton/.claude/hooks/). Each test pipes a
# tool event as JSON on stdin — exactly what Claude Code sends — into a hook running against a
# throwaway git repository, and checks the exit code: 2 blocks / reports, 0 allows.
# No AI invocation. Needs bash, git, and jq or python3. Exit 0 on all-pass.
#
set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="${REPO_ROOT:-$( cd "$SCRIPT_DIR/../.." && pwd )}"
HOOKS_SRC="$REPO_ROOT/skeleton/.claude/hooks"

PASS=0
FAIL=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

json_string() { python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }

run() { # run <hook> <expected-exit> <event-json> <description>
    local out code
    out=$(printf '%s' "$3" | "$H/$1" 2>&1)
    code=$?
    if [ "$code" = "$2" ]; then
        PASS=$((PASS+1)); echo "✓ $1: $4"
    else
        FAIL=$((FAIL+1)); echo "✘ $1: $4 (exit $code, expected $2)"; [ -n "$out" ] && echo "    $out"
    fi
}
bash_event() { printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":%s}}' "$T" "$(printf '%s' "$1" | json_string)"; }
file_event() { printf '{"tool_name":"%s","cwd":"%s","tool_input":{"file_path":"%s"}}' "$1" "$T" "$2"; }

T="$WORK/repo"
mkdir -p "$T" && git -C "$T" init -q -b main
git -C "$T" config user.email test@example.com
git -C "$T" config user.name test
mkdir -p "$T/.claude"
cp -R "$HOOKS_SRC" "$T/.claude/"
echo 'APPEND_ONLY_GLOBS="db/migrations/*"' >> "$T/.claude/hooks/config.sh"
H="$T/.claude/hooks"
mkdir -p "$T/db/migrations" "$T/src" "$T/specs/007-newsletter-signup"
echo "create table t (id int);" > "$T/db/migrations/001_init.sql"
printf -- '---\nstatus: approved\n---\n' > "$T/specs/007-newsletter-signup/spec.md"
printf 'API_URL=\n# OPTIONAL_FLAG=\n' > "$T/.env.example"
git -C "$T" add -A && git -C "$T" commit -qm init

echo ""
echo "Hook tests — skeleton/.claude/hooks"
echo "==================================="

# guard-git — on the protected main branch
run guard-git.sh 0 "$(bash_event 'git status')" "allows read-only git"
run guard-git.sh 0 "$(bash_event 'ls -la && echo done')" "ignores non-git commands"
run guard-git.sh 2 "$(bash_event 'git commit -m "wip"')" "blocks a commit on main"
run guard-git.sh 2 "$(bash_event 'git push')" "blocks a bare push from main"
run guard-git.sh 2 "$(bash_event 'git push origin HEAD')" "blocks pushing HEAD from main"
run guard-git.sh 0 "$(bash_event 'git push --tags')" "allows a tags-only push"
run guard-git.sh 0 "$(bash_event 'git pull --ff-only')" "allows pull"
run guard-git.sh 0 "$(bash_event 'git switch -c feat/new-thing')" "allows creating a work branch"
# Decision 0022: the agent opens the pull request on its own, so the draft rule lives here.
run guard-git.sh 2 "$(bash_event 'gh pr create --title "Add signup" --body-file /tmp/body.md')" "blocks a pull request that isn't a draft"
run guard-git.sh 0 "$(bash_event 'gh pr create --draft --title "Add signup" --body-file /tmp/body.md')" "allows a draft pull request"
run guard-git.sh 0 "$(bash_event 'git push -u origin feat/new-thing && gh pr create -d --fill')" "allows a draft by its short flag, after a work-branch push"
run guard-git.sh 2 "$(bash_event 'gh pr create --title "--draft later" --fill')" "isn't fooled by --draft inside a quoted title"
run guard-git.sh 0 "$(bash_event 'gh pr view 12 --json state')" "ignores other gh commands"

git -C "$T" switch -q -c feat/newsletter-signup
# guard-git — on a work branch
run guard-git.sh 0 "$(bash_event 'git commit -m "feat: add signup form"')" "allows a commit on a work branch"
run guard-git.sh 0 "$(bash_event 'git commit -am "fix: guard against -n flag in messages"')" "ignores flags inside a quoted message"
heredoc=$'git commit -m "$(cat <<\'EOF\'\nfeat: add signup\n\nDon\'t use -n; git push origin main is mentioned here\nEOF\n)"'
run guard-git.sh 0 "$(bash_event "$heredoc")" "ignores a heredoc commit message"
run guard-git.sh 2 "$(bash_event 'git commit --no-verify -m x')" "blocks --no-verify"
run guard-git.sh 2 "$(bash_event 'git commit -nm x')" "blocks -n folded into short flags"
run guard-git.sh 2 "$(bash_event 'git merge --no-verify feat/x')" "blocks --no-verify on merge"
run guard-git.sh 0 "$(bash_event 'git push -u origin feat/newsletter-signup')" "allows pushing the work branch (after the local check, decision 0022)"
run guard-git.sh 2 "$(bash_event 'git push origin main')" "blocks a push to main"
run guard-git.sh 2 "$(bash_event 'git push origin feat/x:main')" "blocks a refspec targeting main"
run guard-git.sh 2 "$(bash_event 'git push --force-with-lease origin +main')" "blocks a force-push to main"
run guard-git.sh 2 "$(bash_event 'git push origin :master')" "blocks deleting master"
run guard-git.sh 2 "$(bash_event 'git push --all origin')" "blocks --all"
run guard-git.sh 0 "$(bash_event 'git push --dry-run origin main')" "allows a dry run"
run guard-git.sh 2 "$(bash_event "cd /tmp && git -C $T push origin main")" "follows git -C"
run guard-git.sh 2 "$(bash_event 'npm test && git push origin HEAD:refs/heads/main')" "checks every command in a chain"
run guard-git.sh 0 "$(bash_event 'echo "git push origin main is forbidden"')" "ignores a quoted mention"
run guard-git.sh 0 "$(bash_event "echo 'done; git push origin main'")" "ignores a single-quoted mention with a separator"
run guard-git.sh 2 "$(bash_event "git commit -m 'subject' -m \"body; more\" --no-verify")" "sees a flag after quoted messages"
run guard-git.sh 0 "$(bash_event 'git log --oneline -n 5')" "allows git log -n"

# protect-paths
run protect-paths.sh 2 "$(file_event Edit "$T/package-lock.json")" "blocks hand-editing a lockfile"
run protect-paths.sh 2 "$(file_event Edit "$T/apps/web/pnpm-lock.yaml")" "blocks a nested lockfile"
run protect-paths.sh 2 "$(file_event Edit "$T/db/migrations/001_init.sql")" "blocks editing an existing migration"
run protect-paths.sh 0 "$(file_event Write "$T/db/migrations/002_add.sql")" "allows a new migration"
run protect-paths.sh 0 "$(file_event Edit "$T/src/app.ts")" "allows ordinary source edits"

# check-env-declared
cat > "$T/src/client.ts" <<'TS'
const url = process.env.API_URL;
const flag = process.env['OPTIONAL_FLAG'];
const key = process.env.PAYMENT_SECRET_KEY;
const mode = process.env.NODE_ENV;
const site = import.meta.env.VITE_PUBLIC_SITE;
TS
run check-env-declared.sh 2 "$(file_event Edit "$T/src/client.ts")" "reports undeclared variables"
cat > "$T/src/ok.py" <<'PY'
import os
url = os.environ["API_URL"]
flag = os.getenv("OPTIONAL_FLAG")
PY
run check-env-declared.sh 0 "$(file_event Write "$T/src/ok.py")" "accepts declared (and commented) variables"
echo 'process.env.TEST_ONLY_VAR = "x";' > "$T/src/client.test.ts"
run check-env-declared.sh 0 "$(file_event Write "$T/src/client.test.ts")" "skips test files"
printf 'package svc\nimport "os"\nvar a = os.Getenv("SERVICE_TOKEN")\n' > "$T/src/svc.go"
run check-env-declared.sh 2 "$(file_event Write "$T/src/svc.go")" "reads Go os.Getenv"

# session-context
# careful-paths — sensitive areas stop the first edit per area per session
careful_event() { printf '{"tool_name":"Edit","session_id":"%s","cwd":"%s","tool_input":{"file_path":"%s"}}' "$1" "$T" "$2"; }
export TMPDIR="$WORK/tmp"; mkdir -p "$TMPDIR"
run careful-paths.sh 0 "$(careful_event s-off "$T/src/billing/invoice.ts")" "does nothing while CAREFUL_GLOBS is empty"
echo 'CAREFUL_GLOBS="src/billing/* */auth/*"' >> "$T/.claude/hooks/config.sh"
run careful-paths.sh 2 "$(careful_event s1 "$T/src/billing/invoice.ts")" "stops the first edit in a sensitive area"
run careful-paths.sh 0 "$(careful_event s1 "$T/src/billing/tax.ts")" "lets later edits in that area through, same session"
run careful-paths.sh 2 "$(careful_event s1 "$T/src/api/auth/session.ts")" "stops again for a different sensitive area"
run careful-paths.sh 2 "$(careful_event s2 "$T/src/billing/invoice.ts")" "stops again in a new session"
run careful-paths.sh 0 "$(careful_event s1 "$T/src/app.ts")" "ignores paths outside the sensitive areas"

# triage-first — the first edit waits for a stated lane, once per session
printf '%s\n' '{"type":"user","message":{"content":"fix the label"}}' '{"type":"assistant","message":{"content":[{"type":"text","text":"Looking at the form."}]}}' > "$WORK/no-lane.jsonl"
printf '%s\n' '{"type":"user","message":{"content":"fix the label"}}' '{"type":"assistant","message":{"content":[{"type":"text","text":"Fast lane — the label reads Your email; done when the test passes; files: Form.tsx."}]}}' > "$WORK/lane.jsonl"
triage_event() { printf '{"tool_name":"Edit","session_id":"%s","transcript_path":"%s","cwd":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2" "$T" "$T/src/app.ts"; }
run triage-first.sh 2 "$(triage_event t1 "$WORK/no-lane.jsonl")" "stops the first edit when no lane was stated"
run triage-first.sh 0 "$(triage_event t1 "$WORK/no-lane.jsonl")" "reminds once per session — a nudge, never a lock"
run triage-first.sh 0 "$(triage_event t2 "$WORK/lane.jsonl")" "lets edits through once a lane is stated"
run triage-first.sh 0 "$(printf '{"tool_name":"Edit","session_id":"t3","agent_id":"a1","transcript_path":"%s","cwd":"%s","tool_input":{"file_path":"%s"}}' "$WORK/no-lane.jsonl" "$T" "$T/src/app.ts")" "leaves subagents alone"
triage_bash() { printf '{"tool_name":"Bash","session_id":"%s","transcript_path":"%s","cwd":"%s","tool_input":{"command":%s}}' "$1" "$2" "$T" "$(printf '%s' "$3" | json_string)"; }
run triage-first.sh 0 "$(triage_bash b1 "$WORK/no-lane.jsonl" 'git status && git branch --show-current')" "ignores Bash commands that create no branch"
run triage-first.sh 2 "$(triage_bash b1 "$WORK/no-lane.jsonl" 'git switch -c fix/label')" "stops a new branch when no lane was stated"
run triage-first.sh 0 "$(triage_event b1 "$WORK/no-lane.jsonl")" "one reminder per session — the edit after it passes"
run triage-first.sh 2 "$(triage_bash b2 "$WORK/no-lane.jsonl" 'cd repo && git checkout -b fix/label')" "catches git checkout -b inside a compound command"
run triage-first.sh 0 "$(triage_bash b3 "$WORK/lane.jsonl" 'git switch -c fix/label')" "lets a new branch through once a lane is stated"
echo 'TRIAGE_FIRST=""' >> "$T/.claude/hooks/config.sh"
run triage-first.sh 0 "$(triage_event t4 "$WORK/no-lane.jsonl")" "does nothing when TRIAGE_FIRST is empty"

out=$(printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$T" | "$H/session-context.sh")
if echo "$out" | grep -q 'specs/007-newsletter-signup/ (status: approved)'; then
    PASS=$((PASS+1)); echo "✓ session-context.sh: finds the branch's spec folder and status"
else
    FAIL=$((FAIL+1)); echo "✘ session-context.sh: spec folder line missing"; echo "    $out"
fi
git -C "$T" switch -q -c feat/newsletter-signup-topics
out=$(printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$T" | "$H/session-context.sh")
if echo "$out" | grep -q 'specs/007-newsletter-signup/'; then
    PASS=$((PASS+1)); echo "✓ session-context.sh: a change-request branch joins its feature's folder by prefix"
else
    FAIL=$((FAIL+1)); echo "✘ session-context.sh: change-request branch did not find the folder"; echo "    $out"
fi
git -C "$T" switch -q -c feat/newsletter
out=$(printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$T" | "$H/session-context.sh")
if echo "$out" | grep -q 'No spec folder matches'; then
    PASS=$((PASS+1)); echo "✓ session-context.sh: a shorter slug doesn't match a longer folder slug"
else
    FAIL=$((FAIL+1)); echo "✘ session-context.sh: feat/newsletter wrongly matched a folder"; echo "    $out"
fi
git -C "$T" switch -q main
out=$(printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$T" | "$H/session-context.sh")
if echo "$out" | grep -q 'main is protected'; then
    PASS=$((PASS+1)); echo "✓ session-context.sh: warns on a protected branch"
else
    FAIL=$((FAIL+1)); echo "✘ session-context.sh: protected-branch warning missing"; echo "    $out"
fi

# With the parallel-agents module, each session learns its role from where it runs: dispatcher in
# the main checkout, worker in any linked worktree (decision 0015). In a worktree the scripts didn't
# set up, it also learns what that worktree lacks. The module's settings are what show it's there: a
# packaged project commits them without the scripts (decision 0025).
mkdir -p "$T/scripts/agent" && printf 'BASE_BRANCH="main"\nENV_FILE=".env"\n' > "$T/scripts/agent/worktree.conf"
git -C "$T" add scripts/agent && git -C "$T" commit -qm "add the worktree settings"
git -C "$T" update-ref refs/remotes/origin/main HEAD && git -C "$T" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
echo 'SECRET=1' > "$T/.env"
git -C "$T" worktree add -q -b feat/role-check "$WORK/feat-role-check"
git -C "$T" worktree add -q -b claude/eager-lamport "$T/.claude/worktrees/eager-lamport"
git -C "$T" worktree add -q --detach "$T/.claude/worktrees/calm-turing"
git -C "$T" worktree add -q -b feat/marked "$WORK/somewhere-else"
echo marker > "$(git -C "$WORK/somewhere-else" rev-parse --absolute-git-dir)/agent-worktree"
ctx() { printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$1" | "$H/session-context.sh"; }
check_ctx() { # check_ctx <description> <dir> <must match> [<must not match>]
    local out; out="$(ctx "$2")"
    if echo "$out" | grep -q -- "$3" && { [ -z "${4:-}" ] || ! echo "$out" | grep -q -- "$4"; }; then
        PASS=$((PASS+1)); echo "✓ session-context.sh: $1"
    else
        FAIL=$((FAIL+1)); echo "✘ session-context.sh: $1"; echo "$out" | sed 's/^/    /'
    fi
}
check_ctx "dispatcher in the main checkout, which gives every task to /dispatch" "$T" "Give every task to /dispatch"
check_ctx "the dispatcher's tasks get worktrees beside the main checkout, from the base branch" "$T" "worktree beside this checkout, on a new branch from main," "Route:"
check_ctx "a dispatched session in the main checkout is told to create its worktree and move first" "$T" "first step is the worktree: scripts/agent/worktree-new.sh <branch> --no-start, then move this session"
check_ctx "worker in a worktree the scripts set up, with nothing missing" "$WORK/feat-role-check" "Role: WORKER" "generated\|No .env\|Not set up"
check_ctx "worker in Claude Code's worktree, told to rename its generated branch" "$T/.claude/worktrees/eager-lamport" "branch name is generated (claude/eager-lamport)"
check_ctx "worker in Claude Code's worktree, told the env file is missing" "$T/.claude/worktrees/eager-lamport" "No .env here"
check_ctx "worker on a detached HEAD, told to create the task's branch" "$T/.claude/worktrees/calm-turing" "Detached HEAD"
check_ctx "a marked worktree counts as the scripts' wherever it is" "$WORK/somewhere-else" "Role: WORKER" "generated\|No .env\|Not set up"
git -C "$T/.claude/worktrees/eager-lamport" branch -q -m feat/renamed
cp "$T/.env" "$T/.claude/worktrees/eager-lamport/.env"
check_ctx "a renamed branch with its env file needs nothing more" "$T/.claude/worktrees/eager-lamport" "Role: WORKER" "generated\|No .env\|Not set up"
printf 'BASE_BRANCH="main"\nENV_FILE=".env"\nPORT_SLOTS=180\nSTART_CMD="npm run dev"\n' > "$T/.claude/worktrees/eager-lamport/scripts/agent/worktree.conf"
cp "$T/.claude/worktrees/eager-lamport/scripts/agent/worktree.conf" "$T/scripts/agent/worktree.conf"
check_ctx "a project whose worktrees run a server takes the same route" "$T" "Give every task to /dispatch" "Route:"
check_ctx "Claude Code's worktree there lacks the port and start command" "$T/.claude/worktrees/eager-lamport" "lacks a port and setup or start commands"
printf 'BASE_BRANCH="staging"\nENV_FILE=".env"\n' > "$T/.claude/worktrees/eager-lamport/scripts/agent/worktree.conf"
cp "$T/.claude/worktrees/eager-lamport/scripts/agent/worktree.conf" "$T/scripts/agent/worktree.conf"
check_ctx "the dispatcher names the branch tasks start from" "$T" "on a new branch from staging,"
check_ctx "Claude Code's worktree there started from the wrong base" "$T/.claude/worktrees/eager-lamport" "started this worktree from main, but tasks here start from staging"
printf 'BASE_BRANCH="staging" # integration\nSETUP_CMD="$(touch %s/conf-ran)"\n' "$WORK" > "$T/scripts/agent/worktree.conf"
check_ctx "worktree.conf is read as data, comments and all" "$T" "on a new branch from staging,"
if [ ! -e "$WORK/conf-ran" ]; then
    PASS=$((PASS+1)); echo "✓ session-context.sh: nothing in worktree.conf runs"
else
    FAIL=$((FAIL+1)); echo "✘ session-context.sh: a command in worktree.conf ran"
fi
git -C "$T" checkout -q -- scripts/agent/worktree.conf && rm -f "$T/.env"
for w in "$WORK/feat-role-check" "$T/.claude/worktrees/eager-lamport" "$T/.claude/worktrees/calm-turing" "$WORK/somewhere-else"; do
    git -C "$T" worktree remove --force "$w"
done

# The jq and Python helpers agree: Python is the fallback when jq isn't installed.
if command -v jq >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    event='{"cwd":"/w","tool_input":{"command":"git status","n":3},"agent_id":null}'
    printf '%s\n' '{"type":"user","message":{"content":"hi"}}' '{"type":"assistant","message":{"content":[{"type":"text","text":"Fast lane — fix it"},{"type":"tool_use"}]}}' 'not json' > "$WORK/transcript.jsonl"
    same=1
    for path in .cwd .tool_input.command .tool_input.n .agent_id .missing.deeper; do
        [ "$(printf '%s' "$event" | jq -r --arg path "$path" -f "$HOOKS_SRC/json-get.jq" 2>/dev/null)" = "$(printf '%s' "$event" | python3 "$HOOKS_SRC/json-get.py" "$path")" ] || same=""
    done
    [ "$(jq -r -f "$HOOKS_SRC/transcript-text.jq" <"$WORK/transcript.jsonl" 2>/dev/null)" = "$(python3 "$HOOKS_SRC/transcript-text.py" <"$WORK/transcript.jsonl")" ] || same=""
    if [ -n "$same" ]; then
        PASS=$((PASS+1)); echo "✓ helpers: json-get and transcript-text give the same answers in jq and Python"
    else
        FAIL=$((FAIL+1)); echo "✘ helpers: the jq and Python helpers disagree"
    fi
fi

# protect-hub — with the module, the main checkout is the hub and edits nothing
git -C "$T" worktree add -q -b feat/hub-check "$WORK/feat-hub-check"
git -C "$T" worktree add -q -b claude/calm-hopper "$T/.claude/worktrees/calm-hopper"
mkdir -p "$WORK/no-module" && git -C "$WORK/no-module" init -q
edit_event() { printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"file_path":"%s"}}' "$T" "$1"; }
run protect-hub.sh 2 "$(edit_event "$T/src/app.ts")" "stops an edit in the main checkout"
run protect-hub.sh 2 "$(edit_event "$T/src/new/file.ts")" "stops a new file in the main checkout"
run protect-hub.sh 0 "$(edit_event "$WORK/feat-hub-check/src/app.ts")" "lets edits in a task worktree through"
run protect-hub.sh 0 "$(edit_event "$T/.claude/worktrees/calm-hopper/notes.md")" "lets edits in Claude Code's own worktrees through"
run protect-hub.sh 0 "$(edit_event "$WORK/no-module/src/app.ts")" "does nothing in a repository without the module"
echo 'HUB_READONLY=""' >> "$T/.claude/hooks/config.sh"
run protect-hub.sh 0 "$(edit_event "$T/src/app.ts")" "does nothing when HUB_READONLY is empty"
git -C "$T" worktree remove --force "$WORK/feat-hub-check"; git -C "$T" worktree remove --force "$T/.claude/worktrees/calm-hopper"

# Packaged install (decision 0016): the plugin's generated scripts, with no config.sh of their own,
# load _lib.sh from CLAUDE_PLUGIN_ROOT and read the project's .claude/hooks/config.sh through
# CLAUDE_PROJECT_DIR — both set by Claude Code.
PKG_ROOT="$WORK/plugin root"; PKG="$PKG_ROOT/hooks"; mkdir -p "$PKG" && cp "$REPO_ROOT/plugins/adf/hooks/"* "$PKG/"
PROJ="$WORK/packaged"; mkdir -p "$PROJ/.claude/hooks" && git -C "$PROJ" init -q -b main
echo '<!-- Skeleton source: v2.0.0 · abc1234 (2026-10-08) · modules: none · install: packaged -->' > "$PROJ/AGENTS.md"
echo 'PROTECTED_BRANCHES="release-x"' > "$PROJ/.claude/hooks/config.sh"
pkg_push() { printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git push origin %s"}}' "$PROJ" "$1" | CLAUDE_PROJECT_DIR="$PROJ" CLAUDE_PLUGIN_ROOT="$PKG_ROOT" "$PKG/guard-git.sh" >/dev/null 2>&1; echo $?; }
if [ "$(pkg_push release-x)" = 2 ] && [ "$(pkg_push main)" = 0 ]; then
    PASS=$((PASS+1)); echo "✓ _lib.sh: packaged hooks read the project's config.sh (release-x protected, main not)"
else
    FAIL=$((FAIL+1)); echo "✘ _lib.sh: packaged hooks didn't read the project's config.sh"
fi
stand_down=$(printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git push origin main"}}' "$T" | CLAUDE_PROJECT_DIR="$T" CLAUDE_PLUGIN_ROOT="$PKG_ROOT" "$PKG/guard-git.sh" >/dev/null 2>&1; echo $?)
own=$(printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git push origin main"}}' "$T" | CLAUDE_PROJECT_DIR="$T" "$H/guard-git.sh" >/dev/null 2>&1; echo $?)
if [ "$stand_down" = 0 ] && [ "$own" = 2 ]; then
    PASS=$((PASS+1)); echo "✓ _lib.sh: the plugin's copy stands down in a committed project, whose own hook blocks"
else
    FAIL=$((FAIL+1)); echo "✘ _lib.sh: plugin copy exit $stand_down (want 0), the project's own $own (want 2)"
fi
NONE="$WORK/not-adopted"; mkdir -p "$NONE" && git -C "$NONE" init -q -b main
untouched=$(printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git push origin main"}}' "$NONE" | CLAUDE_PROJECT_DIR="$NONE" CLAUDE_PLUGIN_ROOT="$PKG_ROOT" "$PKG/guard-git.sh" >/dev/null 2>&1; echo $?)
if [ "$untouched" = 0 ]; then
    PASS=$((PASS+1)); echo "✓ _lib.sh: the plugin's copy does nothing in a project that hasn't adopted the framework"
else
    FAIL=$((FAIL+1)); echo "✘ _lib.sh: the plugin's copy acted in a project without the framework"
fi
# Decision 0024: the stamp is on AGENTS.md's first line, and a project adopted before keeps it on CLAUDE.md's.
LEGACY="$WORK/packaged-legacy"; mkdir -p "$LEGACY/.claude/hooks" && git -C "$LEGACY" init -q -b main
printf '%s\n@AGENTS.md\n' '<!-- Skeleton source: v1.4.0 · abc1234 (2026-10-06) · modules: none · install: packaged -->' > "$LEGACY/CLAUDE.md"
echo 'PROTECTED_BRANCHES="release-x"' > "$LEGACY/.claude/hooks/config.sh"
legacy=$(printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git push origin release-x"}}' "$LEGACY" | CLAUDE_PROJECT_DIR="$LEGACY" CLAUDE_PLUGIN_ROOT="$PKG_ROOT" "$PKG/guard-git.sh" >/dev/null 2>&1; echo $?)
if [ "$legacy" = 2 ]; then
    PASS=$((PASS+1)); echo "✓ _lib.sh: the plugin's copy acts in a packaged project still stamped on CLAUDE.md"
else
    FAIL=$((FAIL+1)); echo "✘ _lib.sh: the plugin's copy stood down in a project stamped on CLAUDE.md (exit $legacy, want 2)"
fi
# Decision 0024: Claude Code reads AGENTS.md only when no CLAUDE.md or CLAUDE.local.md is in the project
# or above it, so the session is told when one is.
AM="$WORK/agents-md"; mkdir -p "$AM" "$WORK/home/.claude" && git -C "$AM" init -q -b main && echo '# Project' > "$AM/AGENTS.md"
am_context() { printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$AM" | HOME="$WORK/home" "$H/session-context.sh" | grep -c "replaces this project's AGENTS.md"; }
clean=$(am_context)
touch "$AM/CLAUDE.local.md"; local_md=$(am_context)
echo '{"pluginConfigs":{"cc-plugin-agents-md@builtin":{"options":{"instructionFiles":"claude-md-and-agents-md"}}}}' > "$WORK/home/.claude/settings.json"; both=$(am_context); rm "$WORK/home/.claude/settings.json"
printf '@AGENTS.md\n' > "$AM/CLAUDE.md"; imported=$(am_context)
if [ "$clean" = 0 ] && [ "$local_md" = 1 ] && [ "$both" = 0 ] && [ "$imported" = 0 ]; then
    PASS=$((PASS+1)); echo "✓ session-context.sh: warns when a CLAUDE.local.md replaces AGENTS.md — not when none is there, the developer loads both, or a CLAUDE.md imports it"
else
    FAIL=$((FAIL+1)); echo "✘ session-context.sh: AGENTS.md warning printed clean=$clean local=$local_md (want 0 1), both=$both imported=$imported (want 0 0)"
fi
# Decision 0019: a packaged session learns where the plugin's reference docs are — unless the project
# still keeps its own copies.
mkdir -p "$PKG_ROOT/docs" && cp "$REPO_ROOT/plugins/adf/docs/"* "$PKG_ROOT/docs/"
pkg_context() { printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$PROJ" | CLAUDE_PROJECT_DIR="$PROJ" CLAUDE_PLUGIN_ROOT="$PKG_ROOT" "$PKG/session-context.sh"; }
names=$(pkg_context | grep -c -F -- "- The framework's reference docs — SPEC-MODEL.md, COST-MODEL.md, MEMORY-STRATEGY.md, MCP-INTEGRATION.md — are in $PKG_ROOT/docs/")
mkdir -p "$PROJ/docs" && echo '# Spec model' > "$PROJ/docs/SPEC-MODEL.md"
kept=$(pkg_context | grep -c "reference docs")
rm -rf "$PROJ/docs"
if [ "$names" = 1 ] && [ "$kept" = 0 ]; then
    PASS=$((PASS+1)); echo "✓ session-context.sh: a packaged session is told where the plugin's reference docs are, unless the project keeps its own"
else
    FAIL=$((FAIL+1)); echo "✘ session-context.sh: reference-docs line printed $names time(s) (want 1), $kept with local copies (want 0)"
fi
# Decision 0025: a packaged project with the parallel-agents module commits only its settings, and the
# plugin's hooks name the plugin's command for the worker's first step.
mkdir -p "$PROJ/scripts/agent" && printf 'BASE_BRANCH="main"\n' > "$PROJ/scripts/agent/worktree.conf"
echo 'HUB_READONLY="1"' >> "$PROJ/.claude/hooks/config.sh"
step=$(pkg_context | grep -c -F "Its first step is the worktree: adf-worktree-new <branch> --no-start")
hub=$(printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"file_path":"%s/src/app.ts"}}' "$PROJ" "$PROJ" | CLAUDE_PROJECT_DIR="$PROJ" CLAUDE_PLUGIN_ROOT="$PKG_ROOT" "$PKG/protect-hub.sh" 2>&1 >/dev/null; echo "exit=$?")
rm -rf "$PROJ/scripts" && echo 'PROTECTED_BRANCHES="release-x"' > "$PROJ/.claude/hooks/config.sh"
if [ "$step" = 1 ] && echo "$hub" | grep -q 'exit=2' && echo "$hub" | grep -q -F "(adf-worktree-new <branch> --no-start)"; then
    PASS=$((PASS+1)); echo "✓ packaged hooks: the module's settings alone make the hub, and the worker's first step is adf-worktree-new"
else
    FAIL=$((FAIL+1)); echo "✘ packaged hooks: first-step line printed $step time(s) (want 1); protect-hub said: $hub"
fi
# config.sh is data: quoting styles, indentation, and trailing comments parse, and nothing in it runs.
cat > "$PROJ/.claude/hooks/config.sh" <<CONF
  PROTECTED_BRANCHES='release-q' # the release branch
TRIAGE_FIRST=1
CAREFUL_GLOBS="\$(touch "$WORK/config-ran")"
CONF
if [ "$(pkg_push release-q)" = 2 ] && [ "$(pkg_push main)" = 0 ] && [ ! -e "$WORK/config-ran" ]; then
    PASS=$((PASS+1)); echo "✓ _lib.sh: config.sh is read as data — single quotes and comments parse, a \$(…) never runs"
else
    FAIL=$((FAIL+1)); echo "✘ _lib.sh: config.sh misread, or a command in it ran"
fi
echo 'PROTECTED_BRANCHES="release-x"' > "$PROJ/.claude/hooks/config.sh"
code=$(printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git push origin release-x"}}' "$T" | CLAUDE_PROJECT_DIR="$PROJ" "$H/guard-git.sh" >/dev/null 2>&1; echo $?)
if [ "$code" = 0 ]; then
    PASS=$((PASS+1)); echo "✓ _lib.sh: a committed install keeps the config next to its scripts"
else
    FAIL=$((FAIL+1)); echo "✘ _lib.sh: a committed install read another project's config"
fi

echo "==================================="
echo "Results: $PASS passed, $FAIL failed"
echo ""
[ "$FAIL" -gt 0 ] && exit 1
exit 0
