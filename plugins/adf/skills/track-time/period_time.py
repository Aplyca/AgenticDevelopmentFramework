#!/usr/bin/env python3
"""Measure a day's or a week's Claude Code session time across every task's branch, each minute once.

Finds every branch a session ran on in the period, except the base branch, and measures each one as
session_time.py measures one task: its sessions, with the work before the move, and its minutes by
day and working block. A session that moved off the branch Claude Code generated for its own worktree
(claude/<name>, worktree-<name>) counts for the branch it moved to, not for the generated one. Each
task keeps its full time, as in session_time.py; each day also gets its active time with every
branch's sessions merged, so a minute two tasks shared counts once, and the overlap, which is how
much the branches' times add up to beyond it. Days are local. Python 3 standard library only.

Usage: period_time.py <first-day> [last-day] [--project .] [--base main] [--branch <name>]...
                      [--siblings] [--json] [--projects-dir ~/.claude/projects]
"""
import argparse
import datetime
import glob
import json
import os
import sys

from session_time import (GENERATED_PREFIXES, block_report, blocks, by_day, counted_times,
                          default_projects_dir, duration, intervals, local_spans, minutes,
                          project_dirs, read_events, union)


def task_branches(events, base):
    """The branches a session worked on as tasks: not the base branch, and not the generated branch
    it moved off, whose work counts for the branch it moved to."""
    names = list(dict.fromkeys(b for _, b in events if b and b not in (base, "HEAD")))
    moved = any(not b.startswith(GENERATED_PREFIXES) for b in names)
    return [b for b in names if not (moved and b.startswith(GENERATED_PREFIXES))]


def measure(dirs, base, start, end, only=None):
    """Each branch's spans and sessions in the window [start, end)."""
    spans, sessions = {}, {}
    for directory in dirs:
        for path in glob.glob(os.path.join(directory, "*.jsonl")):
            events = read_events(path)
            # A session's spans lie between its first and last event.
            if not events or events[-1][0] <= start or events[0][0] >= end:
                continue
            for branch in task_branches(events, base):
                if only and branch not in only:
                    continue
                times = counted_times(events, branch, base)
                if times:
                    spans.setdefault(branch, []).extend(intervals(times))
                    sessions.setdefault(branch, set()).add(os.path.basename(path)[:8])
    return spans, sessions


def report(spans, sessions, start, end):
    per_branch = {b: by_day(local_spans(s, start, end)) for b, s in spans.items()}
    per_branch = {b: days for b, days in per_branch.items() if days}
    dates = sorted({date for days in per_branch.values() for date in days})
    days = []
    for date in dates:
        rows = []
        shared = []
        for branch, branch_days in per_branch.items():
            day = branch_days.get(date)
            if not day:
                continue
            rows.append({"branch": branch, "active_min": sum(minutes(b["active"]) for b in day),
                         "blocks": [block_report(b) for b in day]})
            shared += [span for b in day for span in b["spans"]]
        rows.sort(key=lambda r: (r["blocks"][0]["start"], r["branch"]))
        # The day's own time: every branch's spans that day merged, so a shared minute counts once.
        active = sum(minutes(b["active"]) for b in blocks(union(shared)))
        tasks = sum(r["active_min"] for r in rows)
        days.append({"date": date, "active_min": active, "tasks_min": tasks,
                     "overlap_min": max(tasks - active, 0), "branches": rows})
    branches = [{"branch": b, "sessions": sorted(sessions[b]),
                 "active_min": sum(r["active_min"] for d in days for r in d["branches"] if r["branch"] == b)}
                for b in sorted(per_branch)]
    total = sum(d["active_min"] for d in days)
    tasks = sum(d["tasks_min"] for d in days)
    return {"total_min": total, "tasks_min": tasks, "overlap_min": max(tasks - total, 0),
            "branches": branches, "days": days}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("first", help="the period's first day, e.g. 2026-10-12")
    parser.add_argument("last", nargs="?", help="its last day (default: the first, for one day)")
    parser.add_argument("--project", default=os.getcwd(), help="any checkout of the repository")
    parser.add_argument("--base", default="main", help="the base branch, where triage runs before the move")
    parser.add_argument("--branch", action="append",
                        help="measure only this branch; repeat it for each task the review keeps")
    parser.add_argument("--siblings", action="store_true", help="also every folder beside the project")
    parser.add_argument("--json", action="store_true", help="print the days and branches as JSON")
    parser.add_argument("--projects-dir", default=default_projects_dir())
    args = parser.parse_args()

    try:
        first = datetime.date.fromisoformat(args.first)
        last = datetime.date.fromisoformat(args.last) if args.last else first
    except ValueError as error:
        sys.exit(f"Days are YYYY-MM-DD: {error}")
    if last < first:
        sys.exit(f"The last day, {last}, comes before the first, {first}")
    start = datetime.datetime.combine(first, datetime.time()).astimezone()
    end = datetime.datetime.combine(last + datetime.timedelta(days=1), datetime.time()).astimezone()

    dirs = project_dirs(args.projects_dir, args.project, args.siblings)
    if not dirs:
        sys.exit(f"No Claude Code transcripts for {os.path.abspath(args.project)} under {args.projects_dir}")
    spans, sessions = measure(dirs, args.base, start, end, set(args.branch or []))
    out = report(spans, sessions, start, end)
    period = str(first) if first == last else f"{first} – {last}"
    if not out["days"]:
        sys.exit(f"No session ran on a task's branch in {period}")

    if args.json:
        json.dump({"first": str(first), "last": str(last), **out}, sys.stdout, indent=1)
        print()
        return
    n, d = len(out["branches"]), len(out["days"])
    print(f"{period} · {n} branch{'es' * (n != 1)} · {duration(out['total_min'])} active over "
          f"{d} day{'s' * (d != 1)}" + overlap(out))
    for day in out["days"]:
        print(f"\n{day['date']}  {duration(day['active_min'])}" + overlap(day))
        width = max(len(r["branch"]) for r in day["branches"])
        for r in day["branches"]:
            spans = ", ".join(f"{b['start'][11:16]}–{b['end'][11:16]}" for b in r["blocks"])
            print(f"  {r['branch']:<{width}}  {duration(r['active_min']):>7}  {spans}")


def overlap(part):
    if not part["overlap_min"]:
        return ""
    return (f" · the branches add up to {duration(part['tasks_min'])}: "
            f"{duration(part['overlap_min'])} ran on more than one at once")


if __name__ == "__main__":
    main()
