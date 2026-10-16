#!/usr/bin/env python3
"""Measure the time agent sessions spent on a project, per day and per branch, from local evidence.

Reads Claude Code's transcripts under ~/.claude/projects/<project>/ (subagents count with their
session) and the project's git log. Nothing leaves the machine. A session's time is its blocks of
activity: events closer than --gap minutes apart. Where sessions overlap, the overlap is split
evenly between them, so no minute counts twice. Python 3 standard library only.

Usage: time_report.py [project-path] [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--task TEXT]
                      [--gap 15] [--author EMAIL] [--worktrees] [--json]
                      [--projects-dir ~/.claude/projects]
"""
import argparse
import collections
import datetime
import glob
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "cost-report"))
from session_cost import first_prompt, parse_time, project_dirs  # noqa: E402

SECRET = re.compile(
    r"gh[pousr]_\w+|github_pat_\w+|glpat-[\w-]+|sk-[\w-]{10,}|xox[abp]-[\w-]+|AIza[\w-]{20,}"
    r"|(?:token|password|secret|api[_-]?key)\s*[:=]\s*\S+", re.I)


def label(text, width=60):
    return SECRET.sub("[secret]", text)[:width]


def read_sessions(dirs, start, end):
    sessions = collections.defaultdict(lambda: {"stamps": [], "prompts": [], "branches": collections.Counter()})
    for directory in dirs:
        files = glob.glob(os.path.join(directory, "*.jsonl")) + \
            glob.glob(os.path.join(directory, "*", "subagents", "*.jsonl"))
        for path in files:
            relative = os.path.relpath(path, directory)
            key = (os.path.basename(directory), relative.split(os.sep)[0].removesuffix(".jsonl"))
            main = os.sep not in relative
            for line in open(path, encoding="utf-8", errors="replace"):
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                when = parse_time(event.get("timestamp"))
                if not when:
                    continue
                when = when.astimezone()
                if not start <= when < end:
                    continue
                session = sessions[key]
                session["stamps"].append(when)
                if main and event.get("gitBranch"):
                    session["branches"][event["gitBranch"]] += 1
                if main and event.get("type") == "user" and not event.get("isSidechain"):
                    prompt = first_prompt(event)
                    if prompt:
                        session["prompts"].append((when, prompt))
    return sessions


def blocks_of(stamps, gap):
    stamps = sorted(stamps)
    blocks, first, last = [], stamps[0], stamps[0]
    for when in stamps[1:]:
        if when - last > gap:
            blocks.append((first, last))
            first = when
        last = when
    blocks.append((first, last))
    return blocks


def allocate(session_blocks):
    """Seconds per (session, day), with overlapping time split evenly between the sessions."""
    events = sorted((when, delta, key) for key, blocks in session_blocks.items()
                    for a, b in blocks if b > a for when, delta in ((a, 1), (b, -1)))
    live, credit, previous = collections.Counter(), collections.Counter(), None
    for when, delta, key in events:
        if previous is not None and when > previous:
            running = [k for k, n in live.items() if n > 0]
            for k in running:
                credit[(k, previous.date())] += (when - previous).total_seconds() / len(running)
        live[key] += delta
        previous = when
    return credit


def commits(project, author, start, end):
    out = subprocess.run(
        ["git", "-C", project, "log", "--all", f"--author={author}", f"--since={start.isoformat()}",
         f"--until={end.isoformat()}", "--format=%aI|%s"],
        capture_output=True, text=True).stdout
    rows = []
    for line in out.splitlines():
        when, subject = line.split("|", 1)
        rows.append((datetime.datetime.fromisoformat(when).astimezone(), subject))
    return sorted(rows)


def transcript_dirs(projects_dir, project, worktrees):
    """The project's transcript folders, plus, with worktrees, those of every worktree git lists."""
    paths = [project]
    if worktrees:
        out = subprocess.run(["git", "-C", project, "worktree", "list", "--porcelain"],
                             capture_output=True, text=True).stdout
        paths += [line[len("worktree "):] for line in out.splitlines() if line.startswith("worktree ")]
    dirs = []
    for path in paths:
        dirs += [d for d in project_dirs(projects_dir, path, False) if d not in dirs]
    return sorted(dirs)


