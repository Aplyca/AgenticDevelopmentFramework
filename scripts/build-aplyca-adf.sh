#!/usr/bin/env bash
#
# Builds plugins/aplyca-adf — the packaged install (docs/decisions/0016-packaged-install.md) — from
# skeleton/.claude/: the core skills, the agents as flat files, the workflows, and the hook scripts
# with their hooks.json. Claude Code puts everything a plugin carries under the plugin's name, so the
# copies name each other that way: `/triage` becomes `/aplyca-adf:triage`, `@code-reviewer` becomes
# `@aplyca-adf:code-reviewer`. The hooks read the project's .claude/hooks/config.sh.
#
# Never edit the output. Change skeleton/ and run this again; evals/static/check-skills.sh fails when
# the plugin and the skeleton drift apart.
#
# Usage: scripts/build-aplyca-adf.sh [output directory — default: plugins/aplyca-adf]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/plugins/aplyca-adf}"

python3 - "$ROOT" "$OUT" <<'PY'
import json, os, re, shutil, sys

root, out = sys.argv[1], sys.argv[2]
src = os.path.join(root, "skeleton", ".claude")
PLUGIN = "aplyca-adf"

skills = sorted(os.listdir(os.path.join(src, "skills")))
agents = sorted(os.listdir(os.path.join(src, "agents")))
workflows = sorted(f[:-3] for f in os.listdir(os.path.join(src, "workflows")) if f.endswith(".js"))

# A name counts only on its own: not inside a path (skills/review/SKILL.md), a URL, or a longer name.
command = re.compile(r"(?<![\w./@:-])/(" + "|".join(map(re.escape, skills + workflows)) + r")(?![\w-])")
agent = re.compile(r"(?<![\w./-])@(" + "|".join(map(re.escape, agents)) + r")(?![\w-])")


def rename(text):
    text = command.sub(lambda m: f"/{PLUGIN}:{m.group(1)}", text)
    return agent.sub(lambda m: f"@{PLUGIN}:{m.group(1)}", text)


def copy(source, target, executable=False):
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(source, encoding="utf-8") as f:
        text = f.read()
    with open(target, "w", encoding="utf-8") as f:
        f.write(rename(text))
    os.chmod(target, 0o755 if executable else 0o644)


if os.path.isdir(out):
    shutil.rmtree(out)
os.makedirs(os.path.join(out, ".claude-plugin"))

for name in skills:
    for directory, _, files in os.walk(os.path.join(src, "skills", name)):
        for file in files:
            path = os.path.join(directory, file)
            copy(path, os.path.join(out, "skills", os.path.relpath(path, os.path.join(src, "skills"))))
for name in agents:
    copy(os.path.join(src, "agents", name, "agent.md"), os.path.join(out, "agents", name + ".md"))
for name in workflows:
    copy(os.path.join(src, "workflows", name + ".js"), os.path.join(out, "workflows", name + ".js"))
for file in sorted(os.listdir(os.path.join(src, "hooks"))):
    if file == "config.sh":
        continue  # the project's settings stay in the project
    copy(os.path.join(src, "hooks", file), os.path.join(out, "hooks", file), executable=file.endswith(".sh"))

with open(os.path.join(src, "settings.json"), encoding="utf-8") as f:
    hooks = json.load(f)["hooks"]
wired = json.dumps({"hooks": hooks}, indent=2).replace(
    '\\"$CLAUDE_PROJECT_DIR\\"/.claude/hooks/', '\\"${CLAUDE_PLUGIN_ROOT}\\"/hooks/')
assert "CLAUDE_PROJECT_DIR" not in wired, "a hook command didn't follow the skeleton's path pattern"
with open(os.path.join(out, "hooks", "hooks.json"), "w", encoding="utf-8") as f:
    f.write(wired + "\n")

# No "version": Claude Code then versions the plugin by the commit it comes from, so each release
# tag a project pins is its own version.
manifest = {
    "name": PLUGIN,
    "description": "The Agentic Development Framework's skills, agents, workflows, and guardrail hooks, "
                   "for a packaged install: a project pins a release tag instead of committing these files. "
                   "Generated from the framework's skeleton.",
    "author": {"name": "Aplyca", "email": "dev@aplyca.com"},
    "homepage": "https://github.com/aplyca/AgenticDevelopmentFramework",
}
with open(os.path.join(out, ".claude-plugin", "plugin.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps(manifest, indent=2) + "\n")

with open(os.path.join(out, "README.md"), "w", encoding="utf-8") as f:
    f.write(f"""# aplyca-adf plugin — generated

The framework's machinery for a **packaged install** ([decision 0016](../../docs/decisions/0016-packaged-install.md)):
{len(skills)} skills, {len(agents)} agents, {len(workflows)} workflows, and the guardrail hooks. A packaged
project commits only its own layer — `AGENTS.md`, `CLAUDE.md`, the settings, `.claude/hooks/config.sh`,
the rules, `specs/`, the docs, and its modules — and pins a release of this plugin in its
`.claude/settings.json`. `/adopt` sets it up; [docs/SETUP.md](../../docs/SETUP.md) has the details.

Everything here is named under the plugin: `/{PLUGIN}:triage`, `/{PLUGIN}:deep-review`,
`@{PLUGIN}:code-reviewer`. The hooks read the project's `.claude/hooks/config.sh`.

**Don't edit these files.** They're generated from `skeleton/.claude/` by `scripts/build-aplyca-adf.sh`.
""")
print(f"{out}: {len(skills)} skills, {len(agents)} agents, {len(workflows)} workflows, "
      f"{len([f for f in os.listdir(os.path.join(out, 'hooks')) if f.endswith('.sh')])} hook scripts")
PY
