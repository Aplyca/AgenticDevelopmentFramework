#!/usr/bin/env bash
#
# Builds the generated half of the framework's plugins, one per concern (decision 0023):
#
# - plugins/aplyca-adf, the process (docs/decisions/0016-packaged-install.md): from skeleton/.claude/,
#   the core skills, the agents as flat files, the workflows, and the hook scripts with their
#   hooks.json; from skeleton/docs/, the framework's reference docs (decision 0019).
# - plugins/adf-dev, development, and every other plugin whose manifest is in plugins/: the skills and
#   agents of the modules that name it.
#
# A module names the plugin that carries its skills and agents in modules/<module>/module.json —
# parallel-agents' /dispatch goes to aplyca-adf, docker's /dev-env to adf-dev. The module stays the one
# source: a committed install copies those files, a packaged one turns the plugin on. Every plugin
# carries aplyca-adf's version, which this script copies into the others' manifests.
#
# Claude Code puts everything a plugin carries under the plugin's name, so the copies name each other
# that way: `/triage` becomes `/aplyca-adf:triage`, `@code-reviewer` becomes
# `@aplyca-adf:code-reviewer`, and `/dev-env` becomes `/adf-dev:dev-env`. Names are unique across every
# plugin. The hooks read the project's .claude/hooks/config.sh. The copies act only in a packaged
# project: each skill and agent opens with a step that hands over to the committed copy unless
# CLAUDE.md says "This project uses the packaged install" (visible text — Claude Code strips the
# HTML-comment stamp when it loads the file), and the hooks stand down unless the stamp on CLAUDE.md's
# first line says `install: packaged` (_lib.sh, which reads the file itself).
#
# Each plugin's manifest and README, aplyca-adf's installer skills (adopt, upgrade, cost-report), and
# the marketplace are written by hand and left alone, apart from the version this script keeps equal:
# it rebuilds only the paths each plugin's .generated file lists. Never edit those paths. Change
# skeleton/ or the module and run this again; evals/static/check-skills.sh fails when a plugin and its
# source drift apart.
#
# Usage: scripts/build-plugins.sh [output root — default: this repository]
#   Writes <root>/plugins/<plugin>/; the sources are always this repository's skeleton/ and modules/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_ROOT="${1:-$ROOT}"

python3 - "$ROOT" "$OUT_ROOT" <<'PY'
import json, os, re, shutil, sys

root, out_root = sys.argv[1], sys.argv[2]
src = os.path.join(root, "skeleton", ".claude")
CORE = "aplyca-adf"
REPO_URL = "https://github.com/aplyca/AgenticDevelopmentFramework"
DECISION = f"[decision 0023]({REPO_URL}/blob/main/docs/decisions/0023-plugins-by-concern.md)"

skills = sorted(os.listdir(os.path.join(src, "skills")))
agents = sorted(os.listdir(os.path.join(src, "agents")))
workflows = sorted(f[:-3] for f in os.listdir(os.path.join(src, "workflows")) if f.endswith(".js"))

# Every plugin and what it carries: {plugin: {"skills": {name: folder}, "agents": {name: agent.md}}}.
# A plugin is a folder in plugins/ with a hand-written manifest; aplyca-adf also takes the skeleton's.
plugin_dirs = sorted(d for d in os.listdir(os.path.join(out_root, "plugins")) if os.path.isdir(os.path.join(out_root, "plugins", d)))
for folder in plugin_dirs:
    assert os.path.exists(os.path.join(out_root, "plugins", folder, ".claude-plugin", "plugin.json")), \
        f"plugins/{folder} has no .claude-plugin/plugin.json"
