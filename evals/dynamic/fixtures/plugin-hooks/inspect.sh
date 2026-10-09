#!/usr/bin/env bash
#
# Checks a plugin-hooks run: the hook the case exercises fired (or, for stand-down, didn't), from the
# session's output and — for a PostToolUse hook, whose message reaches Claude only there — its
# transcript. Prints ✓ or ✘ per check, then the end state. Read-only.
# Usage: inspect.sh <run copy> <session output .jsonl> <case>
#
work="$1" out="$2" case_name="$3"
has() { grep -q -F -- "$1" "$out"; }
transcript() {
  local sid
  sid="$(grep -m1 '"subtype":"init"' "$out" | python3 -c 'import json, sys; print(json.loads(sys.stdin.read() or "{}").get("session_id", ""))')"
  [ -n "$sid" ] && find ~/.claude/projects -name "$sid.jsonl" 2>/dev/null | head -1
}
check() { if eval "$2"; then echo "- ✓ $1"; else echo "- ✘ $1"; fi; }
echo "### Checks"
case "$case_name" in
  session-context) check "session-context names the branch's spec folder and its status" \
    "has 'Spec folder for this branch: specs/007-newsletter-signup/ (status: draft)'" ;;
  guard-git) check "guard-git blocks --no-verify" "has 'Blocked by the guard-git hook: --no-verify'" ;;
  triage-first) check "triage-first reminds before the first edit when no lane is stated" \
    "has 'write the triage as your next message'" ;;
  protect-paths) check "protect-paths blocks a hand edit to a generated file" "has 'package-lock.json is generated'" ;;
  careful-paths) check "careful-paths stops the first edit in a sensitive area" "has 'is in a sensitive area'" ;;
  check-env-declared) check "check-env-declared reports the undeclared variable to Claude" \
    "grep -q -F 'reads NEWSLETTER_LIST_ID but .env.example does not declare it' \"\$(transcript)\"" ;;
  stand-down)
    check "the plugin's guard stays out of a committed project" "! has 'Blocked by the guard-git hook'"
    check "the plugin's session context stays out of a committed project" "! has 'Session context (the session-context hook):'" ;;
esac
echo "### End state"
echo '```'
cd "$work" && git log --oneline -3 && git status --short && head -1 AGENTS.md
echo '```'
