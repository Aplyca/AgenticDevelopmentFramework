"""The framework's machinery in its two forms (decision 0028).

The plugins in plugins/ are the source. Each skill, agent, workflow, and hook is written the way a
packaged project loads it: `/adf:triage`, `@adf:code-reviewer`, `${CLAUDE_PLUGIN_ROOT}/docs/SPEC-MODEL.md`,
`adf-worktree-new`, and a Step 0 that hands over to a committed copy. scripts/build-committed.py turns
each file into the form a committed project keeps — `/triage`, `@code-reviewer`, `docs/SPEC-MODEL.md`,
`scripts/agent/worktree-new.sh`, no Step 0 — and to_plugin() is the way back. The static checks require
every file to survive the round trip unchanged, so the two forms can't drift apart.

A committed install carries every skill and agent that opens with a Step 0 (adf's installer skills and
adf-connect's /connect run only from their plugin, and have none), adf's workflows, hook scripts, and
reference docs, and the skills of the modules a project installs, which each module's module.json names.
"""
import json
import os
import re

CORE = "adf"
REPO_URL = "https://github.com/aplyca/AgenticDevelopmentFramework"
REFERENCE_DOCS = ["COST-MODEL", "MCP-INTEGRATION", "MEMORY-STRATEGY", "SPEC-MODEL"]

HANDOVER = {
    "skill": "> **Step 0 — which copy.** This is the packaged copy{source}. "
             "Unless this project's instructions say \"This project uses the packaged install\", stop here: open "
             "`.claude/skills/{name}/SKILL.md` and follow that file instead — it's the version this project "
             "upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.\n\n",
    "agent": "> **Step 0 — which copy.** This is the packaged copy{source}. Unless this project's instructions say "
             "\"This project uses the packaged install\", open `.claude/agents/{name}/agent.md` and follow that file "
             "instead of this one.\n\n",
}
STEP0 = re.compile(r"\A(.*?\n---\n)\n> \*\*Step 0 — which copy\.\*\* [^\n]*\n\n", re.S)
# A model reading a list of project paths takes one outside the project for another project path
# unless it's told: an agent read docs/SPEC-MODEL.md in the project instead of the plugin's copy.
DOCS_NOTE = ("> **The reference docs this file names are the plugin's copies,** in `${CLAUDE_PLUGIN_ROOT}/docs/` — "
             "outside this project, which keeps none in its own `docs/`. Read them at the full paths given.\n\n")
DOCS_NOTE_AT_TOP = re.compile(r"\A(.*?\n---\n\n)" + re.escape(DOCS_NOTE), re.S)
LOCAL_DOC = re.compile(r"(?<![\w/.-])docs/(" + "|".join(REFERENCE_DOCS) + r")\.md")
PLUGIN_DOC = re.compile(r"\$\{CLAUDE_PLUGIN_ROOT\}/docs/(" + "|".join(REFERENCE_DOCS) + r")\.md")

# Claude Code doesn't fill in ${CLAUDE_PLUGIN_ROOT} in a workflow script, so a workflow that needs the
# spec model carries its text; a committed workflow reads the project's copy instead.
SPEC_MODEL_LINE = "const SPEC_MODEL = 'Read docs/SPEC-MODEL.md.'"
SPEC_MODEL_TEXT = re.compile(r'^const SPEC_MODEL = ".*"$', re.M)
SPEC_MODEL_INTRO = "The spec model (SPEC-MODEL.md), which these checks follow:\n\n"

# The Claude Directory refuses a path the shell computes for a file a hook loads or runs: the plugin's
# hooks name _lib.sh, the hooks folder, and the helpers in it literally; a committed hook finds them
# beside itself.
HOOK_FORMS = [  # (committed, plugin)
    ('HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"', 'HOOKS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks"'),
    ('. "$(dirname "$0")/_lib.sh"', 'source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"'),
    ('"$HOOKS_DIR/', '"${CLAUDE_PLUGIN_ROOT}/hooks/'),
    ('"$HOOKS_DIR"', '"${CLAUDE_PLUGIN_ROOT}/hooks"'),
]
SETTINGS_HOOK = re.compile(r'"\$CLAUDE_PROJECT_DIR"/\.claude/hooks/([a-z-]+\.sh)')
PLUGIN_HOOK = re.compile(r'"\$\{CLAUDE_PLUGIN_ROOT\}/hooks/([a-z-]+\.sh)"')


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


