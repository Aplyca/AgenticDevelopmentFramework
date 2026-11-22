#!/usr/bin/env bash
#
# The project for the scripted-upgrade case: a packaged adoption at v2.3.0 with the docker module —
# the skeleton and the module's settings from that tag, the plugin pinned to v2.3.0, the stamp, a
# Makefile with a task that deletes data, two allow rules a broader one covers, and the team's own
# lines in AGENTS.md and a customizable rule — all committed on main. No parallel-agents: with it the
# project is a hub, and the upgrade would first dispatch itself into a worktree.
# Usage: project-v2.sh <project> <framework checkout>
#
set -euo pipefail
cd "$1"
FW="$2"
TAG=v2.3.0
SHA=$(git -C "$FW" rev-parse --short "$TAG^{commit}")
git init -q -b main && git config user.email dev@example.com && git config user.name dev
git -C "$FW" archive "$TAG" skeleton modules/docker | tar -x
cp -R skeleton/. . && sh modules/docker/install.sh . >/dev/null
rm -rf skeleton modules .agents .cursor .gemini evals
python3 - "$TAG" "$SHA" <<'PY'
import json, sys
from pathlib import Path
tag, sha = sys.argv[1:]
settings = json.loads(Path(".claude/settings.json").read_text())
settings.pop("hooks", None)  # packaged: the plugin's hooks.json wires them
settings["permissions"]["allow"] += ["Bash(git status)", "Bash(make test)", "Read(~/.claude/plugins/cache/aplyca/adf/**)"]
settings["extraKnownMarketplaces"] = {"aplyca": {"source": {"source": "github", "repo": "aplyca/AgenticDevelopmentFramework", "ref": tag}}}
settings["enabledPlugins"] = {"adf@aplyca": True}
Path(".claude/settings.json").write_text(json.dumps(settings, indent=2) + "\n")
agents = Path("AGENTS.md").read_text().split("\n", 1)[1]
agents = agents.replace("# [PROJECT NAME]", "# Newsletter Site", 1)
agents += "\n## Team notes\n\nThe newsletter service owns the subscriber list; never write to it from the site.\n"
Path("AGENTS.md").write_text(
    f"<!-- Skeleton source: {tag} · {sha} (2026-10-15) · modules: docker · install: packaged — update on every framework upgrade. See docs/UPGRADING.md in AgenticDevelopmentFramework. -->\n" + agents)
with open(".claude/rules/deployment.md", "a") as f:
    f.write("\n<!-- team: deploys go through the newsletter pipeline, never by hand -->\n")
Path("Makefile").write_text(
    ".PHONY: dev test wipe-db\ndev:\n\tdocker compose up\ntest:\n\tpnpm test\nwipe-db:\n\tdocker compose down -v\n")
PY
git add -A && git commit -q -m "docs: adopt the Agentic Development Framework ($TAG, packaged)"