def minutes(seconds):
    return f"{seconds / 60:.0f} min"


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("project", nargs="?", default=os.getcwd())
    today = datetime.date.today().isoformat()
    parser.add_argument("--from", dest="start", default=today, help="first day, YYYY-MM-DD (default today)")
    parser.add_argument("--to", dest="end", help="last day, YYYY-MM-DD (default: the --from day)")
    parser.add_argument("--task", help="only sessions whose branch or prompts mention this text (a task ID)")
    parser.add_argument("--gap", type=int, default=15, help="minutes without events that end a block")
    parser.add_argument("--author", help="git author for the commits (default: the project's user.email)")
    parser.add_argument("--worktrees", action="store_true", help="also every worktree `git worktree list` shows")
    parser.add_argument("--json", action="store_true", help="print the per-session numbers as JSON")
    parser.add_argument("--projects-dir", default=os.path.join(
        os.environ.get("CLAUDE_CONFIG_DIR", os.path.expanduser("~/.claude")), "projects"))
    args = parser.parse_args()

    local = datetime.datetime.now().astimezone().tzinfo
    start = datetime.datetime.fromisoformat(args.start).replace(tzinfo=local)
    end = datetime.datetime.fromisoformat(args.end or args.start).replace(tzinfo=local) + datetime.timedelta(days=1)
    dirs = transcript_dirs(args.projects_dir, args.project, args.worktrees)
    if not dirs:
        sys.exit(f"No Claude Code transcripts for {os.path.abspath(args.project)} under {args.projects_dir}")

    sessions = {k: v for k, v in read_sessions(dirs, start, end).items() if v["stamps"]}
    if args.task:
        needle = args.task.lower()
        sessions = {k: v for k, v in sessions.items()
                    if any(needle in b.lower() for b in v["branches"]) or any(needle in p.lower() for _, p in v["prompts"])}
    if not sessions:
        sys.exit("No session activity in that window" + (f" mentioning {args.task!r}." if args.task else "."))
    gap = datetime.timedelta(minutes=args.gap)
    session_blocks = {k: blocks_of(v["stamps"], gap) for k, v in sessions.items()}
    credit = allocate(session_blocks)
    branch = {k: (v["branches"].most_common(1)[0][0] if v["branches"] else "-") for k, v in sessions.items()}

    if args.json:
        rows = [{"session": k[1][:8], "folder": k[0], "day": day.isoformat(), "branch": branch[k],
                 "minutes": round(seconds / 60, 1)} for (k, day), seconds in sorted(credit.items(), key=lambda i: i[0][1])]
        json.dump(rows, sys.stdout, indent=1)
        print()
        return

    print(f"# Agent time: {os.path.basename(os.path.abspath(args.project))}, {args.start}"
          f"{' to ' + args.end if args.end and args.end != args.start else ''}"
          f"{' · task ' + args.task if args.task else ''}")
    print(f"Folders: {', '.join(os.path.basename(d) for d in dirs)}")
    print(f"Blocks end after {args.gap} min without events; overlapping sessions share their time.\n")

    print("## Sessions per day")
    for day in sorted({d for _, d in credit}):
        keys = sorted((k for k, d in credit if d == day), key=lambda k: -credit[(k, day)])
        print(f"{day:%a %Y-%m-%d}  {minutes(sum(credit[(k, day)] for k in keys))}")
        for k in keys:
            if credit[(k, day)] < 60:
                continue
            print(f"  {k[1][:8]} {minutes(credit[(k, day)]):>7}  {branch[k]}")
            for a, b in (block for block in session_blocks[k] if block[0].date() == day):
                prompt = next((p for when, p in sessions[k]["prompts"] if a <= when <= b), None)
                print(f"      {a:%H:%M}-{b:%H:%M}" + (f'  "{label(prompt)}"' if prompt else ""))

    print("\n## Per branch")
    per_branch = collections.Counter()
    for (k, _), seconds in credit.items():
        per_branch[branch[k]] += seconds
    for name, seconds in per_branch.most_common():
        print(f"  {minutes(seconds):>8}  {name}")

    author = args.author or subprocess.run(["git", "-C", args.project, "config", "user.email"],
                                           capture_output=True, text=True).stdout.strip()
    rows = commits(args.project, author, start, end) if author else []
    print(f"\n## Commits by {author or 'nobody (no git user.email)'}")
    by_day = collections.defaultdict(list)
    for when, subject in rows:
        by_day[when.date()].append((when, subject))
    for day, items in sorted(by_day.items()):
        print(f"{day:%a %Y-%m-%d}  {len(items)} commits {items[0][0]:%H:%M}-{items[-1][0]:%H:%M}")
        for when, subject in items:
            print(f"  {when:%H:%M} {label(subject, 72)}")
    if not rows:
        print("  none in the window")


if __name__ == "__main__":
    main()
