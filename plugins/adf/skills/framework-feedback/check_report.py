#!/usr/bin/env python3
"""Find where a project's framework reports go, and check a report for anything naming the project.

Two commands, both local (no network), Python 3 standard library only:

  check_report.py context [project-root]
      Print, as JSON, where the framework comes from (the marketplace that enables adf, its source
      repository, the host's CLI and new-issue page) and what the report's "Seen in" line needs
      (the release, the install form, the modules).

  check_report.py check <draft> [project-root] [--allow WORD ...]
      Scan a draft for anything that identifies the project and print one line per hit:
        BLOCK  the project's remotes, the git user, email addresses, home-directory paths (never
               cleared); the folder name, the project name, branch names, hostnames from .mcp.json
               and .claude/launch.json, references to other repositories (cleared with --allow)
        WARN   short or generic identifiers, one-word branch names, other URLs, the project's own
               file paths
      Exit 1 while a BLOCK remains, 0 otherwise, 2 on a usage error.

The project root defaults to the current directory. CLAUDE_CONFIG_DIR, when set, replaces ~/.claude.
"""
import json
import os
import re
import subprocess
import sys
from urllib.parse import urlparse

UPSTREAM = "aplyca/agenticdevelopmentframework"  # the framework's own repository is never a leak
FRAMEWORK_NAMES = {"agentic development framework", "agenticdevelopmentframework", "adf"}
CODE_HOSTS = {"github.com", "gitlab.com", "bitbucket.org", "codeberg.org", "ssh.github.com", "altssh.gitlab.com"}
GENERIC = {"app", "apps", "web", "www", "api", "site", "website", "frontend", "backend", "server",
           "client", "src", "code", "project", "repo", "docs", "test", "tests", "dev", "prod",
           "origin", "upstream"}
BASE_BRANCHES = {"main", "master", "develop", "development", "dev", "staging", "production", "prod",
                 "release", "trunk", "head"}
GITHUB_RESERVED = {"orgs", "settings", "features", "marketplace", "topics", "search", "notifications",
                   "sponsors", "apps", "about", "pricing", "login", "join", "enterprise", "security"}
MACHINERY = (".claude/skills/", ".claude/agents/", ".claude/workflows/", ".claude/hooks/")
NEVER_CLEARED = {"remote", "git-user", "email", "home-path"}

EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
HOME_PATH = re.compile(r"(?:/Users|/home)/[^/\s`'\")]+|[A-Za-z]:\\Users\\[^\\\s`'\")]+")
URL = re.compile(r"https?://[^\s)>\]`'\"]+")
REPO_REF = re.compile(r"(?<![\w./-])([\w.-]+(?:/[\w.-]+)+)[#!](\d+)\b")
PATH = re.compile(r"(?<![\w/.:-])((?:[\w.-]+/)+[\w.-]+|[\w-]+\.[A-Za-z][A-Za-z0-9]{0,4})(?![\w/])")


def git(root, *args):
    try:
        out = subprocess.run(["git", "-C", root, *args], capture_output=True, text=True, timeout=20)
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return out.stdout if out.returncode == 0 else ""


