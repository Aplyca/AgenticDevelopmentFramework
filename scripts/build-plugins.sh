#!/usr/bin/env bash
#
# Builds the framework's plugins and the module-plugin entries of the `aplyca` marketplace.
#
# plugins/aplyca-adf (docs/decisions/0016-packaged-install.md): its packaged half, from
# skeleton/.claude/ — the core skills, the agents as flat files, the workflows, and the hook scripts
# with their hooks.json — and, from skeleton/docs/, the framework's reference docs (decision 0019).
# It also carries the parallel-agents module's /dispatch (decision 0020), the one module skill that
# predates module plugins.
#
# plugins/adf-<module> (decision 0023): a module with a plugin.json beside its MODULE.md gets a plugin
# of its own, opt-in, built from the module's files/.claude/skills and files/.claude/agents, and
# listed in .claude-plugin/marketplace.json. The module stays the one source: a committed install
# copies those files, a packaged one turns the plugin on. Every plugin carries aplyca-adf's version.
#
# Claude Code puts everything a plugin carries under the plugin's name, so the copies name each other
# that way: `/triage` becomes `/aplyca-adf:triage`, `@code-reviewer` becomes
# `@aplyca-adf:code-reviewer`, and a module plugin's `/dev-env` becomes `/adf-docker:dev-env`. Names
# are unique across all of them. The hooks read the project's .claude/hooks/config.sh. The copies act
# only in a packaged project: each skill and agent opens with a step that hands over to the committed
# copy unless CLAUDE.md says "This project uses the packaged install" (visible text — Claude Code
# strips the HTML-comment stamp when it loads the file), and the hooks stand down unless the stamp on
# CLAUDE.md's first line says `install: packaged` (_lib.sh, which reads the file itself).
#
# aplyca-adf's installer skills (adopt, upgrade, cost-report), plugin.json, and README.md are written
# by hand and left alone, as are the marketplace's top-level fields and its aplyca-adf entry: the
# script rebuilds only the paths each plugin's .generated file lists. Never edit those paths. Change
# skeleton/ or the module and run this again; evals/static/check-skills.sh fails when a plugin and its
# source drift apart.
#
# Usage: scripts/build-plugins.sh [output root — default: this repository]
#   Writes <root>/plugins/<plugin>/ and <root>/.claude-plugin/marketplace.json; the sources are always
#   this repository's skeleton/ and modules/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_ROOT="${1:-$ROOT}"

python3 - "$ROOT" "$OUT_ROOT" <<'PY'
import json, os, re, shutil, sys

root, out_root = sys.argv[1], sys.argv[2]
src = os.path.join(root, "skeleton", ".claude")
CORE = "aplyca-adf"
# A module skill the core plugin carried before module plugins existed (decision 0020). Moving it to
# a plugin of its own renames what people type, so it waits for a major release (decision 0023).
GRANDFATHERED = {"parallel-agents"}
MANIFEST_KEYS = {"name", "description", "category", "keywords"}
REPO_URL = "https://github.com/aplyca/AgenticDevelopmentFramework"

skills = sorted(os.listdir(os.path.join(src, "skills")))
agents = sorted(os.listdir(os.path.join(src, "agents")))
workflows = sorted(f[:-3] for f in os.listdir(os.path.join(src, "workflows")) if f.endswith(".js"))

# Every plugin and what it carries: {plugin: {"skills": {name: folder}, "agents": {name: agent.md}}}.
plugins = {CORE: {"module": None, "skills": {n: os.path.join(src, "skills", n) for n in skills},
                  "agents": {n: os.path.join(src, "agents", n, "agent.md") for n in agents}}}
