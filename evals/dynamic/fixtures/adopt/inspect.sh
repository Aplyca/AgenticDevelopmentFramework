#!/usr/bin/env bash
#
# Prints an adopt run's end state for grading: commits per branch, what was added, the version stamp,
# the planned entries, the decision records, and whether the settings parse; for the packaged case,
# checks the packaged layout (../../check-packaged.sh). Read-only.
#
cd "$1" || exit 1
if [ ! -f CLAUDE.md ]; then
  echo "Not adopted — top level: $(ls -A | tr '\n' ' ')· commits: $(git rev-list --all --count 2>/dev/null || echo 0)" \
    "· uncommitted paths: $(git status --short | wc -l | tr -d ' ')"
  exit 0
fi
echo "### Branches and commits"
echo '```'
git branch -a 2>&1
for b in $(git for-each-ref --format='%(refname:short)' refs/heads); do echo "--- $b"; git log --oneline "$b" 2>&1; done
echo "--- remotes: $(git remote | tr '\n' ' ')"
echo "--- working tree: $(git status --short | wc -l | tr -d ' ') uncommitted paths"
echo '```'
echo "### Top level"
echo '```'
ls -A
echo '```'
echo "### CLAUDE.md, first line"
echo '```'
head -1 CLAUDE.md 2>&1
echo '```'
echo "### Planned entries in AGENTS.md"
echo '```'
grep -n 'planned' AGENTS.md 2>&1 | head -20
echo '```'
echo "### Placeholders left in AGENTS.md, CONSTITUTION.md, CONTRIBUTING.md"
echo '```'
grep -n '\[[A-Z][A-Za-z ]*\]' AGENTS.md docs/CONSTITUTION.md CONTRIBUTING.md 2>/dev/null | head -10
echo "TODO(team) count: $(grep -c 'TODO(team)' AGENTS.md 2>/dev/null)"
echo '```'
echo "### AGENTS.md quick reference"
echo '```'
sed -n '/^## Quick reference/,/^## /p' AGENTS.md 2>&1 | head -20
echo '```'
echo "### Decision records"
echo '```'
for f in docs/architecture/decisions/0001-*.md docs/process/0001-*.md; do
  [ -f "$f" ] || { echo "missing: $f"; continue; }
  echo "--- $f"; grep -n -i -m3 'status' "$f"; grep -n -i -m1 'alternative' "$f"
done
echo '```'
echo "### Settings and modules"
echo '```'
python3 -m json.tool .claude/settings.json > /dev/null 2>&1 && echo ".claude/settings.json: valid JSON" || echo ".claude/settings.json: missing or invalid"
for f in GEMINI.md .agents .cursor evals .github/pull_request_template.md .githooks scripts/agent .mcp.json; do
  [ -e "$f" ] && echo "present: $f" || echo "absent:  $f"
done
echo '```'
if [ "${3:-}" = packaged ]; then
  echo "### Checks — the packaged install"
  release="$(git -C "$FW" tag --list 'v*' --sort=-v:refname | head -1)"
  bash "$(dirname "$0")/../../check-packaged.sh" . "$release" "$(git -C "$FW" rev-parse --short "$release^{commit}")"
  if grep -q -i 'packaged' docs/process/0001-*.md 2>/dev/null; then echo "- ✓ PDR-0001 records the packaged install"
  else echo "- ✘ PDR-0001 records the packaged install"; fi
fi
