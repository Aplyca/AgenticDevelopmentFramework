#!/usr/bin/env python3
"""Upgrade an adopted project to this script's own release (decision 0046).

The deterministic part of /adf:upgrade: it reads the project's stamp, builds the old and new copies of
every file the framework gave the project, applies what merges cleanly, leaves conflicts marked, runs
the releases' migrations and the modules' installers, moves the pin, restamps, and writes a report of
what it did and what needs a person. The judgment stays with /adf:upgrade and the developer.

It upgrades to the release of the tree it runs from. The plugin's `adf-upgrade` command fetches that
tree and runs this script from it; a committed install runs it directly from a framework checkout at
the release:

  python3 <framework>/scripts/upgrade.py <repo> [--dry-run] [--add-modules a,b]

Options:
  --dry-run            change nothing; report what the run would do
  --add-modules a,b    install these modules in this upgrade (the developer's choice)
  --history <dir>      a framework checkout with the releases' history (default: this tree, when it is one)
  --new-ref <commit>   the commit this tree is (default: its HEAD, or the tag of its version)
  --unreleased         allow a tree that isn't a release; the stamp then carries its SHA alone
  --protocol <n>       the adf-upgrade wrapper's protocol (1)

Exit codes: 0 it ran (the report says what needs a person), 1 an error, 2 it refused.
The report goes to $(git rev-parse --git-dir)/adf-upgrade/report.md and report.json.
"""
import argparse
import datetime
import difflib
import fnmatch
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

FRAMEWORK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROTOCOLS = {1}
FLOOR = (2, 0, 0)
PLUGIN_NAMES = ("adf@aplyca", "aplyca-adf@aplyca", "aplyca-framework@aplyca")
STAMP = re.compile(r"Skeleton source:\s*(v\d+\.\d+\.\d+)?\s*·?\s*([0-9a-f]{7,40})\s*(?:\((\d{4}-\d\d-\d\d)\))?")
REFUSED, ERROR = 2, 1


class Refusal(Exception):
    pass


def version_tuple(tag):
    return tuple(int(x) for x in tag.lstrip("v").split("."))


def run(cmd, cwd=None, check=True, input=None, env=None):
    result = subprocess.run(cmd, cwd=cwd, input=input, capture_output=True, env=env)
    if check and result.returncode != 0:
        raise RuntimeError(f"{' '.join(cmd)} failed: {result.stderr.decode(errors='replace').strip()}")
    return result


def git(repo, *args, check=True):
    return run(["git", "-C", repo, *args], check=check).stdout.decode(errors="replace").strip()


def load_json_text(data):
    try:
        return json.loads(data)
    except (ValueError, TypeError):
        return None


def dump_json(data):
    return (json.dumps(data, indent=2, ensure_ascii=False) + "\n").encode()


# ─── the project's files, through an overlay in a dry run ──────────────────────────────────────