manifests = {}
for module in sorted(os.listdir(os.path.join(root, "modules"))):
    base = os.path.join(root, "modules", module)
    if not os.path.isdir(base):
        continue
    claude = os.path.join(base, "files", ".claude")
    for kind in ("workflows", "hooks"):
        assert not os.path.isdir(os.path.join(claude, kind)), \
            f"modules/{module} ships .claude/{kind}: a module plugin carries skills and agents only (decision 0023)"
    folder = os.path.join(claude, "skills")
    found = {n: os.path.join(folder, n) for n in sorted(os.listdir(folder))} if os.path.isdir(folder) else {}
    folder = os.path.join(claude, "agents")
    found_agents = {n: os.path.join(folder, n, "agent.md") for n in sorted(os.listdir(folder))} if os.path.isdir(folder) else {}
    manifest_path = os.path.join(base, "plugin.json")
    if os.path.exists(manifest_path):
        with open(manifest_path, encoding="utf-8") as f:
            manifest = json.load(f)
        unknown = set(manifest) - MANIFEST_KEYS
        assert not unknown, f"modules/{module}/plugin.json: unknown keys {sorted(unknown)} — the version comes from {CORE}"
        assert manifest.get("name") == f"adf-{module}", f"modules/{module}/plugin.json: the name must be adf-{module}"
        assert len(manifest.get("description", "")) >= 40, f"modules/{module}/plugin.json: needs a description"
        assert found or found_agents, f"modules/{module}/plugin.json: the module has no skills or agents to carry"
        plugins[manifest["name"]] = {"module": module, "skills": found, "agents": found_agents}
        manifests[manifest["name"]] = manifest
    elif found or found_agents:
        assert module in GRANDFATHERED and not found_agents, \
            f"modules/{module} ships skills or agents but has no plugin.json (decision 0023)"
        plugins[CORE]["skills"].update(found)  # names are checked below

# One owner per name, across every plugin: a bare name must reach one skill (decision 0016, finding 2),
# and a committed install puts every module's skills in one .claude/skills/.
owner, agent_owner = {}, {}


def claim(table, name, plugin, what):
    assert name not in table, f"two {what} are named {name}"
    table[name] = plugin


for name in workflows:
    claim(owner, name, CORE, "skills or workflows")
for plugin, carried in plugins.items():
    for name in carried["skills"]:
        claim(owner, name, plugin, "skills or workflows")
    for name in carried["agents"]:
        claim(agent_owner, name, plugin, "agents")

# A name counts only on its own: not inside a path (skills/review/SKILL.md), a URL, or a longer name.
command = re.compile(r"(?<![\w./@:-])/(" + "|".join(map(re.escape, sorted(owner))) + r")(?![\w-])")
agent = re.compile(r"(?<![\w./-])@(" + "|".join(map(re.escape, sorted(agent_owner))) + r")(?![\w-])")
module_command = re.compile(r"/adf-[a-z-]+:")


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
        assert not module_command.search(text), f"{source} names a module plugin's skill"
    elif kind:
        # ${CLAUDE_PLUGIN_ROOT} is this plugin's folder, and the reference docs are in aplyca-adf's.
        assert not reference.search(text), f"{source} names a reference doc a module plugin can't reach"
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


def source_note(plugin, kind):
    module = plugins[plugin]["module"]
    if module:
        return (f", from the `{module}` module's own plugin "
                f"([decision 0023]({REPO_URL}/blob/main/docs/decisions/0023-area-plugins-for-modules.md))")
    return f" ([decision 0016]({REPO_URL}/blob/main/docs/decisions/0016-packaged-install.md))" if kind == "skill" else ""


# A model reading a list of project paths takes one outside the project for another project path
# unless it's told: an agent read docs/SPEC-MODEL.md in the project instead of the plugin's copy.
DOCS_NOTE = ("> **The reference docs this file names are the plugin's copies,** in `${CLAUDE_PLUGIN_ROOT}/docs/` — "
             "outside this project, which keeps none in its own `docs/`. Read them at the full paths given.\n\n")


def hand_over(text, kind, name, plugin, docs=False):
    # After the frontmatter, so the name and description still come first.
    head, sep, body = text.partition("\n---\n")
    note = HANDOVER[kind].format(name=name, source=source_note(plugin, kind))
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
grandfathered = len(plugins[CORE]["skills"]) - len(skills)
print(f"{out}: {len(skills)} skills and {grandfathered} from modules, {len(agents)} agents, {len(workflows)} workflows, "
      f"{len([f for f in os.listdir(os.path.join(out, 'hooks')) if f.endswith('.sh')])} hook scripts")

# ─── Module plugins (decision 0023) ───────────────────────────────────────────

with open(os.path.join(out_root, "plugins", CORE, ".claude-plugin", "plugin.json"), encoding="utf-8") as f:
    core_manifest = json.load(f)