plugins = {name: {"skills": {}, "agents": {}} for name in plugin_dirs}
assert CORE in plugins, f"plugins/{CORE} is missing"
plugins[CORE]["skills"] = {n: os.path.join(src, "skills", n) for n in skills}
plugins[CORE]["agents"] = {n: os.path.join(src, "agents", n, "agent.md") for n in agents}
module_of = {}  # a module's skill or agent name -> its module
carried = []    # (plugin, kind, name, path) in the order the modules list them
for module in sorted(os.listdir(os.path.join(root, "modules"))):
    base = os.path.join(root, "modules", module)
    if not os.path.isdir(base):
        continue
    claude = os.path.join(base, "files", ".claude")
    for kind in ("workflows", "hooks"):
        assert not os.path.isdir(os.path.join(claude, kind)), \
            f"modules/{module} ships .claude/{kind}: a module's plugin carries its skills and agents only (decision 0023)"
    folder = os.path.join(claude, "skills")
    found = [("skills", n, os.path.join(folder, n)) for n in sorted(os.listdir(folder))] if os.path.isdir(folder) else []
    folder = os.path.join(claude, "agents")
    found += [("agents", n, os.path.join(folder, n, "agent.md")) for n in sorted(os.listdir(folder))] if os.path.isdir(folder) else []
    manifest = os.path.join(base, "module.json")
    if not os.path.exists(manifest):
        assert not found, f"modules/{module} ships skills or agents but no module.json names the plugin that carries them (decision 0023)"
        continue
    with open(manifest, encoding="utf-8") as f:
        data = json.load(f)
    assert set(data) == {"plugin"}, f"modules/{module}/module.json takes one key, plugin"
    assert data["plugin"] in plugins, f"modules/{module}/module.json names {data['plugin']}, which isn't in plugins/"
    assert found, f"modules/{module}/module.json names a plugin, but the module has no skills or agents for it"
    for kind, name, path in found:
        carried.append((data["plugin"], kind, name, path))
        module_of[name] = module

# One owner per name, across every plugin: a bare name must reach one skill (decision 0016, finding 2),
# and a committed install puts every module's skills in one .claude/skills/.
owner, agent_owner = {}, {}


def claim(table, name, plugin, what):
    assert name not in table, f"two {what} are named {name}"
    table[name] = plugin


for name in workflows:
    claim(owner, name, CORE, "skills or workflows")
for name in skills:
    claim(owner, name, CORE, "skills or workflows")
for name in agents:
    claim(agent_owner, name, CORE, "agents")
for plugin, kind, name, path in carried:
    claim(owner if kind == "skills" else agent_owner, name, plugin, "skills or workflows" if kind == "skills" else "agents")
    plugins[plugin][kind][name] = path

# A name counts only on its own: not inside a path (skills/review/SKILL.md), a URL, or a longer name.
command = re.compile(r"(?<![\w./@:-])/(" + "|".join(map(re.escape, sorted(owner))) + r")(?![\w-])")
agent = re.compile(r"(?<![\w./-])@(" + "|".join(map(re.escape, sorted(agent_owner))) + r")(?![\w-])")
others = [p for p in plugins if p != CORE]
other_command = re.compile(r"/(" + "|".join(map(re.escape, others)) + r"):") if others else None


# The framework's reference docs (decision 0019): generic, never edited by a project, so a packaged
# project reads them from the plugin. Its skills and agents name the plugin's copy; Claude Code fills in
# ${CLAUDE_PLUGIN_ROOT} when it loads them.
REFERENCE_DOCS = ["COST-MODEL", "MCP-INTEGRATION", "MEMORY-STRATEGY", "SPEC-MODEL"]
reference = re.compile(r"(?<![\w/.-])docs/(" + "|".join(REFERENCE_DOCS) + r")\.md")


def rename(text):
    text = command.sub(lambda m: f"/{owner[m.group(1)]}:{m.group(1)}", text)
    return agent.sub(lambda m: f"@{agent_owner[m.group(1)]}:{m.group(1)}", text)


