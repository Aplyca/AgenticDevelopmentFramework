#!/usr/bin/env python3
"""Summarize what Claude Code sessions on a project cost, from Claude Code's local transcripts.

Reads ~/.claude/projects/<project>/*.jsonl (nothing leaves the machine) and reports, per session:
API calls, active time, context size, tokens, an estimated cost at list prices — and, for sessions
on Opus or Fable, what the same tokens cost on Sonnet — and flags for the patterns that make sessions
expensive. Python 3 standard library only.

Usage: session_cost.py [project-path] [--days 30] [--top 15] [--siblings] [--json]
                       [--projects-dir ~/.claude/projects]
"""
import argparse
import collections
import datetime
import glob
import json
import os
import re
import statistics
import sys

# USD per million tokens — input, output, cache read, cache write — list prices, September 2026.
# Keep in step with docs/COST-MODEL.md; the report is an estimate, not an invoice.
PRICES = {
    "haiku": (1.00, 5.00, 0.10, 1.25),
    "sonnet": (2.00, 10.00, 0.20, 2.50),
    "opus": (4.00, 20.00, 0.20, 5.00),
    "fable": (10.00, 50.00, 1.00, 12.50),
}
CACHE_LIFETIME = 300  # seconds; a longer pause means the next call writes the context again
IDLE_CAP = 300        # gaps longer than this don't count as active time
BROWSER = re.compile(r"(browser|chrome|playwright|puppeteer)", re.I)


def tier(model):
    for name in PRICES:
        if name in (model or ""):
            return name
    return "sonnet"


def parse_time(value):
    try:
        return datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (AttributeError, ValueError):
        return None


def first_prompt(event):
    content = event.get("message", {}).get("content")
    if isinstance(content, list):
        content = " ".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
    if not isinstance(content, str):
        return None
    text = content.strip()
    if not text or text.startswith("<"):
        return None
    return " ".join(text.split())


def analyze(path):
    calls = {}
    times, assistant_times = [], []
    tools = collections.Counter()
    edits = collections.Counter()
    title = prompt = None
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            event = json.loads(line)
        except ValueError:
            continue
        when = parse_time(event.get("timestamp"))
        if when:
            times.append(when)
        kind = event.get("type")
        if kind in ("custom-title", "ai-title"):
            title = event.get("customTitle") or event.get("aiTitle") or event.get("title") or title
        if kind == "user" and prompt is None and not event.get("isSidechain"):
            prompt = first_prompt(event)
        if kind != "assistant":
            continue
        message = event.get("message", {})
        if message.get("model") in (None, "<synthetic>"):
            continue
        key = message.get("id") or event.get("uuid")
        if key not in calls and when:
            assistant_times.append(when)
        calls[key] = (message.get("model"), message.get("usage") or {})
        for block in message.get("content") or []:
            if isinstance(block, dict) and block.get("type") == "tool_use":
                name = block.get("name") or ""
                tools[name] += 1
                if name in ("Edit", "Write", "MultiEdit"):
                    file_path = (block.get("input") or {}).get("file_path", "")
                    edits["specs" if "/specs/" in file_path else "other"] += 1
    if not calls:
        return None

    totals = collections.Counter()
    contexts, models = [], collections.Counter()
    cost = on_sonnet = 0.0
    for model, usage in calls.values():
        price = PRICES[tier(model)]
        # The same tokens at Sonnet's prices — for calls above Sonnet only; cheaper calls keep theirs.
        sonnet = PRICES["sonnet"] if tier(model) in ("opus", "fable") else price
        fresh = usage.get("input_tokens", 0)
        read = usage.get("cache_read_input_tokens", 0)
        write = usage.get("cache_creation_input_tokens", 0)
        out = usage.get("output_tokens", 0)
        totals.update(input=fresh, read=read, write=write, output=out)
        contexts.append(fresh + read + write)
        models[tier(model)] += 1
        cost += (fresh * price[0] + out * price[1] + read * price[2] + write * price[3]) / 1e6
        on_sonnet += (fresh * sonnet[0] + out * sonnet[1] + read * sonnet[2] + write * sonnet[3]) / 1e6

    times.sort()
    active = sum(min((b - a).total_seconds(), IDLE_CAP) for a, b in zip(times, times[1:]))
    assistant_times.sort()
    long_pauses = sum(1 for a, b in zip(assistant_times, assistant_times[1:]) if (b - a).total_seconds() > CACHE_LIFETIME)
    browser_calls = sum(n for name, n in tools.items() if BROWSER.search(name))
    mean_context = sum(contexts) / len(contexts)

    flags = []
    if mean_context > 150_000:
        flags.append("long-context")
    if long_pauses >= 3:
        flags.append(f"pauses:{long_pauses}")
    if browser_calls > 30:
        flags.append(f"browser:{browser_calls}")
    if edits["specs"] >= 4 and edits["specs"] >= edits["other"] and edits["other"] <= 5:
        flags.append("spec-heavy")

    return {
        "session": os.path.basename(path)[:8],
        "date": times[0].date().isoformat() if times else "",
        "title": (title or prompt or "")[:60],
        "calls": len(calls),
        "active_min": round(active / 60, 1),
        "context_start_k": round(contexts[0] / 1000, 1),
        "context_mean_k": round(mean_context / 1000, 1),
        "output_k": round(totals["output"] / 1000, 1),
        "cache_read_m": round(totals["read"] / 1e6, 2),
        "cache_write_k": round(totals["write"] / 1000, 1),
        "cost": round(cost, 2),
        "cost_on_sonnet": round(on_sonnet, 2),
        "share": {
            "cache_read": totals["read"], "cache_write": totals["write"],
            "output": totals["output"], "input": totals["input"],
        },
        "model": ",".join(name for name, _ in models.most_common(2)),
        "flags": flags,
    }