for plugin, manifest in sorted(manifests.items()):
    module = plugins[plugin]["module"]
    out = os.path.join(out_root, "plugins", plugin)
    listing = clean(out)
    generated = copy_skills_and_agents(plugin, out)
    if plugins[plugin]["agents"]:
        generated.append("agents")
    data = {"name": plugin, "description": manifest["description"], "version": core_manifest["version"],
            "author": core_manifest["author"], "homepage": core_manifest["homepage"]}
    if manifest.get("keywords"):
        data["keywords"] = manifest["keywords"]
    os.makedirs(os.path.join(out, ".claude-plugin"), exist_ok=True)
    with open(os.path.join(out, ".claude-plugin", "plugin.json"), "w", encoding="utf-8") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    carried = [f"`/{plugin}:{n}`" for n in plugins[plugin]["skills"]] + [f"`@{plugin}:{n}`" for n in plugins[plugin]["agents"]]
    readme = (
        f"# {plugin}\n\n"
        f"The `{module}` module's machinery for a packaged install of the "
        f"[Agentic Development Framework]({REPO_URL}): {', '.join(carried)}.\n\n"
        f"{manifest['description']}\n\n"
        f"**Generated** from [`modules/{module}/`]({REPO_URL}/tree/main/modules/{module}) by "
        f"`scripts/build-plugins.sh` ([decision 0023]({REPO_URL}/blob/main/docs/decisions/0023-area-plugins-for-modules.md)); "
        f"never edit it here.\n\n"
        f"It is listed in the `aplyca` marketplace beside `aplyca-adf`, at the same version. "
        f"`/aplyca-adf:adopt` and `/aplyca-adf:upgrade` turn it on in a packaged project that installs the "
        f"`{module}` module; a committed project copies the module's files instead and leaves it off. "
        f"Anywhere else its skills say so and stop. What the module adds, and how to install and customize "
        f"it: [`MODULE.md`]({REPO_URL}/blob/main/modules/{module}/MODULE.md).\n"
    )
    with open(os.path.join(out, "README.md"), "w", encoding="utf-8") as f:
        f.write(readme)
    generated += [".claude-plugin/plugin.json", "README.md"]
    with open(listing, "w", encoding="utf-8") as f:
        f.write("\n".join(sorted(generated)) + "\n")
    print(f"{out}: {len(plugins[plugin]['skills'])} skills, {len(plugins[plugin]['agents'])} agents, from modules/{module}")

# A module plugin whose module no longer has a manifest: remove what the build made. A folder the
# build never made is someone's work — stop rather than delete it.
for folder in sorted(os.listdir(os.path.join(out_root, "plugins"))):
    out = os.path.join(out_root, "plugins", folder)
    if folder in plugins or not os.path.isdir(out):
        continue
    assert os.path.exists(os.path.join(out, ".generated")), \
        f"plugins/{folder} isn't a plugin this script builds: give its module a plugin.json, or remove it"
    os.remove(clean(out))
    for directory, _, _ in sorted(os.walk(out), reverse=True):
        if not os.listdir(directory):
            os.rmdir(directory)
    if os.path.isdir(out):
        sys.exit(f"plugins/{folder}: removed what the build made, but other files are left there")
    print(f"{out}: removed — modules/{folder[4:]} no longer has a plugin.json")

# ─── The marketplace ──────────────────────────────────────────────────────────

path = os.path.join(out_root, ".claude-plugin", "marketplace.json")
with open(path, encoding="utf-8") as f:
    market = json.load(f)
core_entries = [p for p in market["plugins"] if p["name"] == CORE]
assert len(core_entries) == 1, f"marketplace.json must list {CORE} once"
strays = [p["name"] for p in market["plugins"] if p["name"] != CORE and not p["name"].startswith("adf-")]
assert not strays, f"marketplace.json lists plugins no module generates: {strays}"
entries = [{"name": plugin, "description": manifests[plugin]["description"], "author": core_entries[0]["author"],
            "category": manifests[plugin].get("category", "development"), "source": f"./plugins/{plugin}"}
           for plugin in sorted(manifests)]
market["plugins"] = core_entries + entries
with open(path, "w", encoding="utf-8") as f:
    f.write(json.dumps(market, indent=2, ensure_ascii=False) + "\n")
PY
