#!/usr/bin/env bash
#
# Builds a project on the packaged install as /adopt leaves it on a release whose plugin carries the
# reference docs (decision 0019): the skeleton without the machinery or the four reference docs, its
# links pointing at the release on GitHub, the names note in CLAUDE.md, and install: packaged in the
# stamp — so the aplyca-adf plugin, loaded per session with --plugin-dir, acts. On a work branch with
# the delivered newsletter-signup spec folder from docs/examples/.
#
cd "$1" || exit 1
FW="$2"
git init -q -b main && git config user.email dev@example.com && git config user.name dev
cp -R "$FW/skeleton/." .
rm -rf .claude/skills .claude/agents .claude/workflows .cursor GEMINI.md
find .claude/hooks -type f ! -name config.sh -delete
rm -f docs/COST-MODEL.md docs/MCP-INTEGRATION.md docs/MEMORY-STRATEGY.md docs/SPEC-MODEL.md
python3 "$FW/scripts/link-reference-docs.py" . --packaged v1.1.0 >/dev/null
mkdir -p specs/007-newsletter-signup && cp "$FW"/docs/examples/newsletter-signup/{spec,plan,tasks}.md specs/007-newsletter-signup/
python3 - <<'PY'
import json
from pathlib import Path
claude = Path("CLAUDE.md").read_text().split("\n", 1)[1]
note = ("**This project uses the packaged install.** Skills, agents, and workflows come from the `aplyca-adf` plugin, "
        "pinned in `.claude/settings.json`. Where these files name a skill or workflow — `/triage`, `/deep-review` — type "
        "`/aplyca-adf:triage`, `/aplyca-adf:deep-review`. Where they name an agent — `@code-reviewer` — its name is "
        "`aplyca-adf:code-reviewer`. The framework's reference docs — the spec model, the cost model, the memory strategy, "
        "MCP integration — come from the plugin too; these files link them at the pinned release.\n\n")
claude = claude.replace("# [PROJECT NAME] — Claude Code", "# Newsletter Site — Claude Code\n\n" + note, 1)
Path("CLAUDE.md").write_text("<!-- Skeleton source: v1.1.0 · de05c95 (2026-10-04) · modules: none · install: packaged -->\n" + claude)
settings = json.loads(Path(".claude/settings.json").read_text())
settings.pop("hooks", None)
settings["permissions"]["allow"].append("Read(~/.claude/plugins/cache/aplyca/aplyca-adf/**)")
Path(".claude/settings.json").write_text(json.dumps(settings, indent=2) + "\n")
PY
git add -A && git commit -q -m "chore: adopt the Agentic Development Framework (packaged)"
git switch -q -c feat/newsletter-signup