def copy(plugin, source, target, executable=False, kind=None, name=None):
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(source, encoding="utf-8") as f:
        text = rename(f.read())
    if plugin == CORE:
        # The core can't depend on a plugin a project may not have turned on.
        assert not (other_command and other_command.search(text)), f"{source} names a skill another plugin carries"
    elif kind:
        # ${CLAUDE_PLUGIN_ROOT} is this plugin's folder, and the reference docs are in aplyca-adf's.
        assert not reference.search(text), f"{source} names a reference doc only aplyca-adf can reach"
    if kind:
        named = reference.sub(r"${CLAUDE_PLUGIN_ROOT}/docs/\1.md", text)
        text = hand_over(named, kind, name, plugin, docs=named != text)
    with open(target, "w", encoding="utf-8") as f:
        f.write(text)
    os.chmod(target, 0o755 if executable else 0o644)


HANDOVER = {
    "skill": "> **Step 0 — which copy.** This is the packaged copy{source}. "
             "Unless this project's `CLAUDE.md` says \"This project uses the packaged install\", stop here: open "
             "`.claude/skills/{name}/SKILL.md` and follow that file instead — it's the version this project "
             "upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.\n\n",
    "agent": "> **Step 0 — which copy.** This is the packaged copy{source}. Unless this project's `CLAUDE.md` says "
             "\"This project uses the packaged install\", open `.claude/agents/{name}/agent.md` and follow that file "
             "instead of this one.\n\n",
}


def source_note(plugin, kind, name):
    if plugin != CORE:
        return f", from the `{module_of[name]}` module, carried by `{plugin}` ({DECISION})"
    return f" ([decision 0016]({REPO_URL}/blob/main/docs/decisions/0016-packaged-install.md))" if kind == "skill" else ""


# A model reading a list of project paths takes one outside the project for another project path
# unless it's told: an agent read docs/SPEC-MODEL.md in the project instead of the plugin's copy.
DOCS_NOTE = ("> **The reference docs this file names are the plugin's copies,** in `${CLAUDE_PLUGIN_ROOT}/docs/` — "
             "outside this project, which keeps none in its own `docs/`. Read them at the full paths given.\n\n")


def hand_over(text, kind, name, plugin, docs=False):
    # After the frontmatter, so the name and description still come first.
    head, sep, body = text.partition("\n---\n")
    note = HANDOVER[kind].format(name=name, source=source_note(plugin, kind, name))
    return head + sep + "\n" + note + (DOCS_NOTE if docs else "") + body.lstrip("\n")


def clean(out):
    # Remove what the last build generated, so a skill dropped from the source leaves the plugin too.
    listing = os.path.join(out, ".generated")
    if os.path.exists(listing):
        for rel in open(listing, encoding="utf-8").read().split():
            path = os.path.join(out, rel)
            if os.path.isdir(path):
                shutil.rmtree(path)
            elif os.path.exists(path):
                os.remove(path)
    return listing


def copy_skills_and_agents(plugin, out):
    generated = []
    for name, folder in sorted(plugins[plugin]["skills"].items()):
        for directory, _, files in os.walk(folder):
            for file in files:
                path = os.path.join(directory, file)
                copy(plugin, path, os.path.join(out, "skills", name, os.path.relpath(path, folder)),
                     kind="skill" if file == "SKILL.md" else None, name=name)
        generated.append(f"skills/{name}")
    for name, path in sorted(plugins[plugin]["agents"].items()):
        copy(plugin, path, os.path.join(out, "agents", name + ".md"), kind="agent", name=name)
    return generated


# ─── aplyca-adf ───────────────────────────────────────────────────────────────

out = os.path.join(out_root, "plugins", CORE)
listing = clean(out)
generated = copy_skills_and_agents(CORE, out)
for name in REFERENCE_DOCS:
    copy(CORE, os.path.join(root, "skeleton", "docs", name + ".md"), os.path.join(out, "docs", name + ".md"))
