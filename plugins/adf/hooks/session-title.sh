#!/usr/bin/env bash
# UserPromptSubmit hook. Names a terminal session after its task, as /adf:triage does in the desktop
# app: no tool lets the agent rename a session in a terminal, but a hook's sessionTitle does, the same
# as /rename. Once a reply states the triage — "Triage — <task title> (<link>)", or the one-line
# "Fast lane — <request>; …" — the next prompt sets the title to the task's title alone, with no lane
# or link, once per session. A title already set (/rename, --name) stays, and in the desktop app the
# agent names the session itself (triage step 5), so the hook stands aside. Empty SESSION_TITLE turns
# the hook off.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$SESSION_TITLE" ] || exit 0
[ "${CLAUDE_CODE_ENTRYPOINT:-}" != "claude-desktop" ] || exit 0
[ -z "$(json_get '.session_title')" ] || exit 0

session="$(json_get '.session_id' | tr -cd 'A-Za-z0-9_-')"
transcript="$(json_get '.transcript_path')"
[ -n "$session" ] && [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

tmp_dir="${TMPDIR:-}"
[ -d "$tmp_dir" ] || tmp_dir="/tmp"
state="$tmp_dir/claude-session-title-$session"
[ -f "$state" ] && exit 0

# Only the transcript's lines that can hold a triage are parsed: the hook runs on every prompt.
if command -v jq >/dev/null 2>&1; then
  replies="$(grep -E 'Triage|Fast [Ll]ane' "$transcript" | jq -r -f "${CLAUDE_PLUGIN_ROOT}/hooks/transcript-text.jq" 2>/dev/null)"
else
  replies="$(grep -E 'Triage|Fast [Ll]ane' "$transcript" | python3 "${CLAUDE_PLUGIN_ROOT}/hooks/transcript-text.py" 2>/dev/null)"
fi

# The first line that opens with a triage — not its template — once bold, code, quote, and heading
# marks are set aside.
line="$(printf '%s\n' "$replies" | LC_ALL=C sed -E 's/\*\*|`//g; s/^[[:space:]>#]*//' |
  LC_ALL=C grep -m 1 -E '^(Triage|Fast [Ll]ane)([[:space:]]+(—|–|-)|:)[[:space:]]+[^<[:space:]]')"
# The full form's title, without the task's link: a trailing parenthesis holding a URL, a Markdown
# link, or an issue reference, or a bare URL at the end.
full='s/^Triage([[:space:]]+(—|–|-)|:)[[:space:]]+//
s/[[:space:]]*\((\[[^]]*\]\([^)]*\)|[^()]*:\/\/[^()]*|[^()[:space:]]*#[0-9]+)\)[[:space:]]*$//
s/[[:space:]]+<?[a-z]+:\/\/[^[:space:]]*$//'
# The fast lane's request: up to the first semicolon, capitalized unless it opens like "iOS".
fast='s/^Fast [Ll]ane([[:space:]]+(—|–|-)|:)[[:space:]]+//
s/;.*//'
case "$line" in
  Triage*) title="$(printf '%s' "$line" | LC_ALL=C sed -E "$full")" ;;
  Fast*) title="$(printf '%s' "$line" | LC_ALL=C sed -E "$fast" | LC_ALL=C awk '/^[a-z][^A-Z]/ { $0 = toupper(substr($0, 1, 1)) substr($0, 2) } 1')" ;;
  *) exit 0 ;;
esac
title="$(printf '%s' "$title" | LC_ALL=C sed -E 's/\[([^]]*)\]\([^)]*\)/\1/g; s/([[:space:].:-]|—|–)+$//')"
[ -n "$title" ] || exit 0

touch "$state"
if command -v jq >/dev/null 2>&1; then
  printf '%s' "$title" | jq -cRs -f "${CLAUDE_PLUGIN_ROOT}/hooks/session-title.jq"
else
  printf '%s' "$title" | python3 "${CLAUDE_PLUGIN_ROOT}/hooks/session-title.py"
fi