class Workspace:
    """The project's files. A real run writes the project; a dry run writes an overlay folder and
    reads through it, so every step sees the steps before it and the project stays untouched."""

    def __init__(self, repo, dry):
        self.repo, self.dry = repo, dry
        self.overlay = tempfile.mkdtemp(prefix="adf-upgrade-overlay-") if dry else repo
        self.deleted = set()

    def _real(self, rel):
        return os.path.join(self.overlay, rel)

    def read(self, rel):
        if rel in self.deleted:
            return None
        for top in ([self.overlay, self.repo] if self.dry else [self.repo]):
            path = os.path.join(top, rel)
            if os.path.isfile(path):
                with open(path, "rb") as f:
                    return f.read()
        return None

    def text(self, rel):
        data = self.read(rel)
        return None if data is None else data.decode("utf-8", errors="replace")

    def exists(self, rel):
        return self.read(rel) is not None

    def files(self, rel):
        """Every file under a folder, as project paths."""
        found = set()
        for top in {self.overlay, self.repo}:
            base = os.path.join(top, rel)
            for directory, dirs, names in os.walk(base):
                dirs[:] = [d for d in dirs if d != ".git"]
                for name in names:
                    found.add(os.path.relpath(os.path.join(directory, name), top))
        return sorted(f for f in found if f not in self.deleted)

    def write(self, rel, data, executable=None):
        path = self._real(rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if executable is None:
            old = os.path.join(self.repo, rel)
            executable = os.path.isfile(old) and os.access(old, os.X_OK)
        with open(path, "wb") as f:
            f.write(data if isinstance(data, bytes) else data.encode())
        os.chmod(path, 0o755 if executable else 0o644)
        self.deleted.discard(rel)

    def delete(self, rel):
        if self.dry:
            self.deleted.add(rel)
            path = self._real(rel)
            if os.path.isfile(path):
                os.remove(path)
            return
        path = os.path.join(self.repo, rel)
        if os.path.isfile(path):
            os.remove(path)
            parent = os.path.dirname(path)
            while parent != self.repo and os.path.isdir(parent) and not os.listdir(parent):
                os.rmdir(parent)
                parent = os.path.dirname(parent)

    def move(self, src, dst):
        """A file or a folder, with git mv in a real run so history follows it."""
        if not self.dry:
            os.makedirs(os.path.dirname(os.path.join(self.repo, dst)), exist_ok=True)
            tracked = git(self.repo, "ls-files", "--", src, check=False)
            if tracked:
                git(self.repo, "mv", src, dst)
            else:
                shutil.move(os.path.join(self.repo, src), os.path.join(self.repo, dst))
            return
        sources = self.files(src) if not self.exists(src) else [src]
        for f in sources:
            target = dst + f[len(src):]
            path = os.path.join(self.repo, f)
            self.write(target, self.read(f), executable=os.path.isfile(path) and os.access(path, os.X_OK))
            self.delete(f)

    def materialize(self, rels):
        """Copy files into the overlay, so a tool run against the overlay sees them (a dry run)."""
        for rel in rels:
            data = self.read(rel)
            if data is not None and self.dry and not os.path.isfile(self._real(rel)):
                self.write(rel, data)

    def settings(self):
        return load_json_text(self.read(".claude/settings.json") or b"{}")

    def save_settings(self, data):
        self.write(".claude/settings.json", dump_json(data), executable=False)

    def cleanup(self):
        if self.dry:
            shutil.rmtree(self.overlay, ignore_errors=True)


# ─── the releases ──────────────────────────────────────────────────────────────────────────────

class Release:
    """A framework release's files: from a tree on disk (NEW) or from history (OLD)."""

    def __init__(self, tree, commit, tag):
        self.tree, self.commit, self.tag = tree, commit, tag
        self.version = tag

    def module_json(self, module):
        path = os.path.join(self.tree, "modules", module, "module.json")
        if not os.path.isfile(path):
            return {}
        with open(path, encoding="utf-8") as f:
            return json.load(f)

    def has_module(self, module):
        return os.path.isdir(os.path.join(self.tree, "modules", module))

    def layer(self, modules, packaged, new_release):
        """{project path: (bytes, executable, source path)} for the skeleton and the modules' files.
        A packaged project leaves out what the new release's plugins carry (decision 0016, 0027)."""
        sources = [("skeleton", "")]
        sources += [(f"modules/{m}/files", m) for m in sorted(modules) if self.has_module(m)]
        out = {}
        moved = {}
        for m in modules:
            info = new_release.module_json(m)
            if info.get("moved_from") and info.get("commands"):
                moved[info["moved_from"]] = os.path.dirname(next(iter(info["commands"].values())))
        for top, module in sources:
            base = os.path.join(self.tree, top)
            for directory, _, names in os.walk(base):
                for name in names:
                    path = os.path.join(directory, name)
                    rel = os.path.relpath(path, base)
                    for old, new in moved.items():  # a folder a module moved: both sides at the new path
                        if rel.startswith(old + "/"):
                            rel = new + rel[len(old):]
                    if packaged and carried_by_plugin(rel, modules, new_release):
                        continue
                    with open(path, "rb") as f:
                        out[rel] = (f.read(), os.access(path, os.X_OK), os.path.relpath(path, self.tree))
        return out

    def machinery(self, modules, workdir, name):
        """A committed install's machinery: build-committed.py from this release's own tree (0028)."""
        out = os.path.join(workdir, name)
        os.makedirs(out, exist_ok=True)
        script = os.path.join(self.tree, "scripts", "build-committed.py")
        known = [m for m in sorted(modules) if self.has_module(m)]
        cmd = [sys.executable, script, out] + (["--modules", ",".join(known)] if known else [])
        run(cmd)
        files = {}
        for directory, _, names in os.walk(out):
            for fname in names:
                path = os.path.join(directory, fname)
                rel = os.path.relpath(path, out)
                with open(path, "rb") as f:
                    files[rel] = (f.read(), os.access(path, os.X_OK), "build-committed.py")
        return files


def carried_by_plugin(rel, modules, new_release):
    """What a packaged project doesn't commit: the machinery, the reference docs, and the module
    scripts the plugin carries as commands (everything in their folder but the settings)."""
    if rel.startswith((".claude/skills/", ".claude/agents/", ".claude/workflows/")):
        return True
    if rel.startswith(".claude/hooks/") and rel != ".claude/hooks/config.sh":
        return True
    docs = os.path.join(new_release.tree, "plugins", "adf", "docs")
    if rel.startswith("docs/") and rel.count("/") == 1 and os.path.isfile(os.path.join(docs, rel[5:])):
        return True
    for m in modules:
        for script in new_release.module_json(m).get("commands", {}).values():
            if os.path.dirname(rel) == os.path.dirname(script) and rel.endswith(".sh"):
                return True
    return False


# ─── buckets, merges, and the per-path table ───────────────────────────────────────────────────

def load_buckets(tree):
    with open(os.path.join(tree, "scripts", "upgrade-buckets.json"), encoding="utf-8") as f:
        data = json.load(f)
    return {k: data[k] for k in ("merge", "overwrite", "project-owned")}


def bucket_of(rel, buckets):
    for name in ("merge", "overwrite", "project-owned"):
        if any(fnmatch.fnmatchcase(rel, p) for p in buckets[name]):
            return name
    return "merge"


def is_text(data):
    try:
        data.decode("utf-8")
        return b"\0" not in data
    except UnicodeDecodeError:
        return False


def merge3(ours, base, theirs, old_label, new_label):
    """git merge-file: (merged bytes, number of conflicts)."""
    with tempfile.TemporaryDirectory() as tmp:
        paths = []
        for name, data in (("ours", ours), ("base", base), ("theirs", theirs)):
            p = os.path.join(tmp, name)
            with open(p, "wb") as f:
                f.write(data)
            paths.append(p)
        result = subprocess.run(["git", "merge-file", "-p", "-L", "project", "-L", old_label, "-L", new_label, *paths],
                                capture_output=True)
        if result.returncode < 0 or result.returncode > 127:
            raise RuntimeError(f"git merge-file failed: {result.stderr.decode(errors='replace')}")
        merged = result.stdout
        conflicts = len(re.findall(rb"^<<<<<<< project", merged, re.M))
        return merged, conflicts


def hunks(before, after):
    a = before.decode("utf-8", errors="replace").splitlines()
    b = after.decode("utf-8", errors="replace").splitlines()
    return sum(1 for line in difflib.unified_diff(a, b, lineterm="", n=3) if line.startswith("@@"))


def without_hooks(data):
    """A packaged project's settings have no hooks block (decision 0016): merge without it."""
    parsed = load_json_text(data)
    if not isinstance(parsed, dict) or "hooks" not in parsed:
        return data
    parsed.pop("hooks")
    return dump_json(parsed)


def renames(history, old, new):
    """{old source path: new source path} from git's rename detection on the layer's sources."""
    out = git(history, "diff", "-M", "--name-status", old, new, "--", "skeleton", "modules", check=False)
    found = {}
    for line in out.splitlines():
        parts = line.split("\t")
        if parts[0].startswith("R") and len(parts) == 3:
            found[parts[1]] = parts[2]
    return found


def to_project(source):
    if source.startswith("skeleton/"):
        return source[len("skeleton/"):]
    m = re.match(r"modules/[^/]+/files/(.*)", source)
    return m.group(1) if m else None


# ─── settings and permissions ──────────────────────────────────────────────────────────────────

COVERING = re.compile(r"^Bash\(([^*()]+?)(?: \*|:\*)\)$")
BASH_RULE = re.compile(r"^Bash\((.*)\)$")


def covering_rule(rule, allow):
    """The rule in the same allow list that covers this one, or None (decision 0046, § 4):
    `Bash(<prefix> *)` or `Bash(<prefix>:*)` covers `Bash(<prefix> …)`. Only Bash rules."""
    spec = BASH_RULE.match(rule)
    if not spec:
        return None
    spec = spec.group(1)
    for other in allow:
        if other == rule:
            continue
        m = COVERING.match(other)
        if not m:
            continue
        prefix = m.group(1)
        if spec.startswith(prefix + " ") and spec != prefix + " *":
            return other
    return None


def prune_allow(settings):
    """Drop exact duplicates and covered rules from permissions.allow; never ask or deny."""
    allow = (settings or {}).get("permissions", {}).get("allow")
    if not isinstance(allow, list):
        return []
    dropped, kept, seen = [], [], set()
    for rule in allow:
        if rule in seen:
            dropped.append((rule, rule))
            continue
        seen.add(rule)
        kept.append(rule)
    final = []
    for rule in kept:
        cover = covering_rule(rule, kept)
        if cover:
            dropped.append((rule, cover))
        else:
            final.append(rule)
    settings["permissions"]["allow"] = final
    return dropped


def permissions(settings):
    perms = (settings or {}).get("permissions", {}) if isinstance(settings, dict) else {}
    return {k: list(perms.get(k, [])) for k in ("allow", "ask", "deny")}


def permission_changes(before, after, source):
    changes = []
    for key in ("allow", "ask", "deny"):
        for rule in after[key]:
            if rule not in before[key]:
                changes.append({"change": "added", "list": key, "rule": rule, "by": source})
        for rule in before[key]:
            if rule not in after[key]:
                changes.append({"change": "removed", "list": key, "rule": rule, "by": source})
    return changes


# ─── migrations ────────────────────────────────────────────────────────────────────────────────

class MigrationContext:
    """What a migration gets: the project (through the workspace), the install, and the releases.
    A migration writes only through it, so a dry run changes nothing."""

    def __init__(self, upgrade):
        self.u = upgrade
        self.ws = upgrade.ws
        self.repo = upgrade.repo
        self.install = upgrade.install
        self.packaged = upgrade.install == "packaged"
        self.modules = set(upgrade.modules)
        self.old, self.new = upgrade.old, upgrade.new
        self.dry_run = upgrade.dry
        self.touched = upgrade.touched

    def write(self, rel, data, executable=None):
        self.ws.write(rel, data, executable)
        self.touched.add(rel)

    def delete(self, rel):
        self.ws.delete(rel)
        self.touched.add(rel)

    def move(self, src, dst):
        self.ws.move(src, dst)
        self.touched.update({src, dst})

    def settings(self):
        return self.ws.settings()

    def save_settings(self, data):
        self.ws.save_settings(data)

    def old_file(self, source):
        """A file of the old release, by its path in the framework (None if it had none)."""
        result = run(["git", "-C", self.u.history, "show", f"{self.old.commit}:{source}"], check=False)
        return result.stdout if result.returncode == 0 else None

    def new_file(self, source):
        path = os.path.join(self.new.tree, source)
        return open(path, "rb").read() if os.path.isfile(path) else None

    def new_machinery(self, rel):
        """A committed install's copy of a machinery file at the new release."""
        built = self.u.new_machinery()
        return built.get(rel, (None,))[0]

    def claim(self, rel):
        """A path this migration owns, written or not: the file step leaves it alone."""
        self.touched.add(rel)

    def follow_up(self, command, why, source, plugin="adf"):
        self.u.add_follow_up(command, why, source, plugin)

    def grep(self, pattern):
        out = git(self.repo, "grep", "-n", "-I", "-e", pattern, check=False)
        return [line for line in out.splitlines() if line]


def discover_migrations(tree, old_version, new_version, unreleased):
    """Every migration from the old release's own (a project may have skipped part of it) through
    the new one, in version order, then by NN. Each is scripts/migrations/<version>/NN-<slug>.py."""
    top = os.path.join(tree, "scripts", "migrations")
    found = []
    if not os.path.isdir(top):
        return found
    for folder in os.listdir(top):
        path = os.path.join(top, folder)
        if not os.path.isdir(path):
            continue
        if folder == "unreleased":
            if not unreleased:
                continue
            key = (999, 0, 0)
        elif re.fullmatch(r"v\d+\.\d+\.\d+", folder):
            key = version_tuple(folder)
            if not (version_tuple(old_version) <= key <= version_tuple(new_version)):
                continue
        else:
            continue
        for name in os.listdir(path):
            if re.fullmatch(r"\d\d-[a-z0-9-]+\.py", name):
                found.append((key, name, folder, os.path.join(path, name)))
    return [(folder, name, path) for _, name, folder, path in sorted(found)]


def load_migration(path):
    spec = importlib.util.spec_from_file_location("migration_" + re.sub(r"\W", "_", path), path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    assert getattr(module, "PHASE", None) in ("before", "after"), f"{path}: PHASE must be 'before' or 'after'"
    assert callable(getattr(module, "run", None)), f"{path}: no run(ctx)"
    return module


# ─── the upgrade ───────────────────────────────────────────────────────────────────────────────

class Upgrade:
    def __init__(self, args):
        self.args = args
        self.repo = os.path.abspath(args.repo)
        self.dry = args.dry_run
        self.history = os.path.abspath(args.history or FRAMEWORK)
        self.touched = set()
        self.report = {
            "header": {}, "releases": [],
            "needs_you": {"conflicts": [], "permission_changes": [], "modules": [], "files": [], "migrations": [],
                          "customize": []},
            "applied": {"clean_merges": [], "overwritten": [], "added": [], "deleted": [], "renamed": [],
                        "migrations": [], "installers": [], "allow_rules_dropped": [], "pin": None,
                        "reference_links": None, "stamp": None},
            "checks": [], "machines": [], "follow_ups": [],
        }
        self._new_build = None

    # ── resolve ──
    def resolve(self):
        if not os.path.isdir(os.path.join(self.repo, ".git")) and run(
                ["git", "-C", self.repo, "rev-parse", "--git-dir"], check=False).returncode:
            raise Refusal(f"{self.repo} isn't a git repository")
        if run(["git", "-C", self.history, "rev-parse", "--git-dir"], check=False).returncode:
            raise Refusal(f"{self.history} isn't a framework checkout with history: pass --history")
        if git(self.history, "rev-parse", "--is-shallow-repository") == "true":
            raise Refusal(f"{self.history} is a shallow clone; the upgrade needs the releases' history")

        with open(os.path.join(FRAMEWORK, "plugins", "adf", ".claude-plugin", "plugin.json"), encoding="utf-8") as f:
            version = "v" + json.load(f)["version"]
        tag_commit = git(self.history, "rev-parse", "--verify", "-q", f"{version}^{{commit}}", check=False)
        if self.args.new_ref:
            new_commit = git(self.history, "rev-parse", "--verify", f"{self.args.new_ref}^{{commit}}")
        elif os.path.isdir(os.path.join(FRAMEWORK, ".git")) or os.path.isfile(os.path.join(FRAMEWORK, ".git")):
            new_commit = git(FRAMEWORK, "rev-parse", "HEAD")
        else:
            new_commit = tag_commit
        if not new_commit:
            raise Refusal(f"can't tell which commit this tree is: pass --new-ref")
        self.released = new_commit == tag_commit
        if not self.released and not self.args.unreleased:
            raise Refusal(f"this tree ({new_commit[:7]}) isn't the release {version}: check out the tag, or pass --unreleased")
        self.new = Release(FRAMEWORK, new_commit, version)

        agents = os.path.join(self.repo, "AGENTS.md")
        stamp_line = open(agents, encoding="utf-8").readline() if os.path.isfile(agents) else ""
        m = STAMP.search(stamp_line)
        if not m:
            raise Refusal("no `Skeleton source:` stamp on AGENTS.md's first line: run /adf:upgrade, which infers the "
                          "baseline with you, or /adf:adopt")
        self.stamp_line = stamp_line
        old_commit = git(self.history, "rev-parse", "--verify", "-q", f"{m.group(2)}^{{commit}}", check=False)
        if not old_commit:
            raise Refusal(f"the stamp's commit {m.group(2)} isn't in {self.history}: fetch it, or pass --history")
        old_tag = m.group(1) or git(self.history, "describe", "--tags", "--abbrev=0", "--match", "v*", old_commit, check=False)
        if not old_tag or version_tuple(old_tag) < FLOOR:
            raise Refusal(f"the project is at {old_tag or old_commit[:7]}; the scripted upgrade starts at v2.0.0. "
                          "Follow /adf:upgrade's manual procedure to reach v2.0.0 first")
        if old_commit == new_commit:
            raise Refusal(f"the project is already at {version} ({new_commit[:7]})")
        if version_tuple(old_tag) > version_tuple(version):
            raise Refusal(f"the project is at {old_tag}, newer than {version}")
        self.old_tree = tempfile.mkdtemp(prefix="adf-upgrade-old-")
        archive = run(["git", "-C", self.history, "archive", old_commit])
        run(["tar", "-x", "-C", self.old_tree], input=archive.stdout)
        self.old = Release(self.old_tree, old_commit, old_tag)

        mods = re.search(r"· modules: ([^·>]*)", stamp_line)
        listed = [x for x in re.split(r"[,\s]+", mods.group(1)) if x] if mods else []
        self.stamp_modules = [x for x in listed if os.path.isdir(os.path.join(FRAMEWORK, "modules", x))]
        added = [m for m in (self.args.add_modules or "").split(",") if m]
        unknown = [m for m in added if not self.new.has_module(m)]
        if unknown:
            raise Refusal(f"no such module at {version}: {', '.join(unknown)}")
        self.added_modules = [m for m in added if m not in self.stamp_modules]
        self.modules = self.stamp_modules + self.added_modules

        settings = load_json_text(open(os.path.join(self.repo, ".claude", "settings.json"), "rb").read()) \
            if os.path.isfile(os.path.join(self.repo, ".claude", "settings.json")) else {}
        enabled = (settings or {}).get("enabledPlugins", {}) or {}
        self.enabled_before = {k for k, v in enabled.items() if v and k.endswith("@aplyca")}
        # The stamp says packaged; committed machinery says committed (which keeps adf on for /adf:upgrade);
        # otherwise the plugin's setting decides (decision 0016).
        committed = os.path.isdir(os.path.join(self.repo, ".claude", "skills")) or \
            os.path.isfile(os.path.join(self.repo, ".claude", "hooks", "_lib.sh"))
        packaged = "install: packaged" in stamp_line or (not committed and any(enabled.get(n) for n in PLUGIN_NAMES))
        self.install = "packaged" if packaged else "committed"
        self.ws = Workspace(self.repo, self.dry)
        self.buckets = load_buckets(FRAMEWORK)

        date = git(self.history, "log", "-1", "--format=%cs", new_commit)
        self.report["header"] = {
            "old": {"version": old_tag, "commit": old_commit[:7]},
            "new": {"version": version if self.released else None, "commit": new_commit[:7], "date": date},
            "install": self.install, "modules": self.modules, "added_modules": self.added_modules, "dry_run": self.dry,
        }

    def preconditions(self):
        if self.dry:
            return
        if git(self.repo, "status", "--porcelain"):
            raise Refusal("the working tree has uncommitted changes: commit or stash them first")
        branch = git(self.repo, "rev-parse", "--abbrev-ref", "HEAD")
        default = git(self.repo, "symbolic-ref", "--short", "-q", "refs/remotes/origin/HEAD", check=False)
        default = default.split("/", 1)[1] if default else "main"
        if branch in (default, "main", "master", "HEAD"):
            raise Refusal(f"on {branch}: run the upgrade on its own branch (chore/skeleton-upgrade-{self.new.commit[:7]})")
        hub = any(os.path.isfile(os.path.join(self.repo, d, "worktree.conf")) for d in ("ops/agent", "scripts/agent"))
        common = os.path.abspath(os.path.join(self.repo, git(self.repo, "rev-parse", "--git-common-dir")))
        gitdir = os.path.abspath(os.path.join(self.repo, git(self.repo, "rev-parse", "--git-dir")))
        if hub and common == gitdir:
            raise Refusal("this is the hub's main checkout: run the upgrade in the task's worktree (/adf:dispatch)")

    # ── the releases in between ──
    def releases(self):
        path = os.path.join(FRAMEWORK, "CHANGELOG.md")
        text = open(path, encoding="utf-8").read()
        sections = re.split(r"^## ", text, flags=re.M)[1:]
        lo, hi = version_tuple(self.old.tag), version_tuple(self.new.tag)
        for section in sections:
            heading, _, body = section.partition("\n")
            m = re.match(r"(v\d+\.\d+\.\d+)", heading)
            if heading.startswith("Unreleased"):
                if self.released or not body.strip():
                    continue
                version = "Unreleased"
            elif m and lo < version_tuple(m.group(1)) <= hi:
                version = m.group(1)
            else:
                continue
            entries = []
            for chunk in re.split(r"^- \*\*", body, flags=re.M)[1:]:
                title = " ".join(chunk.split("**", 1)[0].split())
                migration = None
                if re.search(r"\*\*[^*\n]*[Mm]igration[^*\n]*\*\*", chunk):
                    scripts = re.findall(r"scripts/migrations/[\w./-]+\.py", chunk)
                    migration = "scripted: " + ", ".join(sorted(set(scripts))) if scripts else "by hand"
                impact = re.search(r"\*\*Upgrade impact:?\*\*:?\s*(.*)", chunk)
                entries.append({"title": title, "upgrade_impact": (impact.group(1).strip() if impact else ""),
                                "migration": migration})
            self.report["releases"].append({"version": version, "title": heading.strip(), "entries": entries})

    # ── copies ──
    def new_machinery(self):
        if self._new_build is None:
            self._new_build = self.new.machinery(self.modules, self.old_tree + "-builds", "new") \
                if self.install == "committed" else {}
        return self._new_build

    def copies(self):
        packaged = self.install == "packaged"
        old = self.old.layer(self.stamp_modules, packaged, self.new)
        new = self.new.layer(self.modules, packaged, self.new)
        if not packaged:
            old.update(self.old.machinery(self.stamp_modules, self.old_tree + "-builds", "old"))
            new.update(self.new_machinery())
        moves = {}
        for src, dst in renames(self.history, self.old.commit, self.new.commit).items():
            a, b = to_project(src), to_project(dst)
            if a and b and a != b and a in old and b in new:
                moves[b] = a
        return old, new, moves

    # ── the per-path table ──
    def apply_files(self):
        old, new, moves = self.copies()
        packaged = self.install == "packaged"
        old_label, new_label = self.old.tag, self.new.tag if self.released else self.new.commit[:7]
        saved = os.path.join(self.report_dir(), "new")
        move_sources = set(moves.values())
        for rel in sorted(set(old) | set(new)):
            if rel in self.touched or bucket_of(rel, self.buckets) == "project-owned":
                continue
            if rel in move_sources and rel not in new:
                continue  # the old side of a rename: handled at its new path
            base_rel = moves.get(rel, rel)
            o = old.get(base_rel, (None,))[0]
            n, n_exec = new.get(rel, (None, False))[:2]
            bucket = bucket_of(rel, self.buckets)
            p = self.ws.read(rel)
            if rel in moves:
                old_path_content = self.ws.read(base_rel)
                if p is None and old_path_content is not None:
                    self.ws.move(base_rel, rel)
                    self.report["applied"]["renamed"].append({"from": base_rel, "to": rel})
                    p = old_path_content
                elif p is not None and old_path_content is not None:
                    self.needs_file(rel, f"renamed from {base_rel}, and the project has both")
                    continue
            if rel == ".claude/settings.json" and packaged:
                o = without_hooks(o) if o is not None else o
                n = without_hooks(n) if n is not None else n
            if o == n:
                continue
            if o is None:  # added upstream
                if p is None:
                    self.ws.write(rel, n, n_exec)
                    self.report["applied"]["added"].append(rel)
                elif p != n:
                    target = os.path.join(saved, rel)
                    if not self.dry:
                        os.makedirs(os.path.dirname(target), exist_ok=True)
                        open(target, "wb").write(n)
                    self.needs_file(rel, f"new in {new_label}, and the project already has one: the new copy is at "
                                         f"{os.path.relpath(target, self.repo)}")
                continue
            if n is None:  # deleted upstream
                if p is None:
                    continue
                if p == o:
                    self.ws.delete(rel)
                    self.report["applied"]["deleted"].append(rel)
                else:
                    self.needs_file(rel, f"deleted in {new_label}, and the project edited its copy")
                continue
            if p is None:
                self.needs_file(rel, f"changed in {new_label}, and the project deleted it")
                continue
            if p == n:
                continue
            if not (is_text(p) and is_text(o) and is_text(n)):
                if p == o:
                    self.ws.write(rel, n, n_exec)
                    self.report["applied"]["overwritten"].append(rel)
                else:
                    self.needs_file(rel, "a binary file the project changed")
                continue
            if bucket == "overwrite" and p == o:
                self.ws.write(rel, n, n_exec)
                self.report["applied"]["overwritten"].append(rel)
                continue
            merged, conflicts = merge3(p, o, n, old_label, new_label)
            self.ws.write(rel, merged, n_exec)
            entry = {"file": rel, "hunks": hunks(p, merged)}
            if bucket == "overwrite":
                entry["edited_machinery"] = True
            if conflicts:
                self.report["needs_you"]["conflicts"].append({"file": rel, "conflicts": conflicts,
                                                              "edited_machinery": bucket == "overwrite"})
            else:
                self.report["applied"]["clean_merges"].append(entry)

    def needs_file(self, rel, why):
        self.report["needs_you"]["files"].append({"file": rel, "why": why})

    # ── a module's folder that moved (module.json's moved_from, decision 0032) ──
    def module_moves(self):
        for module in self.modules:
            info = self.new.module_json(module)
            old, commands = info.get("moved_from"), info.get("commands")
            if not old or not commands or not self.ws.files(old):
                continue
            new = os.path.dirname(next(iter(commands.values())))
            if self.ws.files(new):
                self.report["needs_you"]["migrations"].append({
                    "migration": f"{module} folder", "text": f"both `{old}/` and `{new}/` exist: keep one, by hand"})
                continue
            self.ws.move(old, new)
            self.report["applied"]["renamed"].append({"from": old + "/", "to": new + "/"})
            for rel in [os.path.join(new, "worktree.conf"), ".worktreeinclude"] + \
                    (["AGENTS.md"] if self.install == "committed" else []):
                text = self.ws.text(rel)
                if text and old + "/" in text:
                    self.ws.write(rel, text.replace(old + "/", new + "/"))
            hits = [h for h in git(self.repo, "grep", "-n", "-I", "-e", old + "/", check=False).splitlines()
                    if h and not h.startswith((new + "/", ".worktreeinclude", "AGENTS.md"))
                    and bucket_of(h.split(":", 1)[0], self.buckets) != "overwrite"]  # machinery names both
            if hits:
                self.report["needs_you"]["migrations"].append({
                    "migration": f"{module} folder", "text": f"these still name `{old}/`:\n"
                    + "\n".join(f"  {h}" for h in hits[:20])})

    # ── migrations ──
    def run_migrations(self, phase):
        ctx = MigrationContext(self)
        for folder, name, path in discover_migrations(FRAMEWORK, self.old.tag, self.new.tag, not self.released):
            module = load_migration(path)
            if module.PHASE != phase:
                continue
            slug = f"{folder}/{name[:-3]}"
            before = permissions(self.ws.settings())
            status, text = module.run(ctx)
            assert status in ("applied", "done", "needs"), f"{slug} returned {status!r}"
            after = permissions(self.ws.settings())
            self.report["needs_you"]["permission_changes"] += permission_changes(before, after, f"migration {slug}")
            if status == "needs":
                self.report["needs_you"]["migrations"].append({"migration": slug, "text": text})
            else:
                self.report["applied"]["migrations"].append({"migration": slug, "status": status, "text": text})

    # ── installers ──
    def installers(self):
        for module in self.modules:
            script = os.path.join(FRAMEWORK, "modules", module, "install.sh")
            if not os.path.isfile(script):
                continue
            if self.ws.exists(".claude/settings.json") and self.ws.settings() is None:
                self.report["needs_you"]["migrations"].append({
                    "migration": f"installer {module}",
                    "text": f".claude/settings.json doesn't parse (a conflict?): resolve it, then run "
                            f"`sh {script} .`"})
                continue
            self.ws.materialize([".claude/settings.json", ".mcp.json"])
            before = permissions(self.ws.settings())
            result = run(["sh", script, self.ws.overlay], check=False)
            if result.returncode:
                self.report["needs_you"]["migrations"].append({
                    "migration": f"installer {module}",
                    "text": f"`sh {script} .` failed: {result.stderr.decode(errors='replace').strip()}"})
                continue
            self.ws.deleted.discard(".claude/settings.json")
            after = permissions(self.ws.settings())
            self.report["needs_you"]["permission_changes"] += permission_changes(before, after, f"{module} installer")
            self.report["applied"]["installers"].append({"module": module,
                                                         "output": result.stdout.decode(errors="replace").strip()})

    # ── settings: modules' plugins, the pin, pruning ──
    def settings_steps(self):
        settings = self.ws.settings()
        if settings is None:
            if self.ws.exists(".claude/settings.json"):
                self.report["needs_you"]["migrations"].append({
                    "migration": "settings", "text": ".claude/settings.json doesn't parse: resolve its conflicts, "
                                                     "then set the pin and prune by hand"})
            return
        before = permissions(settings)
        if self.install == "packaged":
            for module in self.added_modules:
                plugin = self.new.module_json(module).get("plugin")
                if plugin and plugin != "adf":
                    settings.setdefault("enabledPlugins", {})[f"{plugin}@aplyca"] = True
                    rule = f"Read(~/.claude/plugins/cache/aplyca/{plugin}/**)"
                    allow = settings.setdefault("permissions", {}).setdefault("allow", [])
                    if rule not in allow:
                        allow.append(rule)
        entry = (settings.get("extraKnownMarketplaces") or {}).get("aplyca")
        if isinstance(entry, dict) and isinstance(entry.get("source"), dict):
            if self.released:
                old_ref = entry["source"].get("ref")
                entry["source"]["ref"] = self.new.tag
                self.report["applied"]["pin"] = {"from": old_ref, "to": self.new.tag,
                                                 "autoUpdate": bool(entry.get("autoUpdate"))}
            else:
                self.report["applied"]["pin"] = {"from": entry["source"].get("ref"), "to": None,
                                                 "note": "not a release: the pin stays"}
        elif self.install == "packaged":
            self.report["needs_you"]["migrations"].append({
                "migration": "plugin setting",
                "text": "no `aplyca` entry in extraKnownMarketplaces: add it with its `ref` and `autoUpdate`, and "
                        "`\"adf@aplyca\": true` in enabledPlugins (the adf plugin's README § For teams)"})
        after_modules = permissions(settings)
        self.report["needs_you"]["permission_changes"] += permission_changes(before, after_modules, "module plugin")
        dropped = prune_allow(settings)
        self.report["applied"]["allow_rules_dropped"] = [{"rule": r, "covered_by": c} for r, c in dropped]
        self.ws.save_settings(settings)
        self.enabled_after = {k for k, v in (settings.get("enabledPlugins") or {}).items() if v and k.endswith("@aplyca")}

    # ── links, stamp, checks ──
    def reference_links(self):
        if self.install != "packaged":
            return
        if not self.released:
            self.report["applied"]["reference_links"] = "skipped: not a release"
            return
        if self.dry:
            self.report["applied"]["reference_links"] = f"would run link-reference-docs.py --packaged {self.new.tag}"
            return
        script = os.path.join(FRAMEWORK, "scripts", "link-reference-docs.py")
        result = run([sys.executable, script, self.repo, "--packaged", self.new.tag], check=False)
        self.report["applied"]["reference_links"] = result.stdout.decode(errors="replace").strip() or \
            result.stderr.decode(errors="replace").strip()

    def restamp(self):
        text = self.ws.text("AGENTS.md")
        if text is None:
            return
        first, _, rest = text.partition("\n")
        m = STAMP.search(first)
        if not m:
            self.report["needs_you"]["migrations"].append({"migration": "stamp", "text": "AGENTS.md's first line lost its "
                                                           "stamp in the merge: restore it"})
            return
        tail = re.search(r"( — [^>]*?)\s*-->", first)
        version = f"{self.new.tag} · " if self.released else ""
        modules = ", ".join(self.modules) or "none"
        install = " · install: packaged" if self.install == "packaged" else ""
        stamp = (f"<!-- Skeleton source: {version}{self.new.commit[:7]} ({self.report['header']['new']['date']})"
                 f" · modules: {modules}{install}{tail.group(1) if tail else ''} -->")
        self.ws.write("AGENTS.md", stamp + "\n" + rest, executable=False)
        self.report["applied"]["stamp"] = stamp

    def checks(self):
        checks = self.report["checks"]
        settings_raw = self.ws.read(".claude/settings.json")
        if settings_raw is not None:
            ok = load_json_text(settings_raw) is not None
            checks.append({"check": ".claude/settings.json parses", "ok": ok})
        if self.dry:
            checks.append({"check": "hook smoke tests", "ok": None, "note": "run on the real run"})
            return
        plugin_root = os.path.join(FRAMEWORK, "plugins", "adf")
        with open(os.path.join(plugin_root, "hooks", "hooks.json"), encoding="utf-8") as f:
            wiring = json.load(f)["hooks"]
        env = dict(os.environ, CLAUDE_PLUGIN_ROOT=plugin_root, CLAUDE_PROJECT_DIR=self.repo)
        seen = set()
        for event, groups in wiring.items():
            for group in groups:
                for hook in group["hooks"]:
                    name = re.search(r"hooks/([\w-]+\.sh)", hook["command"]).group(1)
                    script = os.path.join(plugin_root, "hooks", name) if self.install == "packaged" \
                        else os.path.join(self.repo, ".claude", "hooks", name)
                    key = (event, name)
                    if key in seen or not os.path.isfile(script):
                        continue
                    seen.add(key)
                    sample = {"hook_event_name": event, "cwd": self.repo, "session_id": "adf-upgrade-smoke"}
                    matcher = group.get("matcher") or ""
                    if event == "SessionStart":
                        sample["source"] = "startup"
                    elif "Bash" in matcher:
                        sample.update(tool_name="Bash", tool_input={"command": "git status"})
                    elif "Edit" in matcher:
                        sample.update(tool_name="Edit", tool_input={"file_path": os.path.join(self.repo, "README.md")})
                    else:
                        sample.update(tool_name=matcher.split("|")[0], tool_input={})
                    result = subprocess.run(["bash", script], input=json.dumps(sample).encode(), capture_output=True,
                                            cwd=self.repo, env=env, timeout=60)
                    err = result.stderr.decode(errors="replace")
                    ok = result.returncode in (0, 2) and "unbound variable" not in err and "command not found" not in err
                    checks.append({"check": f"hook {name} ({event})", "ok": ok,
                                   **({} if ok else {"note": (err.strip() or f"exit {result.returncode}")[:300]})})

    # ── follow-ups and machines ──
    def add_follow_up(self, command, why, source, plugin="adf"):
        # A committed install copies adf's and the modules' skills, but adf-connect's only come from its plugin.
        if self.install == "committed" and plugin != "adf-connect":
            command = re.sub(r"^/[\w-]+:", "/", command)
        item = {"command": command, "why": why, "source": source, "plugin": plugin, "when": "after-merge"}
        if all(f["command"] != command for f in self.report["follow_ups"]):
            self.report["follow_ups"].append(item)

    def follow_ups(self):
        def spec_changed(skill):
            return run(["git", "-C", self.history, "diff", "--quiet", self.old.commit, self.new.commit, "--",
                        f"plugins/adf-dev/skills/{skill}/SPECIFICATION.md"], check=False).returncode == 1

        if "docker" in self.added_modules:
            self.add_follow_up("/adf-dev:dev-env set up", "the docker module was added", "module docker", "adf-dev")
        elif "docker" in self.stamp_modules and spec_changed("dev-env"):
            self.add_follow_up("/adf-dev:dev-env set up", "the local environment specification changed",
                               f"{self.new.tag} dev-env SPECIFICATION.md", "adf-dev")
        if "e2e" in self.added_modules:
            self.add_follow_up("/adf-dev:e2e set up", "the e2e module was added", "module e2e", "adf-dev")
        elif "e2e" in self.stamp_modules and spec_changed("e2e"):
            self.add_follow_up("/adf-dev:e2e audit", "the end-to-end test specification changed",
                               f"{self.new.tag} e2e SPECIFICATION.md", "adf-dev")
        for module in self.added_modules:
            self.report["needs_you"]["customize"].append({
                "module": module, "text": f"modules/{module}/MODULE.md § Customize, at {self.new.tag}"})

    def machines(self):
        before = getattr(self, "enabled_before", set())
        after = getattr(self, "enabled_after", set())
        if not after:
            return
        cmds = ["claude plugin marketplace update aplyca"]
        cmds += [f"claude plugin install {p} --scope project" for p in sorted(after - before)]
        cmds += [f"claude plugin update {p}" for p in sorted(after & before)]
        cmds.append("/reload-plugins (in an open session), or a new session")
        self.report["machines"] = cmds

    def modules_offer(self):
        available = sorted(m for m in os.listdir(os.path.join(FRAMEWORK, "modules"))
                           if os.path.isdir(os.path.join(FRAMEWORK, "modules", m)) and m not in self.modules)
        self.report["needs_you"]["modules"] = available

    # ── report ──
    def report_dir(self):
        gitdir = git(self.repo, "rev-parse", "--absolute-git-dir")
        path = os.path.join(gitdir, "adf-upgrade")
        os.makedirs(path, exist_ok=True)
        return path

    def write_report(self):
        out = self.report_dir()
        with open(os.path.join(out, "report.json"), "w", encoding="utf-8") as f:
            json.dump(self.report, f, indent=2, ensure_ascii=False)
            f.write("\n")
        md = render(self.report)
        with open(os.path.join(out, "report.md"), "w", encoding="utf-8") as f:
            f.write(md)
        return md

    def execute(self):
        self.resolve()
        try:
            self.preconditions()
            self.releases()
            self.modules_offer()
            self.module_moves()
            self.run_migrations("before")
            before = permissions(self.ws.settings())
            self.apply_files()
            if self.ws.settings() is not None:
                self.report["needs_you"]["permission_changes"] += permission_changes(
                    before, permissions(self.ws.settings()), "merge of .claude/settings.json")
            self.installers()
            self.run_migrations("after")
            self.settings_steps()
            self.reference_links()
            self.restamp()
            self.follow_ups()
            self.machines()
            self.checks()
            return self.write_report()
        finally:
            self.ws.cleanup()
            shutil.rmtree(self.old_tree, ignore_errors=True)
            shutil.rmtree(self.old_tree + "-builds", ignore_errors=True)


# ─── the report in Markdown ────────────────────────────────────────────────────────────────────

def render(r):
    h = r["header"]
    new = h["new"]["version"] or "unreleased"
    lines = [f"# Framework upgrade {h['old']['version']} ({h['old']['commit']}) → {new} ({h['new']['commit']})", "",
             f"`{h['old']['version']} ({h['old']['commit']}) → {new} ({h['new']['commit']}) · install: {h['install']} · "
             f"modules: {', '.join(h['modules']) or 'none'}`" + (" — **dry run: nothing changed**" if h["dry_run"] else ""), ""]
    lines += ["## Releases", ""]
    for rel in r["releases"]:
        lines.append(f"- **{rel['title']}**")
        for e in rel["entries"]:
            extra = f" — migration: {e['migration']}" if e["migration"] else ""
            lines.append(f"  - {e['title']}{extra}")
    if not r["releases"]:
        lines.append("- (no changelog entries in between)")
    n = r["needs_you"]
    lines += ["", "## Needs you", ""]
    section = lambda title, items: lines.extend([f"### {title}", ""] + (items or ["- none"]) + [""])
    section("Conflicts", [f"- `{c['file']}` — {c['conflicts']} conflicting hunk(s)"
                          + (" (edited machinery)" if c.get("edited_machinery") else "") for c in n["conflicts"]])
    section("Permission changes", [f"- {p['change']} in `{p['list']}`: `{p['rule']}` — by {p['by']}"
                                   for p in n["permission_changes"]])
    section("Modules", [f"- {m}" for m in n["modules"]] + [f"- customize {c['module']}: {c['text']}" for c in n["customize"]])
    section("Files to decide", [f"- `{f['file']}` — {f['why']}" for f in n["files"]])
    section("Migrations", [f"- {m['migration']}: {m['text']}" for m in n["migrations"]])
    a = r["applied"]
    lines += ["## Applied", ""]
    section("Clean merges", [f"- `{c['file']}` — {c['hunks']} hunk(s)" + (" (edited machinery)" if c.get("edited_machinery") else "")
                             for c in a["clean_merges"]])
    section("Files", [f"- overwritten `{x}`" for x in a["overwritten"]] + [f"- added `{x}`" for x in a["added"]]
            + [f"- deleted `{x}`" for x in a["deleted"]] + [f"- renamed `{x['from']}` → `{x['to']}`" for x in a["renamed"]])
    section("Migrations", [f"- {m['migration']}: {m['status']} — {m['text']}" for m in a["migrations"]])
    section("Installers", [f"- {i['module']}: {i['output']}" for i in a["installers"]])
    section("Allow rules dropped", [f"- `{d['rule']}` — covered by `{d['covered_by']}`" for d in a["allow_rules_dropped"]])
    pin = a["pin"]
    other = []
    if pin:
        other.append(f"- pin: `{pin['from']}` → `{pin['to']}`" if pin["to"] else f"- pin: stays at `{pin['from']}` ({pin['note']})")
    if a["reference_links"]:
        other.append(f"- reference links: {a['reference_links'].splitlines()[0]}")
    if a["stamp"]:
        other.append(f"- stamp: `{a['stamp']}`")
    section("Pin, links, and stamp", other)
    lines += ["## Checks", ""]
    for c in r["checks"]:
        mark = "✓" if c["ok"] else ("–" if c["ok"] is None else "✘")
        lines.append(f"- {mark} {c['check']}" + (f" — {c['note']}" if c.get("note") else ""))
    lines += ["", "## On each machine", "", "After the merge, from the project's folder:", ""]
    lines += [f"- `{c}`" for c in r["machines"]] or ["- nothing"]
    lines += ["", "## Follow-ups", ""]
    lines += [f"- [ ] `{f['command']}` — {f['why']} ({f['source']})" for f in r["follow_ups"]] or ["- none"]
    return "\n".join(lines) + "\n"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("repo")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--add-modules", default="")
    parser.add_argument("--history")
    parser.add_argument("--new-ref")
    parser.add_argument("--unreleased", action="store_true")
    parser.add_argument("--protocol", type=int, default=1)
    args = parser.parse_args(argv)
    if args.protocol not in PROTOCOLS:
        print(f"adf-upgrade speaks protocol {args.protocol}; this release speaks {sorted(PROTOCOLS)}. "
              "Update the plugin first: claude plugin marketplace update aplyca && claude plugin update adf@aplyca",
              file=sys.stderr)
        return REFUSED
    upgrade = Upgrade(args)
    try:
        print(upgrade.execute(), end="")
    except Refusal as e:
        print(f"adf-upgrade: {e}", file=sys.stderr)
        return REFUSED
    except (RuntimeError, OSError) as e:
        print(f"adf-upgrade: error: {e}", file=sys.stderr)
        return ERROR
    return 0


if __name__ == "__main__":
    sys.exit(main())