# Claude Code doesn't fill in ${CLAUDE_PLUGIN_ROOT} in a workflow script, so a workflow that needs the
# spec model gets its text: the skeleton's one-line constant becomes the plugin's copy of the doc.
SPEC_MODEL_LINE = "const SPEC_MODEL = 'Read docs/SPEC-MODEL.md.'"
for name in workflows:
    target = os.path.join(out, "workflows", name + ".js")
    copy(CORE, os.path.join(src, "workflows", name + ".js"), target)
    with open(target, encoding="utf-8") as f:
        text = f.read()
    if SPEC_MODEL_LINE in text:
        assert text.count(SPEC_MODEL_LINE) == 1, f"{name}.js names the spec model more than once"
        with open(os.path.join(out, "docs", "SPEC-MODEL.md"), encoding="utf-8") as f:
            model = "The spec model (SPEC-MODEL.md), which these checks follow:\n\n" + f.read()
        text = text.replace(SPEC_MODEL_LINE, "const SPEC_MODEL = " + json.dumps(model, ensure_ascii=False))
        with open(target, "w", encoding="utf-8") as f:
            f.write(text)
    assert not reference.search(text), f"{name}.js names a reference doc the plugin can't reach from a workflow"
LIB_SOURCE = '. "$(dirname "$0")/_lib.sh"'
HOOKS_DIR_LINE = 'HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
for file in sorted(os.listdir(os.path.join(src, "hooks"))):
    if file == "config.sh":
        continue  # the project's settings stay in the project
    target = os.path.join(out, "hooks", file)
    copy(CORE, os.path.join(src, "hooks", file), target, executable=file.endswith(".sh"))
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
generated += ["agents", "docs", "workflows", "hooks"]

with open(os.path.join(src, "settings.json"), encoding="utf-8") as f:
    hooks = json.load(f)["hooks"]
for groups in hooks.values():
    for group in groups:
        for hook in group["hooks"]:
            wired = re.fullmatch(r'"\$CLAUDE_PROJECT_DIR"/\.claude/hooks/([a-z-]+\.sh)', hook["command"])
            assert wired, f"a hook command didn't follow the skeleton's path pattern: {hook['command']}"
            # the documented form: one quoted literal path, which the Claude Directory's checks follow
            hook["command"] = f'"${{CLAUDE_PLUGIN_ROOT}}/hooks/{wired.group(1)}"'
with open(os.path.join(out, "hooks", "hooks.json"), "w", encoding="utf-8") as f:
    f.write(json.dumps({"hooks": hooks}, indent=2) + "\n")

with open(listing, "w", encoding="utf-8") as f:
    f.write("\n".join(sorted(generated)) + "\n")
from_modules = len(plugins[CORE]["skills"]) - len(skills)
print(f"{out}: {len(skills)} skills and {from_modules} from modules, {len(agents)} agents, {len(workflows)} workflows, "
      f"{len([f for f in os.listdir(os.path.join(out, 'hooks')) if f.endswith('.sh')])} hook scripts")

# ─── The other plugins (decision 0023) ────────────────────────────────────────

with open(os.path.join(out_root, "plugins", CORE, ".claude-plugin", "plugin.json"), encoding="utf-8") as f:
    version = json.load(f)["version"]
for plugin in others:
    out = os.path.join(out_root, "plugins", plugin)
    listing = clean(out)
    generated = copy_skills_and_agents(plugin, out)
    if plugins[plugin]["agents"]:
        generated.append("agents")
    with open(listing, "w", encoding="utf-8") as f:
        f.write("".join(f"{rel}\n" for rel in sorted(generated)))
    # One release, one version: aplyca-adf's, which a release sets by hand.
    path = os.path.join(out, ".claude-plugin", "plugin.json")
    with open(path, encoding="utf-8") as f:
        manifest = json.load(f)
    assert manifest.get("name") == plugin, f"plugins/{plugin}/.claude-plugin/plugin.json: the name must be {plugin}"
    manifest["version"] = version
    with open(path, "w", encoding="utf-8") as f:
        f.write(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print(f"{out}: {len(plugins[plugin]['skills'])} skills and {len(plugins[plugin]['agents'])} agents from modules")
PY
