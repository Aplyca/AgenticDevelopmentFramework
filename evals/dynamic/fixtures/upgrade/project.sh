#!/usr/bin/env bash
#
# The project for the upgrade cases: a committed adoption at v1.0.0 — the skeleton from the framework's
# v1.0.0 tag, without the Antigravity and Cursor layers (a team that works in Claude Code only), the
# plugin pinned to v1.0.0, a filled-in PDR-0001, and the stamp — all committed on main.
# Usage: project.sh <project> <framework checkout>
#
set -euo pipefail
cd "$1"
FW="$2"
git init -q -b main && git config user.email dev@example.com && git config user.name dev
git -C "$FW" archive v1.0.0 skeleton | tar -x --strip-components=1
rm -rf .agents .cursor GEMINI.md evals
python3 - <<'PY'
import json, re
from pathlib import Path
def fill(path, pairs):
    p = Path(path); s = p.read_text()
    for old, new in pairs:
        assert old in s, (path, old[:40]); s = s.replace(old, new)
    p.write_text(s)
claude = Path("CLAUDE.md").read_text().split("\n", 1)
Path("CLAUDE.md").write_text("<!-- Skeleton source: v1.0.0 · cf1776b (2026-10-02) · modules: none — see docs/UPGRADING.md in AgenticDevelopmentFramework -->\n" + claude[1])
fill("CLAUDE.md", [("# [PROJECT NAME] — Claude Code", "# Newsletter Site — Claude Code")])
fill("AGENTS.md", [("# [PROJECT NAME]", "# Newsletter Site"),
    ("[One paragraph: what this project is, who uses it, and its stage — PoC, MVP, or production.]",
     "The marketing site for a publisher: article pages and a newsletter signup. In production.")])
settings = json.loads(Path(".claude/settings.json").read_text())
settings["extraKnownMarketplaces"] = {"aplyca": {"source": {"source": "github", "repo": "aplyca/AgenticDevelopmentFramework", "ref": "v1.0.0"}}}
settings["enabledPlugins"] = {"aplyca-adf@aplyca": True}
Path(".claude/settings.json").write_text(json.dumps(settings, indent=2) + "\n")
template = Path("docs/process/0000-pdr-template.md").read_text()
pdr = re.sub(r"^# PDR NNNN: .*$", "# PDR 0001: Adopt the AI-assisted development workflow", template, flags=re.M)
pdr = pdr.replace("proposed | accepted | superseded by PDR-NNNN", "accepted").replace("YYYY-MM-DD", "2026-10-02") \
    .replace("[who]", "the tech lead").replace('[PDR-NNNN, or "—"]', "—")
Path("docs/process/0001-adopt-ai-assisted-workflow.md").write_text(pdr)
fill("docs/process/README.md", [("| 0001 | [`0001-adopt-ai-assisted-workflow.md` — Adopt the AI-assisted development workflow] | [accepted] |",
    "| 0001 | [Adopt the AI-assisted development workflow](0001-adopt-ai-assisted-workflow.md) — committed install | accepted |")])
PY
git add -A && git commit -q -m "docs: adopt the Agentic Development Framework (v1.0.0)"
