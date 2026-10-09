#!/usr/bin/env bash
#
# Turns a run's copy of the committed v1.4.0 adoption into a packaged one, the way v1.4.0's
# docs/SETUP.md § Packaged install says. It leaves out the machinery the aplyca-adf plugin carries, the
# Cursor and Gemini layers, and the reference docs, linking them at v1.4.0. It drops the hooks block,
# adds the read rule, the names note, and the full names in DEV-SETUP.md, and stamps `install:
# packaged`. With `parallel-agents`, it adds that module's files as v1.4.0 shipped them, but not
# /dispatch, which the plugin carries. The adoption stays one commit on main.
# Usage: packaged.sh <project> <framework checkout> [parallel-agents]
#
set -euo pipefail
cd "$1"
FW="$2"
MODULE="${3:-}"
release="$(mktemp -d)"
git -C "$FW" archive v1.4.0 | tar -x -C "$release"
rm -rf .claude/skills .claude/agents .claude/workflows .claude/hooks/README.md GEMINI.md .agents .cursor \
  docs/COST-MODEL.md docs/MCP-INTEGRATION.md docs/MEMORY-STRATEGY.md docs/SPEC-MODEL.md
find .claude/hooks -type f ! -name config.sh -delete
if [ "$MODULE" = parallel-agents ]; then
  cp -R "$release/modules/parallel-agents/files/." .
  rm -rf .claude/skills
  chmod +x scripts/agent/*.sh
fi
python3 "$release/scripts/link-reference-docs.py" . --packaged v1.4.0 >/dev/null
python3 - "${MODULE:-none}" <<'PY'
import json, re, sys
from pathlib import Path
def fill(path, pairs):
    p = Path(path); s = p.read_text()
    for old, new in pairs:
        assert old in s, (path, old[:40]); s = s.replace(old, new, 1)
    p.write_text(s)
settings = json.loads(Path(".claude/settings.json").read_text())
settings.pop("hooks", None)
settings.setdefault("permissions", {}).setdefault("allow", []).append("Read(~/.claude/plugins/cache/aplyca/aplyca-adf/**)")
Path(".claude/settings.json").write_text(json.dumps(settings, indent=2) + "\n")
note = ("> **This project uses the packaged install.** Skills, agents, and workflows come from the\n"
        "> `aplyca-adf` plugin, pinned in `.claude/settings.json`. Where these files name a skill or\n"
        "> workflow — `/triage`, `/deep-review` — type `/aplyca-adf:triage`, `/aplyca-adf:deep-review`.\n"
        "> Where they name an agent — `@code-reviewer` — its name is `aplyca-adf:code-reviewer`. The\n"
        "> framework's reference docs — the spec model, the cost model, the memory strategy, MCP\n"
        "> integration — come from the plugin too; these files link them at the pinned release.\n\n")
fill("CLAUDE.md", [("## Skills, agents, and workflows\n\n", "## Skills, agents, and workflows\n\n" + note),
    ("· modules: none", f"· modules: {sys.argv[1]} · install: packaged")])
setup = Path("docs/getting-started/DEV-SETUP.md")
head, rest = setup.read_text().split("Key commands:\n", 1)
commands, tail = rest.split("\n\n", 1)
setup.write_text(head + "Key commands:\n" + re.sub(r"`([/@])([a-z])", r"`\1aplyca-adf:\2", commands) + "\n\n" + tail)
fill("docs/process/README.md", [("— committed install |", "— packaged install |")])
PY
rm -rf "$release"
git add -A && git commit -q --amend -m "docs: adopt the Agentic Development Framework (v1.4.0, packaged)"