class Machinery:
    """What the plugins carry into a committed install, and the names each form gives it."""

    def __init__(self, root, modules_root=None):
        self.root = root
        self.modules_root = modules_root or root
        self.plugins_dir = os.path.join(root, "plugins")
        self.plugins = sorted(d for d in os.listdir(self.plugins_dir)
                              if os.path.isfile(os.path.join(self.plugins_dir, d, ".claude-plugin", "plugin.json")))
        assert CORE in self.plugins, "plugins/adf is missing"
        self._modules()
        self._carried()
        names = {**self.skills, **{name: CORE for name in self.workflows}}
        alternation = lambda words: "|".join(map(re.escape, sorted(words, key=len, reverse=True)))
        plugins = alternation(self.plugins)
        # A name counts only on its own: not inside a path (skills/review/SKILL.md), a URL, or a longer
        # name. A script counts on its own too: not the end of a longer path ("$root/scripts/agent/…",
        # which a hook tests for).
        self.bare_skill = re.compile(r"(?<![\w./@:-])/(" + alternation(names) + r")(?![\w-])")
        self.plugin_skill = re.compile(r"(?<![\w./@:-])/(" + plugins + r"):(" + alternation(names) + r")(?![\w-])")
        self.bare_agent = re.compile(r"(?<![\w./-])@(" + alternation(self.agents) + r")(?![\w-])")
        self.plugin_agent = re.compile(r"(?<![\w./-])@(" + plugins + r"):(" + alternation(self.agents) + r")(?![\w-])")
        self.script = re.compile(r"(?<![\w./$-])(" + alternation(self.script_of) + r")(?![\w-])") if self.script_of else None
        self.command = re.compile(r"(?<![\w./$-])(" + alternation(self.command_script) + r")(?![\w-])") if self.command_script else None
        self.names = names

    def _modules(self):
        """Each module's module.json: the plugin that carries its skills and commands (decisions 0023, 0027)."""
        self.module_plugin, self.module_skills, self.module_of = {}, {}, {}
        self.command_script, self.script_of, self.command_module = {}, {}, {}
        modules = os.path.join(self.modules_root, "modules")
        for module in sorted(os.listdir(modules)):
            manifest = os.path.join(modules, module, "module.json")
            if not os.path.isfile(manifest):
                continue
            data = json.loads(read(manifest))
            assert "plugin" in data and set(data) <= {"plugin", "skills", "commands"}, \
                f"modules/{module}/module.json takes plugin and, optionally, skills and commands"
            plugin = data["plugin"]
            assert plugin in self.plugins, f"modules/{module}/module.json names {plugin}, which isn't in plugins/"
            assert data.get("skills") or data.get("commands"), \
                f"modules/{module}/module.json names a plugin, but no skills or commands for it"
            self.module_plugin[module] = plugin
            self.module_skills[module] = list(data.get("skills", []))
            for name in self.module_skills[module]:
                assert os.path.isfile(os.path.join(self.plugins_dir, plugin, "skills", name, "SKILL.md")), \
                    f"modules/{module}/module.json names the skill {name}, which plugins/{plugin} doesn't carry"
                assert name not in self.module_of, f"two modules name the skill {name}"
                self.module_of[name] = module
            # A command's name starts with its plugin's, so it can't take the name of a command on the
            # developer's PATH by accident (it comes last there, decision 0027).
            for name, rel in data.get("commands", {}).items():
                assert re.fullmatch(re.escape(plugin) + r"-[a-z0-9-]+", name), \
                    f"modules/{module}/module.json: command {name} must be named {plugin}-<name>"
                assert rel.endswith(".sh") and os.path.isfile(os.path.join(modules, module, "files", rel)), \
                    f"modules/{module}/module.json: {rel} isn't a script in files/"
                assert name not in self.command_script, f"two commands are named {name}"
                self.command_script[name] = rel
                self.command_module[name] = module
                # Docs name a script by its path or by its file name alone (worktree-new.sh).
                for mention in (rel, os.path.basename(rel)):
                    assert mention not in self.script_of, f"two commands come from scripts named {mention}"
                    self.script_of[mention] = name

    def _carried(self):
        """Every skill and agent with a Step 0, in any plugin; adf's workflows, hooks, and docs."""
        self.skills, self.agents = {}, {}
        for plugin in self.plugins:
            folder = os.path.join(self.plugins_dir, plugin, "skills")
            for name in sorted(os.listdir(folder)) if os.path.isdir(folder) else []:
                if STEP0.match(read(os.path.join(folder, name, "SKILL.md"))):
                    assert name not in self.skills, f"two plugins carry a skill named {name}"
                    assert plugin == CORE or name in self.module_of, \
                        f"plugins/{plugin}/skills/{name} has a Step 0 but no module names it (module.json)"
                    self.skills[name] = plugin
            folder = os.path.join(self.plugins_dir, plugin, "agents")
            for entry in sorted(os.listdir(folder)) if os.path.isdir(folder) else []:
                assert plugin == CORE, f"plugins/{plugin}/agents: only adf carries agents"
                assert entry.endswith(".md"), f"plugins/{plugin}/agents/{entry}: an agent is one .md file"
                self.agents[entry[:-3]] = plugin
        self.workflows = sorted(f[:-3] for f in os.listdir(self.path("workflows")) if f.endswith(".js"))
        self.hooks = sorted(f for f in os.listdir(self.path("hooks")) if f != "hooks.json")
        for name in self.module_of:
            assert name in self.skills, f"{name} comes from a module but has no Step 0"

    def path(self, *parts):
        return os.path.join(self.plugins_dir, CORE, *parts)

    # ─── The names ─────────────────────────────────────────────────────────

    def to_plugin_names(self, text):
        text = self.bare_skill.sub(lambda m: f"/{self.names[m.group(1)]}:{m.group(1)}", text)
        if self.script:
            text = self.script.sub(lambda m: self.script_of[m.group(1)], text)
        return self.bare_agent.sub(lambda m: f"@{self.agents[m.group(1)]}:{m.group(1)}", text)

    def to_committed_names(self, text):
        def skill(m):
            plugin, name = m.groups()
            return f"/{name}" if self.names[name] == plugin else m.group(0)

        def agent(m):
            plugin, name = m.groups()
            return f"@{name}" if self.agents[name] == plugin else m.group(0)

        text = self.plugin_skill.sub(skill, text)
        if self.command:
            text = self.command.sub(lambda m: self.command_script[m.group(1)], text)
        return self.plugin_agent.sub(agent, text)

    # ─── Skills and agents ─────────────────────────────────────────────────

    def source_note(self, plugin, kind, name):
        if plugin != CORE:
            decision = f"[decision 0023]({REPO_URL}/blob/main/docs/decisions/0023-plugins-by-concern.md)"
            return f", from the `{self.module_of[name]}` module, carried by `{plugin}` ({decision})"
        decision = f"[decision 0016]({REPO_URL}/blob/main/docs/decisions/0016-packaged-install.md)"
        return f" ({decision})" if kind == "skill" else ""

    def to_plugin_markdown(self, text, kind, name, plugin):
        """A committed SKILL.md or agent.md, as the plugin carries it."""
        text = self.to_plugin_names(text)
        if plugin != CORE:
            # ${CLAUDE_PLUGIN_ROOT} is this plugin's folder, and the reference docs are in adf's.
            assert not LOCAL_DOC.search(text), f"{plugin}:{name} names a reference doc only adf can reach"
        named = LOCAL_DOC.sub(r"${CLAUDE_PLUGIN_ROOT}/docs/\1.md", text)
        # After the frontmatter, so the name and description still come first.
        head, sep, body = named.partition("\n---\n")
        note = HANDOVER[kind].format(name=name, source=self.source_note(plugin, kind, name))
        return head + sep + "\n" + note + (DOCS_NOTE if named != text else "") + body.lstrip("\n")

    def to_committed_markdown(self, text):
        text = STEP0.sub(lambda m: m.group(1) + "\n", text, count=1)
        text = DOCS_NOTE_AT_TOP.sub(lambda m: m.group(1), text, count=1)
        return self.to_committed_names(PLUGIN_DOC.sub(r"docs/\1.md", text))

    # ─── Workflows and hooks ───────────────────────────────────────────────

    def spec_model(self):
        return "const SPEC_MODEL = " + json.dumps(SPEC_MODEL_INTRO + read(self.path("docs", "SPEC-MODEL.md")), ensure_ascii=False)

    def to_plugin_workflow(self, text):
        text = self.to_plugin_names(text)
        assert text.count(SPEC_MODEL_LINE) <= 1, "a workflow names the spec model more than once"
        text = text.replace(SPEC_MODEL_LINE, self.spec_model())
        assert not LOCAL_DOC.search(text), "a workflow names a reference doc, which the plugin can't reach from a script"
        return text

    def to_committed_workflow(self, text):
        return self.to_committed_names(SPEC_MODEL_TEXT.sub(lambda m: SPEC_MODEL_LINE, text))

    def to_plugin_hook(self, text, name):
        text = self.to_plugin_names(text)
        if name.endswith(".sh"):
            for committed, plugin in HOOK_FORMS:
                text = text.replace(committed, plugin)
        return text

    def to_committed_hook(self, text, name):
        if name.endswith(".sh"):
            for committed, plugin in HOOK_FORMS:
                text = text.replace(plugin, committed)
        return self.to_committed_names(text)

    # ─── The committed install ─────────────────────────────────────────────

    def committed_files(self, modules=()):
        """{path in a committed project: (text, executable)}: the core, and the given modules' skills."""
        files = {}
        skills = [n for n, p in self.skills.items() if p == CORE and n not in self.module_of]
        skills += [n for m in modules for n in self.module_skills.get(m, [])]
        for name in sorted(skills):
            folder = os.path.join(self.plugins_dir, self.skills[name], "skills", name)
            for directory, _, entries in os.walk(folder):
                for entry in entries:
                    source = os.path.join(directory, entry)
                    text = read(source)
                    text = self.to_committed_markdown(text) if entry == "SKILL.md" else self.to_committed_names(text)
                    files[os.path.join(".claude", "skills", name, os.path.relpath(source, folder))] = (text, os.access(source, os.X_OK))
        for name in sorted(self.agents):
            files[os.path.join(".claude", "agents", name, "agent.md")] = (self.to_committed_markdown(read(self.path("agents", name + ".md"))), False)
        for name in self.workflows:
            files[os.path.join(".claude", "workflows", name + ".js")] = (self.to_committed_workflow(read(self.path("workflows", name + ".js"))), False)
        for name in self.hooks:
            # A committed hook runs from settings.json; _lib.sh and the helpers are loaded, never run.
            executable = name.endswith(".sh") and not name.startswith("_")
            files[os.path.join(".claude", "hooks", name)] = (self.to_committed_hook(read(self.path("hooks", name)), name), executable)
        for name in REFERENCE_DOCS:
            files[os.path.join("docs", name + ".md")] = (self.to_committed_names(read(self.path("docs", name + ".md"))), False)
        return files

    def settings_hooks(self):
        """adf's hooks.json, as a committed project's .claude/settings.json wires the same hooks."""
        hooks = json.loads(read(self.path("hooks", "hooks.json")))["hooks"]
        for groups in hooks.values():
            for group in groups:
                for hook in group["hooks"]:
                    wired = PLUGIN_HOOK.fullmatch(hook["command"])
                    assert wired, f"hooks.json: {hook['command']} isn't one quoted literal path to a hook"
                    hook["command"] = f'"$CLAUDE_PROJECT_DIR"/.claude/hooks/{wired.group(1)}'
        return hooks

    def round_trip(self):
        """Every carried file that doesn't come back unchanged from the committed form: [(path, why)]."""
        problems = []
        committed = self.committed_files(modules=list(self.module_skills))
        for name, plugin in sorted(self.skills.items()):
            folder = os.path.join(self.plugins_dir, plugin, "skills", name)
            for directory, _, entries in os.walk(folder):
                for entry in entries:
                    source = os.path.join(directory, entry)
                    text = committed[os.path.join(".claude", "skills", name, os.path.relpath(source, folder))][0]
                    back = self.to_plugin_markdown(text, "skill", name, plugin) if entry == "SKILL.md" else self.to_plugin_names(text)
                    if back != read(source):
                        problems.append((os.path.relpath(source, self.root), back))
                    if plugin == CORE and entry == "SKILL.md":
                        for other in self.plugins:
                            if other != CORE and re.search(rf"/{re.escape(other)}:", read(source)):
                                problems.append((os.path.relpath(source, self.root), f"names a skill of {other}, which a project may not have on"))
        checks = [(self.path("agents", n + ".md"), os.path.join(".claude", "agents", n, "agent.md"),
                   lambda t, n=n: self.to_plugin_markdown(t, "agent", n, CORE)) for n in self.agents]
        checks += [(self.path("workflows", n + ".js"), os.path.join(".claude", "workflows", n + ".js"), self.to_plugin_workflow) for n in self.workflows]
        checks += [(self.path("hooks", n), os.path.join(".claude", "hooks", n), lambda t, n=n: self.to_plugin_hook(t, n)) for n in self.hooks]
        checks += [(self.path("docs", n + ".md"), os.path.join("docs", n + ".md"), self.to_plugin_names) for n in REFERENCE_DOCS]
        for source, rel, forward in checks:
            back = forward(committed[rel][0])
            if back != read(source):
                problems.append((os.path.relpath(source, self.root), back))
        return problems