def read_json(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return {}


def read_text(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except (OSError, UnicodeDecodeError):
        return ""


def config_dir():
    return os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")


def parse_remote(url):
    """Return (host, path segments) for a git remote URL; a local path gives (None, [basename])."""
    url = url.strip()
    if "://" in url:
        parsed = urlparse(url)
        host, path = parsed.hostname, parsed.path
    else:
        scp = re.match(r"^(?:[\w.-]+@)?([\w.-]+):(?!\\)(.+)$", url)
        if scp and not re.match(r"^[A-Za-z]:[\\/]", url):
            host, path = scp.groups()
        else:
            return None, [re.sub(r"\.git$", "", os.path.basename(url.rstrip("/\\")))]
    segments = [s for s in re.sub(r"\.git$", "", path.strip("/")).split("/") if s]
    return (host.lower() if host else None), segments


# ─── context ──────────────────────────────────────────────────────────────

def context(root):
    root = os.path.abspath(root)
    settings = read_json(os.path.join(root, ".claude", "settings.json"))
    known = read_json(os.path.join(config_dir(), "plugins", "known_marketplaces.json"))
    enabled = settings.get("enabledPlugins") or {}
    marketplace = next((key.split("@", 1)[1] for key, on in enabled.items()
                        if key.startswith("adf@") and on), None)
    entry = (settings.get("extraKnownMarketplaces") or {}).get(marketplace) if marketplace else None
    if not entry and marketplace:
        entry = known.get(marketplace)
    if not entry and not marketplace:
        found = [(name, value) for name, value in known.items()
                 if isinstance(value, dict) and "AgenticDevelopmentFramework" in json.dumps(value.get("source", {}))]
        if len(found) == 1:
            marketplace, entry = found[0]
    source = (entry or {}).get("source") or {}

    host = repo = None
    kind = source.get("source")
    if kind == "github" and source.get("repo"):
        host, repo = "github.com", source["repo"].strip("/")
    elif kind == "git" and source.get("url"):
        remote_host, segments = parse_remote(source["url"])
        if remote_host and len(segments) >= 2:
            host, repo = remote_host, "/".join(segments)

    tool = new_issue = None
    if host == "github.com":
        tool, new_issue = "gh", f"https://github.com/{repo}/issues/new"
    elif host and "gitlab" in host:
        tool, new_issue = "glab", f"https://{host}/{repo}/-/issues/new"

    framework_dir = None
    install = (known.get(marketplace) or {}).get("installLocation") if marketplace else None
    for candidate in (install,
                      os.path.join(config_dir(), "plugins", "marketplaces", marketplace) if marketplace else None,
                      os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))):
        if candidate and os.path.isdir(os.path.join(candidate, "skeleton")):
            framework_dir = candidate
            break

    agents = read_text(os.path.join(root, "AGENTS.md"))
    stamp = agents.split("\n", 1)[0]
    release = re.search(r"Skeleton source:\s*(v\d+\.\d+\.\d+)", stamp)
    modules = re.search(r"modules:\s*([^—·>]+?)\s*(?:·|—|-->|$)", stamp)
    module_list = [m.strip() for m in modules.group(1).split(",")] if modules else []
    module_list = [m for m in module_list if m and m.lower() not in ("none", "[none]")]
    if "install: packaged" in stamp or "This project uses the packaged install" in agents:
        form = "packaged"
    elif os.path.isdir(os.path.join(root, ".claude", "skills")):
        form = "committed"
    else:
        form = None

    return {
        "marketplace": marketplace,
        "source": source or None,
        "host": host,
        "repo": repo,
        "tool": tool,
        "new_issue_url": new_issue,
        "framework_dir": framework_dir,
        "release": release.group(1) if release else None,
        "pinned_ref": source.get("ref"),
        "install": form,
        "modules": module_list,
    }


# ─── check ────────────────────────────────────────────────────────────────

def identifiers(root, ctx):
    """(text, kind) pairs that name the project, without the target repository's own names."""
    target = {s.lower() for s in (ctx.get("repo") or "").split("/") + UPSTREAM.split("/") if s}
    target |= FRAMEWORK_NAMES
    if ctx.get("host"):
        target.add(ctx["host"].lower())
    found = []

    remotes = set()
    for line in git(root, "remote", "-v").splitlines():
        parts = line.split()
        if len(parts) >= 2:
            remotes.add((parts[0], parts[1]))
    remote_names = {name for name, _ in remotes}
    for _, url in remotes:
        host, segments = parse_remote(url)
        if host and host not in CODE_HOSTS:
            found.append((host, "remote"))
        found += [(segment, "remote") for segment in segments]

    top = git(root, "rev-parse", "--show-toplevel").strip() or os.path.abspath(root)
    found.append((os.path.basename(top), "folder"))
    common = git(root, "rev-parse", "--path-format=absolute", "--git-common-dir").strip()
    if common.endswith("/.git"):  # a worktree: the main checkout's folder names the project too
        found.append((os.path.basename(os.path.dirname(common)), "folder"))
    heading = re.search(r"^# (.+)$", read_text(os.path.join(root, "AGENTS.md")), re.M)
    if heading and "[" not in heading.group(1):
        found.append((heading.group(1).strip(), "project-name"))

    for key in ("user.name", "user.email"):
        value = git(root, "config", key).strip()
        if value:
            found.append((value, "git-user"))

    refs = git(root, "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes").split()
    for ref in refs:
        first, _, rest = ref.partition("/")
        if first in remote_names:
            ref = rest
        if ref and ref.lower() not in BASE_BRANCHES and ref not in remote_names:
            found.append((ref, "branch"))

    for name in (".mcp.json", os.path.join(".claude", "launch.json")):
        for host in hosts_in(read_json(os.path.join(root, name))):
            found.append((host, "host"))

    unique, seen = [], set()
    for text, kind in found:
        key = text.lower()
        if text and key not in target and key not in seen:
            seen.add(key)
            unique.append((text, kind))
    return unique


def hosts_in(value):
    if isinstance(value, dict):
        for item in value.values():
            yield from hosts_in(item)
    elif isinstance(value, list):
        for item in value:
            yield from hosts_in(item)
    elif isinstance(value, str):
        for url in URL.findall(value):
            host = urlparse(url).hostname
            if host and host != "localhost" and not re.match(r"^[\d.]+$|^\[", host):
                yield host


def severity(text, kind):
    if len(text) <= 3 or text.lower() in GENERIC:
        return "WARN"
    if kind in NEVER_CLEARED:
        return "BLOCK"
    if kind == "branch" and not re.search(r"[/_-]", text):
        return "WARN"
    return "BLOCK"


