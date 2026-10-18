#!/usr/bin/env python3
"""Measure the time a task's Claude Code sessions were active, by day and working block.

Reads ~/.claude/projects/<project>/*.jsonl for the main checkout and each of its git worktrees
(nothing leaves the machine). A session belongs to the task when any of its events ran on the task's
branch; its events on the branch, on the base branch, or on none count — so the triage before the
move into the worktree counts, and work on another task's branch doesn't. Each gap between two
counted events is active up to IDLE_CAP; the task's sessions are merged, so a minute two of them
share counts once. Blocks are active stretches with no break longer than BLOCK_GAP. Days are local.
Python 3 standard library only.

Usage: session_time.py <branch> [project-path] [--base main] [--since 2026-10-14T13:00]
                       [--siblings] [--json] [--projects-dir ~/.claude/projects]
"""
import argparse
import datetime
import glob
import json
import os
import re
import subprocess
import sys

IDLE_CAP = 300    # seconds; a longer gap counts as this much (reading the reply), as in /cost-report
BLOCK_GAP = 1800  # seconds; a longer break between active stretches starts a new block


def parse_time(value):
    try:
        return datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (AttributeError, ValueError):
        return None


def slug(path):
    return re.sub(r"[^A-Za-z0-9]", "-", os.path.abspath(path))


def worktrees(project):
    try:
        out = subprocess.run(["git", "-C", project, "worktree", "list", "--porcelain"],
                             capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return [project]
    paths = [line[len("worktree "):] for line in out.splitlines() if line.startswith("worktree ")]
    return paths or [project]


def project_dirs(projects_dir, project, siblings):
    dirs = set()
    for path in worktrees(project):
        for d in glob.glob(os.path.join(projects_dir, "*")):
            name = os.path.basename(d)
            if name == slug(path) or name.startswith(slug(path) + "--"):
                dirs.add(d)
    if siblings:
        parent = slug(os.path.dirname(os.path.abspath(project)))
        dirs.update(glob.glob(os.path.join(projects_dir, parent + "-*")))
    return sorted(dirs)


def session_times(path, branch, base):
    """The timestamps of a session's counted events, or [] when the session never ran on the branch."""
    events = []
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            event = json.loads(line)
        except ValueError:
            continue
        when = parse_time(event.get("timestamp"))
        if when and when.tzinfo:
            events.append((when, event.get("gitBranch") or None))
    events.sort(key=lambda e: e[0])
    on_branch = [i for i, (_, b) in enumerate(events) if b == branch]
    if not on_branch:
        return []
    first, last = on_branch[0], on_branch[-1]
    # Between the first and last event on the branch: the branch's events and those with none.
    counted = [t for t, b in events[first:last + 1] if b in (branch, None)]
    # Before it, the triage that led to the move: the run on the base branch (or none) just before,
    # back to the first break longer than BLOCK_GAP. Earlier work in the session was another task.
    i = first
    while i > 0 and events[i - 1][1] in (base, None) and \
            (events[i][0] - events[i - 1][0]).total_seconds() <= BLOCK_GAP:
        i -= 1
        counted.append(events[i][0])
    return sorted(counted)


def intervals(times):
    return [(a, a + datetime.timedelta(seconds=min((b - a).total_seconds(), IDLE_CAP)))
            for a, b in zip(times, times[1:]) if b > a]


def union(spans):
    merged = []
    for start, end in sorted(spans):
        if merged and start <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], end))
        else:
            merged.append((start, end))
    return merged


def blocks(spans):
    out = []
    for start, end in spans:
        if out and (start - out[-1]["end"]).total_seconds() <= BLOCK_GAP:
            out[-1]["end"] = end
            out[-1]["active"] += (end - start).total_seconds()
        else:
            out.append({"start": start, "end": end, "active": (end - start).total_seconds()})
    return out


def minutes(seconds):
    return int(round(seconds / 60))


def duration(mins):
    return f"{mins // 60}h {mins % 60:02d}m" if mins >= 60 else f"{mins}m"


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("branch", help="the task's branch, e.g. feat/newsletter-signup")
    parser.add_argument("project", nargs="?", default=os.getcwd())
    parser.add_argument("--base", default="main", help="the base branch, where triage runs before the move")
    parser.add_argument("--since", help="count only time after this local date-time (the last entry logged)")
    parser.add_argument("--siblings", action="store_true", help="also every folder beside the project")
    parser.add_argument("--json", action="store_true", help="print the days and blocks as JSON")
    parser.add_argument("--projects-dir", default=os.path.join(
        os.environ.get("CLAUDE_CONFIG_DIR", os.path.expanduser("~/.claude")), "projects"))
    args = parser.parse_args()

    dirs = project_dirs(args.projects_dir, args.project, args.siblings)
    if not dirs:
        sys.exit(f"No Claude Code transcripts for {os.path.abspath(args.project)} under {args.projects_dir}")
    spans, sessions = [], []
    for directory in dirs:
        for path in glob.glob(os.path.join(directory, "*.jsonl")):
            times = session_times(path, args.branch, args.base)
            if times:
                sessions.append(os.path.basename(path)[:8])
                spans += intervals(times)
    if not sessions:
        sys.exit(f"No session ran on {args.branch} in {', '.join(os.path.basename(d) for d in dirs)}")

    local = [(a.astimezone(), b.astimezone()) for a, b in union(spans)]
    if args.since:
        since = datetime.datetime.fromisoformat(args.since)
        since = since.astimezone() if since.tzinfo is None else since
        local = [(max(a, since), b) for a, b in local if b > since]
    days = {}
    for block in blocks(local):
        days.setdefault(block["start"].date().isoformat(), []).append(block)
    report = [{"date": date, "active_min": sum(minutes(b["active"]) for b in day),
               "blocks": [{"start": b["start"].isoformat(timespec="minutes"),
                           "end": b["end"].isoformat(timespec="minutes"),
                           "active_min": minutes(b["active"])} for b in day]}
              for date, day in sorted(days.items())]
    total = sum(d["active_min"] for d in report)

    if args.json:
        json.dump({"branch": args.branch, "sessions": sorted(sessions), "total_min": total, "days": report},
                  sys.stdout, indent=1)
        print()
        return
    print(f"{args.branch} · {len(sessions)} session{'s' * (len(sessions) != 1)} · "
          f"{duration(total)} active over {len(report)} day{'s' * (len(report) != 1)}"
          + (f" · since {args.since}" if args.since else ""))
    for day in report:
        print(f"\n{day['date']}  {duration(day['active_min'])}")
        for b in day["blocks"]:
            print(f"  {b['start'][11:16]}–{b['end'][11:16]}  {duration(b['active_min']):>7}")


if __name__ == "__main__":
    main()
