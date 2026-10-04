#!/usr/bin/env bash
#
# Builds the packaged half of plugins/aplyca-adf (docs/decisions/0016-packaged-install.md) from
# skeleton/.claude/: the core skills, the agents as flat files, the workflows, and the hook scripts
# with their hooks.json. Claude Code puts everything a plugin carries under the plugin's name, so the
# copies name each other that way: `/triage` becomes `/aplyca-adf:triage`, `@code-reviewer` becomes
# `@aplyca-adf:code-reviewer`. The hooks read the project's .claude/hooks/config.sh. The copies act only
# in a packaged project: each skill and agent opens with a step that hands over to the committed copy
# unless CLAUDE.md says "This project uses the packaged install" (visible text — Claude Code strips the
# HTML-comment stamp when it loads the file), and the hooks stand down unless the stamp on CLAUDE.md's
# first line says `install: packaged` (_lib.sh, which reads the file itself).
#
# The installer's skills (adopt, upgrade, cost-report), plugin.json, and README.md are written by
# hand and left alone: the script rebuilds only the paths it lists in .generated. Never edit those
# paths. Change skeleton/ and run this again; evals/static/check-skills.sh fails when the plugin and
# the skeleton drift apart.
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


def copy(source, target, executable=False, kind=None, name=None):
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(source, encoding="utf-8") as f:
        text = rename(f.read())
    if kind:
        text = hand_over(text, kind, name)
    with open(target, "w", encoding="utf-8") as f:
        f.write(text)
    os.chmod(target, 0o755 if executable else 0o644)


HANDOVER = {
    "skill": "> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). "
             "Unless this project's `CLAUDE.md` says \"This project uses the packaged install\", stop here: open "
             "`.claude/skills/{name}/SKILL.md` and follow that file instead — it's the version this project "
             "upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.\n\n",
    "agent": "> **Step 0 — which copy.** This is the packaged copy. Unless this project's `CLAUDE.md` says "
             "\"This project uses the packaged install\", open `.claude/agents/{name}/agent.md` and follow that file "
             "instead of this one.\n\n",
}


def hand_over(text, kind, name):
    # After the frontmatter, so the name and description still come first.
    head, sep, body = text.partition("\n---\n")
    return head + sep + "\n" + HANDOVER[kind].format(name=name) + body.lstrip("\n")


listing = os.path.join(out, ".generated")
if os.path.exists(listing):
    for rel in open(listing, encoding="utf-8").read().split():
        path = os.path.join(out, rel)
        if os.path.isdir(path):
            shutil.rmtree(path)
        elif os.path.exists(path):
            os.remove(path)
generated = []

for name in skills:
    for directory, _, files in os.walk(os.path.join(src, "skills", name)):
        for file in files:
            path = os.path.join(directory, file)
            copy(path, os.path.join(out, "skills", os.path.relpath(path, os.path.join(src, "skills"))),
                 kind="skill" if file == "SKILL.md" else None, name=name)
    generated.append(f"skills/{name}")
for name in agents:
    copy(os.path.join(src, "agents", name, "agent.md"), os.path.join(out, "agents", name + ".md"), kind="agent", name=name)
for name in workflows:
    copy(os.path.join(src, "workflows", name + ".js"), os.path.join(out, "workflows", name + ".js"))
LIB_SOURCE = '. "$(dirname "$0")/_lib.sh"'
HOOKS_DIR_LINE = 'HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
for file in sorted(os.listdir(os.path.join(src, "hooks"))):
    if file == "config.sh":
        continue  # the project's settings stay in the project
    target = os.path.join(out, "hooks", file)
    copy(os.path.join(src, "hooks", file), target, executable=file.endswith(".sh"))
    if file.endswith(".sh"):
        # The Claude Directory refuses a path the shell computes for a file a hook loads or runs: the
        # plugin's copies name _lib.sh, the hooks folder, and the helpers in it literally.
        with open(target, encoding="utf-8") as f:
            text = f.read()
        if file == "_lib.sh":
            assert text.count(HOOKS_DIR_LINE) == 1, "_lib.sh doesn't find its folder the skeleton's way"
            text = text.replace(HOOKS_DIR_LINE, 'HOOKS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks"')
        else:
            assert text.count(LIB_SOURCE) == 1, f"{file} doesn't load _lib.sh the skeleton's way"
            text = text.replace(LIB_SOURCE, 'source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"')
        text = text.replace('"$HOOKS_DIR/', '"${CLAUDE_PLUGIN_ROOT}/hooks/').replace('"$HOOKS_DIR"', '"${CLAUDE_PLUGIN_ROOT}/hooks"')
        with open(target, "w", encoding="utf-8") as f:
            f.write(text)
generated += ["agents", "workflows", "hooks"]

with open(os.path.join(src, "settings.json"), encoding="utf-8") as f:
    hooks = json.load(f)["hooks"]
for groups in hooks.values():
    for group in groups:
        for hook in group["hooks"]:
            command = re.fullmatch(r'"\$CLAUDE_PROJECT_DIR"/\.claude/hooks/([a-z-]+\.sh)', hook["command"])
            assert command, f"a hook command didn't follow the skeleton's path pattern: {hook['command']}"
            # the documented form: one quoted literal path, which the Claude Directory's checks follow
            hook["command"] = f'"${{CLAUDE_PLUGIN_ROOT}}/hooks/{command.group(1)}"'
wired = json.dumps({"hooks": hooks}, indent=2)
with open(os.path.join(out, "hooks", "hooks.json"), "w", encoding="utf-8") as f:
    f.write(wired + "\n")

with open(listing, "w", encoding="utf-8") as f:
    f.write("\n".join(sorted(generated)) + "\n")
print(f"{out}: {len(skills)} skills, {len(agents)} agents, {len(workflows)} workflows, "
      f"{len([f for f in os.listdir(os.path.join(out, 'hooks')) if f.endswith('.sh')])} hook scripts")
PY