def framework_paths(ctx):
    paths = set()
    base = ctx.get("framework_dir")
    if not base:
        return paths
    trees = [os.path.join(base, "skeleton")]
    modules = os.path.join(base, "modules")
    if os.path.isdir(modules):
        trees += [os.path.join(modules, m, "files") for m in sorted(os.listdir(modules))]
    for tree in trees:
        for folder, _, files in os.walk(tree):
            for name in files:
                paths.add(os.path.relpath(os.path.join(folder, name), tree).replace(os.sep, "/"))
    return paths


def repo_url_path(url, ctx):
    """The repository a code-host URL names, or None when it names no repository."""
    parsed = urlparse(url)
    host = (parsed.hostname or "").lower()
    if host not in CODE_HOSTS and host != (ctx.get("host") or ""):
        return None
    path = parsed.path.split("/-/", 1)[0]
    segments = [s for s in path.split("/") if s]
    if len(segments) < 2 or (host == "github.com" and segments[0].lower() in GITHUB_RESERVED):
        return None
    if host == "github.com" or host == "bitbucket.org":
        segments = segments[:2]
    return "/".join(segments)


def check(draft_path, root, allow):
    ctx = context(root)
    targets = {(ctx.get("repo") or "").lower(), UPSTREAM} - {""}
    text = read_text(draft_path)
    if not text:
        print(f"check_report: can't read {draft_path}, or it's empty", file=sys.stderr)
        return 2
    allowed = {a.lower() for a in allow}
    project_files = git(root, "ls-files").splitlines()
    framework = framework_paths(ctx)

    patterns = [(re.compile(r"(?<!\w)" + re.escape(ident) + r"(?!\w)", re.I), ident, kind)
                for ident, kind in identifiers(root, ctx)]
    hits = []
    for number, line in enumerate(text.splitlines(), 1):
        for pattern, ident, kind in patterns:
            for match in pattern.finditer(line):
                hits.append((severity(ident, kind), kind, number, match.group(0)))
        for match in EMAIL.finditer(line):
            hits.append(("BLOCK", "email", number, match.group(0)))
        for match in HOME_PATH.finditer(line):
            hits.append(("BLOCK", "home-path", number, match.group(0)))
        for match in REPO_REF.finditer(line):
            if match.group(1).lower() not in targets:
                hits.append(("BLOCK", "repo-ref", number, match.group(0)))
        for match in URL.finditer(line):
            url = match.group(0).rstrip(".,;:")
            repo = repo_url_path(url, ctx)
            if repo is None:
                hits.append(("WARN", "url", number, url))
            elif repo.lower() not in targets:
                hits.append(("BLOCK", "repo-ref", number, url))
        for match in PATH.finditer(URL.sub(" ", line)):
            token = match.group(1).strip(".")
            if "/" not in token and "." not in token:
                continue
            owned = [f for f in project_files if f == token or f.endswith("/" + token)]
            if owned and not any(f in framework or f.startswith(MACHINERY) for f in owned):
                hits.append(("WARN", "path", number, token))

    report, seen = [], set()
    for level, kind, number, found in hits:
        if (kind, number, found.lower()) in seen:
            continue
        seen.add((kind, number, found.lower()))
        note = ""
        if level == "BLOCK" and any(a in found.lower() for a in allowed):
            if kind in NEVER_CLEARED:
                note = "  (can't be allowed)"
            else:
                level, note = "WARN", "  (allowed)"
        report.append((level, kind, number, found, note))

    report.sort(key=lambda r: (r[0] != "BLOCK", r[2]))
    for level, kind, number, found, note in report:
        print(f"{level:<6} {kind:<13} line {number}: {found}{note}")
    blocked = [r for r in report if r[0] == "BLOCK"]
    clearable = [r for r in blocked if r[1] not in NEVER_CLEARED]
    warnings = len(report) - len(blocked)
    print(f"check_report: {len(blocked)} blocked ({len(clearable)} can be cleared with --allow), "
          f"{warnings} warning{'s' if warnings != 1 else ''}")
    return 1 if blocked else 0


def main(argv):
    if len(argv) >= 1 and argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    if argv[:1] == ["context"] and len(argv) <= 2:
        print(json.dumps(context(argv[1] if len(argv) == 2 else "."), indent=2))
        return 0
    if argv[:1] == ["check"] and len(argv) >= 2:
        args, allow = [], []
        rest = argv[1:]
        while rest:
            item = rest.pop(0)
            if item == "--allow" and rest:
                allow.append(rest.pop(0))
            elif item.startswith("--allow="):
                allow.append(item.split("=", 1)[1])
            else:
                args.append(item)
        if 1 <= len(args) <= 2:
            return check(args[0], args[1] if len(args) == 2 else ".", allow)
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
