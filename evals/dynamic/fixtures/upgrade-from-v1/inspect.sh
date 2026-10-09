#!/usr/bin/env bash
#
# Prints an upgrade-from-v1 run's end state, and checks what v2.0.0 asks of every v1 project. Every
# case is checked for main untouched, the stamp on AGENTS.md at the newest release, no CLAUDE.md or
# GEMINI.md, the Claude Code rule, the plugin's new name, and no old names left. The committed case
# also needs the machinery that build-committed.py writes at the release. The packaged cases need the
# packaged layout (../../check-packaged.sh), and with parallel-agents, the module in ops/agent/
# without the scripts the plugin's commands replace. Read-only.
# Usage: inspect.sh <run copy> <session output .jsonl> <case>
#
cd "$1" || exit 1
release="$(git -C "$FW" tag --list 'v*' --sort=-v:refname | head -1)"
commit="$(git -C "$FW" rev-parse --short "$release^{commit}")"
echo "### Branches and commits"
echo '```'
for b in $(git for-each-ref --format='%(refname:short)' refs/heads); do echo "--- $b"; git log --oneline "$b" 2>&1 | head -5; done
echo "--- current: $(git branch --show-current) · working tree: $(git status --short | wc -l | tr -d ' ') uncommitted paths"
echo '```'
echo "### AGENTS.md, first line · instruction files · .claude/"
echo '```'
head -1 AGENTS.md
for f in CLAUDE.md GEMINI.md .gemini/settings.json .claude/rules/claude-code.md; do [ -e "$f" ] && echo "$f present" || echo "no $f"; done
ls .claude .claude/hooks 2>&1
echo '```'
echo "### Checks — upgrading from v1.4.0 to $release"
check() { if eval "$2"; then echo "- ✓ $1"; else echo "- ✘ $1"; fi; }
check "\`main\` is untouched: the upgrade is on its own branch" \
  "[ \"\$(git rev-list --count main)\" = 1 ] && [ \"\$(git branch --show-current)\" != main ]"
check "\`AGENTS.md\`'s stamp names $release and its commit $commit" "head -1 AGENTS.md | grep -q -F 'Skeleton source: $release · $commit'"
check "no \`CLAUDE.md\` or \`GEMINI.md\` (decisions 0024, 0025)" "[ ! -e CLAUDE.md ] && [ ! -e GEMINI.md ]"
check "\`.claude/rules/claude-code.md\` holds the Claude Code layer" "[ -f .claude/rules/claude-code.md ] && grep -q '^## Skills, agents, and workflows' .claude/rules/claude-code.md"
check "the settings turn on \`adf@aplyca\`, not \`aplyca-adf@aplyca\`, pinned to $release" "python3 - '$release' <<'PY'
import json, sys
s = json.load(open('.claude/settings.json'))
plugins = s.get('enabledPlugins', {})
ref = s.get('extraKnownMarketplaces', {}).get('aplyca', {}).get('source', {}).get('ref')
sys.exit(0 if plugins.get('adf@aplyca') is True and 'aplyca-adf@aplyca' not in plugins and ref == sys.argv[1] else 1)
PY"
check "no \`aplyca-adf:\` name left in the project's files" "! git grep -q 'aplyca-adf:'"
check "everything is committed" "[ -z \"\$(git status --short)\" ]"
case "${3:-}" in
  committed)
    built="$(mktemp -d)"
    git -C "$FW" archive "$release" | tar -x -C "$built" && mkdir "$built/project" \
      && python3 "$built/scripts/build-committed.py" "$built/project" >/dev/null 2>&1
    check "the machinery is $release's, as \`build-committed.py\` writes it" \
      "(for d in .claude/skills .claude/agents .claude/workflows; do diff -rq '$built/project/'\$d \$d >/dev/null || exit 1; done; diff -rq -x config.sh '$built/project/.claude/hooks' .claude/hooks >/dev/null && for f in COST-MODEL MCP-INTEGRATION MEMORY-STRATEGY SPEC-MODEL; do cmp -s '$built/project/docs/'\$f.md docs/\$f.md || exit 1; done)"
    check "the settings still wire the hooks" "python3 -c 'import json; exit(0 if \"hooks\" in json.load(open(\".claude/settings.json\")) else 1)'"
    check "\`.gemini/settings.json\` points Gemini CLI at \`AGENTS.md\`" "grep -qs 'AGENTS.md' .gemini/settings.json"
    rm -rf "$built" ;;
  packaged | packaged-parallel-agents)
    echo
    bash "$(dirname "$0")/../../check-packaged.sh" . "$release" "$commit" "$FW" ;;
esac
if [ "${3:-}" = packaged-parallel-agents ]; then
  check "the module is in \`ops/agent/\`, and \`scripts/agent/\` is gone (decision 0032)" "[ -f ops/agent/worktree.conf ] && [ ! -e scripts/agent ]"
  check "no worktree scripts committed — \`adf\`'s commands replace them (decision 0027)" "[ -d ops/agent ] && ! ls ops/agent | grep -q '\.sh\$'"
  check "nothing names \`scripts/agent/\` any more" "! git grep -q 'scripts/agent/'"
fi
