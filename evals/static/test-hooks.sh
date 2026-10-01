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

git -C "$T" switch -q -c feat/newsletter-signup
# guard-git — on a work branch
run guard-git.sh 0 "$(bash_event 'git commit -m "feat: add signup form"')" "allows a commit on a work branch"
run guard-git.sh 0 "$(bash_event 'git commit -am "fix: guard against -n flag in messages"')" "ignores flags inside a quoted message"
heredoc=$'git commit -m "$(cat <<\'EOF\'\nfeat: add signup\n\nDon\'t use -n; git push origin main is mentioned here\nEOF\n)"'
run guard-git.sh 0 "$(bash_event "$heredoc")" "ignores a heredoc commit message"
run guard-git.sh 2 "$(bash_event 'git commit --no-verify -m x')" "blocks --no-verify"
run guard-git.sh 2 "$(bash_event 'git commit -nm x')" "blocks -n folded into short flags"
run guard-git.sh 2 "$(bash_event 'git merge --no-verify feat/x')" "blocks --no-verify on merge"
run guard-git.sh 0 "$(bash_event 'git push -u origin feat/newsletter-signup')" "allows pushing the work branch (permissions.ask confirms it)"
run guard-git.sh 2 "$(bash_event 'git push origin main')" "blocks a push to main"
run guard-git.sh 2 "$(bash_event 'git push origin feat/x:main')" "blocks a refspec targeting main"
run guard-git.sh 2 "$(bash_event 'git push --force-with-lease origin +main')" "blocks a force-push to main"
run guard-git.sh 2 "$(bash_event 'git push origin :master')" "blocks deleting master"
run guard-git.sh 2 "$(bash_event 'git push --all origin')" "blocks --all"
run guard-git.sh 0 "$(bash_event 'git push --dry-run origin main')" "allows a dry run"
run guard-git.sh 2 "$(bash_event "cd /tmp && git -C $T push origin main")" "follows git -C"
run guard-git.sh 2 "$(bash_event 'npm test && git push origin HEAD:refs/heads/main')" "checks every command in a chain"
run guard-git.sh 0 "$(bash_event 'echo "git push origin main is forbidden"')" "ignores a quoted mention"
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

echo "==================================="
echo "Results: $PASS passed, $FAIL failed"
echo ""
[ "$FAIL" -gt 0 ] && exit 1
exit 0