def project_dirs(projects_dir, project, siblings):
    slug = re.sub(r"[^A-Za-z0-9]", "-", os.path.abspath(project))
    dirs = [d for d in glob.glob(os.path.join(projects_dir, "*"))
            if os.path.basename(d) == slug or os.path.basename(d).startswith(slug + "--")]
    if siblings:
        parent = re.sub(r"[^A-Za-z0-9]", "-", os.path.dirname(os.path.abspath(project)))
        dirs += [d for d in glob.glob(os.path.join(projects_dir, parent + "-*")) if d not in dirs]
    return sorted(dirs)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("project", nargs="?", default=os.getcwd())
    parser.add_argument("--days", type=int, default=30, help="sessions active in the last N days (0 = all)")
    parser.add_argument("--top", type=int, default=15, help="sessions to list, most expensive first")
    parser.add_argument("--siblings", action="store_true", help="also sibling worktrees (../<type>-<slug>)")
    parser.add_argument("--json", action="store_true", help="print every session as JSON")
    parser.add_argument("--projects-dir", default=os.path.join(
        os.environ.get("CLAUDE_CONFIG_DIR", os.path.expanduser("~/.claude")), "projects"))
    args = parser.parse_args()

    dirs = project_dirs(args.projects_dir, args.project, args.siblings)
    if not dirs:
        sys.exit(f"No Claude Code transcripts for {os.path.abspath(args.project)} under {args.projects_dir}")
    cutoff = None
    if args.days:
        cutoff = datetime.datetime.now().timestamp() - args.days * 86400
    sessions = []
    for directory in dirs:
        for path in glob.glob(os.path.join(directory, "*.jsonl")):
            if cutoff and os.path.getmtime(path) < cutoff:
                continue
            result = analyze(path)
            if result:
                sessions.append(result)
    if not sessions:
        sys.exit("No sessions with model calls in that window.")

    if args.json:
        json.dump(sessions, sys.stdout, indent=1)
        print()
        return

    sessions.sort(key=lambda s: s["cost"], reverse=True)
    total = sum(s["cost"] for s in sessions)
    calls = sum(s["calls"] for s in sessions)
    share = collections.Counter()
    for s in sessions:
        share.update(s["share"])
    print(f"{len(sessions)} sessions · {calls} calls · ≈ ${total:.2f} at list prices "
          f"(median ${statistics.median(s['cost'] / s['calls'] for s in sessions):.3f} per call)")
    print(f"Folders: {', '.join(os.path.basename(d) for d in dirs)}\n")
    print(f"{'date':<11}{'calls':>6}{'active':>8}{'ctx avg':>9}{'cost':>9}{'on sonnet':>11}  {'model':<12}{'flags':<28}title")
    for s in sessions[: args.top]:
        sonnet = f"≈{s['cost_on_sonnet']:.2f}" if s["cost_on_sonnet"] < s["cost"] else "-"
        print(f"{s['date']:<11}{s['calls']:>6}{s['active_min']:>7.0f}m{s['context_mean_k']:>8.0f}k"
              f"{s['cost']:>9.2f}{sonnet:>11}  {s['model']:<12}{' '.join(s['flags']):<28}{s['title']}")
    if len(sessions) > args.top:
        print(f"… {len(sessions) - args.top} cheaper sessions not listed (--top)")
    print()
    for low, high in ((0, 30), (30, 100), (100, 10**9)):
        band = [s for s in sessions if low <= s["calls"] < high]
        if band:
            label = f"{low}+" if high == 10**9 else f"{low}–{high - 1}"
            print(f"{label:>7} calls: {len(band):>3} sessions, median ${statistics.median(s['cost'] for s in band):.2f}, "
                  f"median {statistics.median(s['active_min'] for s in band):.0f} min active")
    above = [s for s in sessions if s["cost_on_sonnet"] < s["cost"]]
    if above:
        spent = sum(s["cost"] for s in above)
        saved = spent - sum(s["cost_on_sonnet"] for s in above)
        print(f"\nModel: {len(above)} session{'s' * (len(above) != 1)} ran above Sonnet (≈ ${spent:.2f}); the same tokens on "
              f"Sonnet ≈ ${spent - saved:.2f}, {saved / spent:.0%} less.")
        print("  Sonnet suits work with a clear spec and a way to check it — the fast and careful lanes, bug")
        print("  fixes, reviews, an approved plan; Opus, the full lane's spec and plan (docs/COST-MODEL.md).")
        print("  Cache reads cost the same on both: in long sessions, context size matters as much as the model.")
    flagged = collections.Counter(f.split(":")[0] for s in sessions for f in s["flags"])
    if flagged:
        print("\nFlags: " + ", ".join(f"{name} ×{n}" for name, n in flagged.most_common()))
        print("  long-context  average call carried >150k tokens — one task per session, /clear between tasks")
        print("  pauses        3+ waits longer than the cache lifetime — each one re-wrote the whole context")
        print("  browser       >30 browser calls — prefer tests; leave visual QC to the human check")
        print("  spec-heavy    spec edits outnumber code edits on a small change — was the full lane needed?")


if __name__ == "__main__":
    main()
