#!/usr/bin/env bash
#
# Prints an adopt run's end state for grading: commits per branch, what was added, the version stamp,
# the planned entries, the decision records, and whether the settings parse; for the packaged case,
# checks the packaged layout (../../check-packaged.sh); for the legacy-instructions case, checks where
# each line of the project's CLAUDE.md went (decision 0099). Read-only.
#
cd "$1" || exit 1
if ! head -1 AGENTS.md 2>/dev/null | grep -q 'Skeleton source:'; then
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
echo "### AGENTS.md, first line · CLAUDE.md"
echo '```'
head -1 AGENTS.md 2>&1
[ -e CLAUDE.md ] && echo "CLAUDE.md present — Claude Code reads it instead of AGENTS.md" || echo "no CLAUDE.md"
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
for f in GEMINI.md .gemini .agents .cursor evals .github/pull_request_template.md .githooks ops/agent scripts/agent .mcp.json; do
  [ -e "$f" ] && echo "present: $f" || echo "absent:  $f"
done
echo '```'
if [ "${3:-}" = packaged ]; then
  echo "### Checks — the packaged install"
  release="$(git -C "$FW" tag --list 'v*' --sort=-v:refname | head -1)"
  bash "$(dirname "$0")/../../check-packaged.sh" . "$release" "$(git -C "$FW" rev-parse --short "$release^{commit}")" "$FW"
  if grep -q -i 'packaged' docs/process/0001-*.md 2>/dev/null; then echo "- ✓ PDR-0001 records the packaged install"
  else echo "- ✘ PDR-0001 records the packaged install"; fi
fi
if [ "${3:-}" = legacy-instructions ]; then
  echo "### Checks — the compatibility pass (decision 0099)"
  mark() { if [ "$1" = 0 ]; then echo "- ✓ $2"; else echo "- ✘ $2"; fi; }
  adoption=$(git for-each-ref --format='%(refname:short)' refs/heads | grep -vx main | head -1)
  [ "$(git rev-list --count main 2>/dev/null)" = 1 ] && [ -n "$adoption" ] && [ "$(git rev-list --count "main..$adoption")" -ge 1 ]
  mark $? "main keeps its one commit; the adoption is on its own branch${adoption:+ ($adoption)}"
  [ -z "$(git status --porcelain)" ]; mark $? "everything is committed"
  [ ! -e CLAUDE.md ]; mark $? "no CLAUDE.md"
  ! grep -rqiE 'before every commit|confirm each step' AGENTS.md .claude/rules 2>/dev/null
  mark $? "no instruction file asks before each commit or confirms each step"
  grep -qF 'pnpm test' AGENTS.md && grep -qF 'legacy/' AGENTS.md; mark $? "AGENTS.md names \`pnpm test\` and \`legacy/\`"
  python3 - <<'PY'
import re, sys
text = re.sub(r"<!--.*?-->", "", open("AGENTS.md", encoding="utf-8").read(), flags=re.S)
def section(name):
    m = re.search(r"^## " + name + r"\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    return m.group(1) if m else ""
ready = re.search(r"(person|people|human|developer|tech lead)\w*\s+(marks?|moves?|sets?|flips?)\b[^.\n]{0,40}\bready\b",
                  section("Delivery rules"), re.I)
print(("- ✓" if ready else "- ✘") + " § Delivery rules says a person marks pull requests ready")
sensitive = "src/newsletter" in section("Sensitive areas")
config = open(".claude/hooks/config.sh", encoding="utf-8").read()
careful = re.search(r'^CAREFUL_GLOBS="[^"]*src/newsletter', config, re.M)
print(("- ✓" if sensitive and careful else "- ✘") + " `src/newsletter/` is in § Sensitive areas and CAREFUL_GLOBS")
PY
  echo "- AGENTS.md: $(wc -c < AGENTS.md | tr -d ' ') characters (the skeleton's budget is 21,000)"
fi
