#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write|MultiEdit). Every environment variable the code reads must
# be declared — name only, never a value — in the env template (.env.example or similar), so the
# next developer, CI, and every deploy target knows it is required. Undeclared variables are the
# classic onboarding landmine: the app boots on one machine and fails on the next.
# The edit has already happened; exit 2 hands the message to Claude so it declares the variable.
# Only the names the edit wrote are checked — an Edit's new text, a Write's content — so a variable
# the file already read, such as one the platform provides, doesn't come back on every edit.
set -uo pipefail
export LC_ALL=C
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

file_path="$(json_get '.tool_input.file_path')"
[ -n "$file_path" ] && [ -f "$file_path" ] || exit 0

case "$file_path" in
  *.js | *.jsx | *.mjs | *.cjs | *.ts | *.tsx | *.mts | *.cts | *.vue | *.svelte | *.astro) ;;
  *.py | *.rb | *.go | *.php | *.rs | *.java | *.kt | *.cs | *.ex | *.exs) ;;
  *) exit 0 ;;
esac

repo_relative "$file_path" || exit 0
matches_any "$relative" "$ENV_CHECK_EXCLUDE" && exit 0

template="$ENV_TEMPLATE"
if [ -z "$template" ]; then
  for candidate in .env.example .env.sample .env.template .env.dist; do
    if [ -f "$root/$candidate" ]; then
      template="$candidate"
      break
    fi
  done
fi
[ -n "$template" ] && [ -f "$root/$template" ] || exit 0

name='([A-Z_][A-Z0-9_]*)'
# After a dot, the name ends where the identifier does: process.env.Path is not a variable named P.
end='([^A-Za-z0-9_]|$)'
patterns=(
  "process\\.env\\.$name$end"
  "process\\.env\\[['\"]$name['\"]\\]"
  "import\\.meta\\.env\\.$name$end"
  "os\\.environ\\[['\"]$name['\"]\\]"
  "os\\.environ\\.get\\(['\"]$name['\"]"
  "getenv\\(['\"]$name['\"]"
  "ENV\\[['\"]$name['\"]\\]"
  "ENV\\.fetch\\(['\"]$name['\"]"
  "os\\.Getenv\\(\"$name\""
  "os\\.LookupEnv\\(\"$name\""
  "\\\$_ENV\\[['\"]$name['\"]\\]"
  "env::var\\(\"$name\""
  "System\\.getenv\\(\"$name\""
  "Environment\\.GetEnvironmentVariable\\(\"$name\""
  "System\\.get_env\\(\"$name\""
)

written="$(json_get '.tool_input.new_string')"
[ -n "$written" ] || written="$(json_get '.tool_input.content')"
[ -n "$written" ] || written="$(cat "$file_path")" # a MultiEdit, or an event without the text

found=""
for pattern in "${patterns[@]}"; do
  while IFS= read -r match; do
    [[ $match =~ $pattern ]] && found="$found ${BASH_REMATCH[1]}"
  done < <(printf '%s\n' "$written" | grep -oE "$pattern" 2>/dev/null)
done

missing=""
set -f
for variable in $(printf '%s\n' $found | sort -u); do
  ignored=""
  for ignore in $ENV_IGNORE; do
    if [[ $variable == $ignore ]]; then
      ignored=1
      break
    fi
  done
  [ -n "$ignored" ] && continue
  if ! grep -qE "^[[:space:]]*(#[[:space:]]*)?(export[[:space:]]+)?$variable=" "$root/$template"; then
    missing="$missing $variable"
  fi
done
set +f

if [ -n "$missing" ]; then
  echo "$relative reads${missing} but $template does not declare it. Add each name to $template with a placeholder or a comment — never a real value — so every environment knows it is required. A variable the platform sets for you (PORT, VERCEL_URL…) goes in ENV_IGNORE in .claude/hooks/config.sh instead." >&2
  exit 2
fi
exit 0
