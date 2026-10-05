#!/usr/bin/env bash
#
# Checks that a project is laid out for the packaged install (decision 0016, docs/SETUP.md § Packaged
# install), pinned to <release>: no framework machinery committed, the plugin pinned and turned on, no
# hooks block, the stamp, and the names people type. Prints ✓ or ✘ per check. Read-only.
# Usage: check-packaged.sh <project> <release, e.g. v1.0.6> <the release's commit, short>
#
cd "$1" || exit 1
release="$2" commit="$3"
check() { if eval "$2"; then echo "- ✓ $1"; else echo "- ✘ $1"; fi; }
check "the stamp names $release, its commit $commit, and \`install: packaged\`" \
  "head -1 CLAUDE.md | grep -q -F 'Skeleton source: $release · $commit' && head -1 CLAUDE.md | grep -q -F 'install: packaged'"
check "no framework skills, agents, or workflows committed" \
  "[ ! -e .claude/skills/triage ] && [ ! -e .claude/skills/write-spec ] && [ ! -e .claude/agents ] && [ ! -e .claude/workflows ]"
check "\`.claude/hooks/\` holds only \`config.sh\`" "[ -f .claude/hooks/config.sh ] && [ \"\$(ls .claude/hooks)\" = config.sh ]"
check "the settings: no \`hooks\` block, the marketplace pinned to $release, \`aplyca-adf\` turned on" "python3 - '$release' <<'PY'
import json, sys
s = json.load(open('.claude/settings.json'))
source = s.get('extraKnownMarketplaces', {}).get('aplyca', {}).get('source', {})
ok = 'hooks' not in s and source.get('repo', '').lower() == 'aplyca/agenticdevelopmentframework' \
    and source.get('ref') == sys.argv[1] and s.get('enabledPlugins', {}).get('aplyca-adf@aplyca') is True
sys.exit(0 if ok else 1)
PY"
check "\`CLAUDE.md\` says the project uses the packaged install" "grep -q 'uses the packaged install' CLAUDE.md"
check "\`DEV-SETUP.md\` gives the commands by their full names" "grep -q '/aplyca-adf:triage' docs/getting-started/DEV-SETUP.md"
check "everything is committed" "[ -z \"\$(git status --short)\" ]"
