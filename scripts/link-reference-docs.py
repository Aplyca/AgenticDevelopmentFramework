#!/usr/bin/env python3
"""Point a project's links to the framework's reference docs at the copy its install uses.

The reference docs (decision 0019) are the framework's own: generic, and never edited by a project. A
packaged project reads them from the adf plugin and commits none of them, so its files link
them at the release it pins, on GitHub. A committed project keeps them in docs/ and links them there.
/adf:adopt and /adf:upgrade run this from the framework at the release they install.

Usage:
  link-reference-docs.py <repo> --packaged vX.Y.Z   link the release on GitHub (and move an older pin)
  link-reference-docs.py <repo> --committed         link docs/ in the project

It rewrites the project's copies of the skeleton files that name a reference doc, then lists every
other file that still names one the other way, and the reference docs the project still has in docs/.
It deletes nothing.
"""
import argparse
import os
import re
import sys

FRAMEWORK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = sorted(f[:-3] for f in os.listdir(os.path.join(FRAMEWORK, "plugins", "adf", "docs")) if f.endswith(".md"))
NAMES = "|".join(map(re.escape, DOCS))
TEXT_FILES = (".md", ".mdc")
SKIP_DIRS = {".git", "node_modules"}

# Local: `docs/X.md`, [text](docs/X.md#anchor) from any folder, and a bare docs/X.md.
LOCAL_CODE = re.compile(r"`docs/(" + NAMES + r")\.md`")
LOCAL_LINK = re.compile(r"\[([^\]\n]*)\]\((?:\./|(?:\.\./)+)?docs/(" + NAMES + r")\.md(#[^)\s]*)?\)")
LOCAL_BARE = re.compile(r"(?<![\w/.-])docs/(" + NAMES + r")\.md")
# On GitHub, at any release: the same three shapes, in either home the docs have had.
URL = r"https://github\.com/aplyca/AgenticDevelopmentFramework/blob/[^/\s)]+/(?:skeleton|plugins/adf)/docs/(" + NAMES + r")\.md"
RELEASE_CODE = re.compile(r"\[`(" + NAMES + r")\.md`\]\(" + URL + r"\)", re.I)
RELEASE_LINK = re.compile(r"\[([^\]\n]*)\]\(" + URL + r"(#[^)\s]*)?\)", re.I)
RELEASE_BARE = re.compile(URL, re.I)


def release_url(tag, name):
    """The doc at a release. From v2.0.0 the plugin is its only home (decision 0028); before, the
    skeleton kept the source in skeleton/docs/."""
    folder = "plugins/adf/docs" if int(tag[1:].split(".")[0]) >= 2 else "skeleton/docs"
    return f"https://github.com/aplyca/AgenticDevelopmentFramework/blob/{tag}/{folder}/{name}.md"


def to_release(text, tag):
    url = lambda name: release_url(tag, name)
    text = RELEASE_BARE.sub(lambda m: url(m.group(1)), text)  # an older pin moves to this one
    text = LOCAL_CODE.sub(lambda m: f"[`{m.group(1)}.md`]({url(m.group(1))})", text)
    text = LOCAL_LINK.sub(
        lambda m: f"[{m.group(1).replace(f'docs/{m.group(2)}.md', f'{m.group(2)}.md')}]({url(m.group(2))}{m.group(3) or ''})",
        text,
    )
    return LOCAL_BARE.sub(lambda m: url(m.group(1)), text)


def to_local(text, folder):
    path = lambda name: os.path.relpath(os.path.join("docs", name + ".md"), folder or ".")
    text = RELEASE_CODE.sub(lambda m: f"`docs/{m.group(1)}.md`", text)

    def link(m):
        label = re.sub(r"(?<![\w/.-])" + re.escape(m.group(2)) + r"\.md", f"docs/{m.group(2)}.md", m.group(1))
        return f"[{label}]({path(m.group(2))}{m.group(3) or ''})"

    text = RELEASE_LINK.sub(link, text)
    return RELEASE_BARE.sub(lambda m: f"docs/{m.group(1)}.md", text)


def text_files(top, skip=()):
    for directory, dirs, files in os.walk(top):
        rel_dir = os.path.relpath(directory, top)
        dirs[:] = sorted(
            d for d in dirs
            if d not in SKIP_DIRS and os.path.normpath(os.path.join(rel_dir, d)) not in skip
        )
        for file in sorted(files):
            if file.endswith(TEXT_FILES):
                yield os.path.normpath(os.path.join(rel_dir, file))


def skeleton_files():
    """The skeleton's files that name a reference doc, its committed rules included. The machinery
    isn't among them: a packaged project takes it from the plugin, and a committed one's copies, which
    scripts/build-committed.py writes, link docs/ in the project."""
    skeleton = os.path.join(FRAMEWORK, "skeleton")
    for rel in text_files(skeleton):
        with open(os.path.join(skeleton, rel), encoding="utf-8") as f:
            if LOCAL_BARE.search(f.read()):
                yield rel


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("repo")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--packaged", metavar="TAG", help="the release the project pins, e.g. v1.2.0")
    mode.add_argument("--committed", action="store_true")
    args = parser.parse_args()
    if args.packaged and not re.fullmatch(r"v\d+\.\d+\.\d+", args.packaged):
        sys.exit(f"--packaged takes a release tag such as v1.2.0, not {args.packaged!r}")

    repo = os.path.abspath(args.repo)
    rewritten = []
    for rel in skeleton_files():
        path = os.path.join(repo, rel)
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as f:
            before = f.read()
        after = to_release(before, args.packaged) if args.packaged else to_local(before, os.path.dirname(rel))
        if after != before:
            with open(path, "w", encoding="utf-8") as f:
                f.write(after)
            rewritten.append(rel)
    print(f"Rewrote the reference-doc links in {len(rewritten)} file(s): {', '.join(rewritten) or 'none'}")

    stale = RELEASE_BARE if args.committed else LOCAL_BARE
    mentions = []
    for rel in text_files(repo, skip={os.path.join(".claude", "worktrees")}):
        if rel in rewritten:
            continue
        with open(os.path.join(repo, rel), encoding="utf-8", errors="replace") as f:
            for number, line in enumerate(f, 1):
                if stale.search(line) and not (args.packaged and rel.startswith("docs" + os.sep) and rel[5:-3] in DOCS):
                    mentions.append(f"  {rel}:{number}: {line.strip()[:160]}")
    if mentions:
        print("Other files still naming a reference doc the " + ("packaged" if args.committed else "committed")
              + " way — update them by hand if they should follow:")
        print("\n".join(mentions))

    present = [f"docs/{name}.md" for name in DOCS if os.path.isfile(os.path.join(repo, "docs", name + ".md"))]
    if args.packaged and present:
        print("Still in docs/ (a packaged project reads the plugin's copy): " + ", ".join(present))
    if args.committed and len(present) < len(DOCS):
        print("Missing from docs/ (scripts/build-committed.py writes them): "
              + ", ".join(f"docs/{name}.md" for name in DOCS if f"docs/{name}.md" not in present))


if __name__ == "__main__":
    main()
