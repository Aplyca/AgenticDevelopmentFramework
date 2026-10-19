#!/usr/bin/env bash
#
# Prints an upgrade run's end state — branches and commits, the stamp, the settings — and, for the
# switch-to-packaged case, checks the packaged layout (../../check-packaged.sh), the PDR that records
# the switch, and that main is untouched. Read-only.
# Usage: inspect.sh <run copy> <session output .jsonl> <case>
#
cd "$1" || exit 1
echo "### Branches and commits"
echo '```'
for b in $(git for-each-ref --format='%(refname:short)' refs/heads); do echo "--- $b"; git log --oneline "$b" 2>&1 | head -5; done
echo "--- current: $(git branch --show-current) · working tree: $(git status --short | wc -l | tr -d ' ') uncommitted paths"
echo '```'
echo "### AGENTS.md, first line · CLAUDE.md · .claude/ · docs/process/"
echo '```'
head -1 AGENTS.md
[ -e CLAUDE.md ] && echo "CLAUDE.md still present" || echo "no CLAUDE.md"
ls .claude .claude/hooks 2>&1
ls docs/process
echo '```'
if [ "${3:-}" = switch-to-packaged ]; then
  echo "### Checks — the switch to the packaged install"
  release="$(git -C "$FW" tag --list 'v*' --sort=-v:refname | head -1)"
  bash "$(dirname "$0")/../../check-packaged.sh" . "$release" "$(git -C "$FW" rev-parse --short "$release^{commit}")" "$FW"
  check() { if eval "$2"; then echo "- ✓ $1"; else echo "- ✘ $1"; fi; }
  check "a new PDR records the switch to the packaged install" \
    "ls docs/process | grep -v -E '^(0000|0001)-|README' | grep -q . && grep -l -i 'packaged' \$(ls docs/process/*.md | grep -v -E '/(0000|0001)-|README') >/dev/null"
  check "PDR-0001 is marked amended" "grep -q -i 'amend' docs/process/0001-*.md"
  check "\`main\` is untouched: the switch is on its own branch" "[ \"\$(git rev-list --count main)\" = 1 ] && [ \"\$(git branch --show-current)\" != main ]"
fi
if [ "${3:-}" = scripted-upgrade ]; then
  echo "### Checks — the scripted upgrade"
  check() { if eval "$2"; then echo "- ✓ $1"; else echo "- ✘ $1"; fi; }
  gd="$(git rev-parse --absolute-git-dir)"
  transcripts="$2 ${2%.jsonl}.2.jsonl"
  # The Bash commands of both turns, in order, one per line.
  cmds="$(python3 - $transcripts <<'PY'
import json, sys
for path in sys.argv[1:]:
    try:
        lines = open(path)
    except OSError:
        continue
    for raw in lines:
        try:
            d = json.loads(raw)
        except ValueError:
            continue
        for block in (d.get("message") or {}).get("content", []) if d.get("type") == "assistant" else []:
            if isinstance(block, dict) and block.get("type") == "tool_use" and block.get("name") == "Bash":
                print(" ".join(block["input"].get("command", "").split()))
PY
)"
  dry=$(printf '%s\n' "$cmds" | grep -n 'adf-upgrade.*--dry-run' | head -1 | cut -d: -f1)
  real=$(printf '%s\n' "$cmds" | grep -n 'adf-upgrade' | grep -v -e '--dry-run' | head -1 | cut -d: -f1)
  check "adf-upgrade --dry-run ran before the run" "[ -n '$dry' ] && [ -n '$real' ] && [ '$dry' -lt '$real' ]"
  check "\`main\` is untouched: the upgrade is on its own branch" "[ \"\$(git rev-list --count main)\" = 1 ] && [ \"\$(git branch --show-current)\" != main ]"
  check "everything is committed" "[ -z \"\$(git status --porcelain)\" ] && [ \"\$(git rev-list --count HEAD)\" -gt 1 ]"
  check "nothing was pushed" "! printf '%s\n' \"\$cmds\" | grep -q 'git push'"
  check "AGENTS.md keeps the team's line" "grep -q 'never write to it from the site' AGENTS.md"
  check "the stamp moved past v2.3.0 and keeps install: packaged and the docker module" \
    "head -1 AGENTS.md | grep -q 'install: packaged' && head -1 AGENTS.md | grep -q 'modules: docker' && ! head -1 AGENTS.md | grep -q 'v2.3.0'"
  check "deployment.md keeps the team's comment" "grep -q 'newsletter pipeline' .claude/rules/deployment.md"
  check "settings.json parses and has no hooks block" "python3 -c 'import json,sys; sys.exit(\"hooks\" in json.load(open(\".claude/settings.json\")))'"
  check "autoUpdate is on the aplyca entry" \
    "python3 -c 'import json,sys; sys.exit(not json.load(open(\".claude/settings.json\"))[\"extraKnownMarketplaces\"][\"aplyca\"].get(\"autoUpdate\"))'"
  rules() { python3 -c 'import json,sys; print(json.dumps(json.load(open(".claude/settings.json"))["permissions"].get(sys.argv[1], [])))' "$1"; }
  check "covered allow rules are gone; the covering ones stay" \
    "! rules allow | grep -q 'Bash(make test)' && ! rules allow | grep -q 'Bash(git status)' && rules allow | grep -q 'Bash(make \*)' && rules allow | grep -q 'Bash(git \*)'"
  check "the docker ask rules are still there" "rules ask | grep -q 'docker rm \*'"
  check "the task that deletes data has an ask rule" "rules ask | grep -q 'make wipe-db'"
  check "the report was written" "[ -f '$gd/adf-upgrade/report.md' ] && [ -f '$gd/adf-upgrade/report.json' ]"
  check "the Follow-ups section is in the report" "grep -q '^## Follow-ups' '$gd/adf-upgrade/report.md'"
fi
