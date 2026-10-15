#!/usr/bin/env python3
"""Write the committed install's machinery from the plugins (decision 0028).

The plugins are the source of the framework's skills, agents, workflows, hook scripts, and reference
docs. A committed project keeps its own copies, in the form scripts/forms.py describes: /adopt and
/upgrade run this script to write them, and so does the manual setup in docs/SETUP.md.

Usage:
  build-committed.py <project> [--modules <name,name> | --modules all]
      Writes .claude/skills/, .claude/agents/, .claude/workflows/, .claude/hooks/ (all but config.sh,
      which comes from the skeleton), and docs/'s four reference docs into <project>, with the skills
      of the modules given. A file that already exists is kept and listed, never overwritten: an
      upgrade writes into an empty folder and merges from there.
  build-committed.py --check
      Checks that every carried file survives the round trip — plugin, committed, plugin — unchanged,
      and that the skeleton's .claude/settings.json wires the hooks adf's hooks.json does. Exit 1 on
      the first file that doesn't, with what it should be.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from forms import Machinery  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def check(machinery):
    problems = machinery.round_trip()
    for path, expected in problems[:3]:
        print(f"✘ {path} doesn't survive the round trip. In the plugin form it would read:\n", file=sys.stderr)
        print("\n".join(expected.split("\n")[:40]), file=sys.stderr)
    settings = json.load(open(os.path.join(ROOT, "skeleton", ".claude", "settings.json"), encoding="utf-8"))
    if settings.get("hooks") != machinery.settings_hooks():
        problems.append(("skeleton/.claude/settings.json", "hooks"))
        print("✘ skeleton/.claude/settings.json: its hooks block isn't the one adf's hooks.json wires:\n"
              + json.dumps({"hooks": machinery.settings_hooks()}, indent=2), file=sys.stderr)
    if problems:
        print(f"{len(problems)} file(s) differ between the plugin and committed forms", file=sys.stderr)
        return 1
    print(f"round trip: {len(machinery.committed_files(list(machinery.module_skills)))} files, "
          "every one unchanged; the skeleton's settings wire adf's hooks")
    return 0


def write(machinery, project, modules):
    unknown = [m for m in modules if m not in machinery.module_skills and not os.path.isdir(os.path.join(ROOT, "modules", m))]
    if unknown:
        sys.exit(f"no such module: {', '.join(unknown)}")
    written, kept = 0, []
    for rel, (text, executable) in sorted(machinery.committed_files(modules).items()):
        target = os.path.join(project, rel)
        if os.path.exists(target):
            kept.append(rel)
            continue
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, "w", encoding="utf-8") as f:
            f.write(text)
        os.chmod(target, 0o755 if executable else 0o644)
        written += 1
    print(f"Wrote {written} file(s) into {project}.")
    if kept:
        print(f"Kept {len(kept)} that already existed — merge them by hand: " + ", ".join(kept))


def main(argv):
    machinery = Machinery(ROOT)
    if argv == ["--check"]:
        return check(machinery)
    if not argv or argv[0].startswith("-"):
        print(__doc__, file=sys.stderr)
        return 2
    project, modules = argv[0], []
    if argv[1:2] == ["--modules"] and len(argv) == 3:
        modules = sorted(machinery.module_skills) if argv[2] == "all" else [m for m in argv[2].split(",") if m]
    elif argv[1:]:
        print(__doc__, file=sys.stderr)
        return 2
    write(machinery, project, modules)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
