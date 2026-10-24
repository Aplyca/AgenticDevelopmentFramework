#!/usr/bin/env bash
#
# Checks an open-pr run from what the stand-ins recorded ($work.events: server starts and requests,
# pushes, gh and docker calls, each with its time), the pull request body gh received, and the
# session's output. Prints ✓ or ✘ per check, then the end state, and stops the servers the run left.
# Usage: inspect.sh <run copy> <session output .jsonl> <case>
#
work="$1" out="$2" case_name="$3"
touch "$work.done"  # a preview still deploying stays down
python3 - "$work" "$out" "$case_name" <<'PY'
import json, re, subprocess, sys
from pathlib import Path
work, out, case = sys.argv[1:]
port, preview_port = Path(work + ".ports").read_text().split()
events = []
for line in Path(work + ".events").read_text().splitlines():
    ts, source, *rest = line.split(" ", 2)
    events.append((float(ts), source, rest[0] if rest else ""))
def first(source, pattern=""):
    return next((ts for ts, s, what in events if s == source and re.search(pattern, what)), None)
def any_(source, pattern=""):
    return first(source, pattern) is not None
body_file = Path(work + ".pr-body.md")
body = body_file.read_text() if body_file.exists() else ""
texts, tools, final = [], [], ""
for raw in open(out):
    try: d = json.loads(raw)
    except ValueError: continue
    if d.get("type") == "assistant":
        for b in d["message"].get("content", []):
            if b.get("type") == "text" and b["text"].strip(): texts.append(b["text"])
            elif b.get("type") == "tool_use": tools.append((b["name"], b.get("input", {})))
    elif d.get("type") == "result":
        final = d.get("result") or ""
def tool_index(match):
    return next((i for i, (n, i_) in enumerate(tools) if match(n, i_)), None)
def bash(pattern):
    return lambda n, i: n == "Bash" and re.search(pattern, i.get("command", ""))
def check(label, ok):
    print(f"- {'✓' if ok else '✘'} {label}")

walk, push, create = first("local", "^GET "), first("push"), first("gh", r"^pr create")
pr_url = "pull/42"
print("### Checks")
if case == "visible-change":
    check("walked the change on the local environment", walk is not None)
    check("walked it before any push", walk is not None and (push is None or walk < push))
    check("pushed the work branch", push is not None)
    check("opened the pull request as a draft", any_("gh", r"^pr create .*--draft"))
    check("opened it after the local walk", create is not None and walk is not None and walk < create)
    check("waited for the preview with gh pr checks", any_("gh", r"^pr checks"))
    check("walked the preview once it deployed", any_("preview", "^GET "))
    check("the preview walk was read-only — no POST", not any_("preview", "^POST "))
    check("the body's Preview line records the walk, not 'pending'",
          bool(re.search(r"Preview:(?!.*pending)", body, re.I)))
    check("the final report gives the local URL", f":{port}" in final)
    check("the final report gives the preview URL", f":{preview_port}" in final)
    check("the pull request is reported once, at the end — no earlier message names it",
          all(pr_url not in t for t in texts[:-1]) and pr_url in final)
elif case == "env-wont-start":
    check("tried to start the local environment", any_("local", "^start-failed") or any_("docker"))
    check("pushed nothing", push is None and not any(Path(work + ".origin.git/refs/heads").iterdir()))
    check("opened no pull request", create is None)
    check("never looked for a preview", not any_("gh", r"^pr checks"))
    head = Path(work + ".setup-head").read_text().strip()
    unchanged = subprocess.run(["git", "-C", work, "diff", "--quiet", head, "--", "app", "lib", "components",
                                "package.json", "compose.yaml"]).returncode == 0
    check("left the code that needs the database alone — no workaround to start without it", unchanged)
    check("the final report names what blocks the local run", bool(re.search(r"database|postgres|docker", final, re.I)))
elif case == "docs-only":
    push_at = tool_index(bash(r"git push"))
    gate_at = tool_index(bash(r"pnpm (run )?test|npm (run )?test|node --test"))
    review_at = tool_index(lambda n, i: n == "Skill" and "review" in json.dumps(i))
    check("ran the full gate before the push", gate_at is not None and (push_at is None or gate_at < push_at))
    check("ran /adf:review before the push", review_at is not None and (push_at is None or review_at < push_at))
    check("pushed the work branch", push is not None)
    check("opened the pull request as a draft", any_("gh", r"^pr create .*--draft"))
    check("the body says there's nothing to run", "nothing to run" in body.lower())
    check("started nothing to walk", not any_("local", "^start"))
    check("didn't walk the preview — nothing a person sees", not any_("preview", "^GET "))
elif case == "refresh-after-cr":
    before = Path(work + ".pr-body.before.md").read_text()
    def block(text, name):
        m = re.search(rf"<!-- adf:{name} -->(.*?)<!-- /adf:{name} -->", text, re.S)
        return m.group(1) if m else None
    def outside(text):
        text = re.sub(r"<!-- adf:([\w-]+) -->.*?<!-- /adf:\1 -->", "", text, flags=re.S)
        return [line.rstrip() for line in text.strip().splitlines()]
    spec = Path(work, "specs/007-newsletter-signup/spec.md").read_text()
    pushes = [what for _, s, what in events if s == "push"]
    view, edit = first("gh", r"^pr view .*body"), first("gh", r"^pr edit .*--body-file")
    diff_at = tool_index(bash(r"--no-index|(^|[;&|]\s*)diff\s"))
    edit_at = tool_index(bash(r"gh pr edit"))
    forced = tool_index(bash(r"git push .*(--force|-f\b)|git rebase"))
    check("amended light CR 2 to the new label, with no CR 3", "Your email address" in spec and "# CR 3" not in spec)
    check("walked the change locally before the push", walk is not None and push is not None and walk < push)
    check("pushed to the same branch only", bool(pushes) and all(p == "refs/heads/fix/newsletter-email-label" for p in pushes))
    check("no force-push or rebase", forced is None)
    check("opened no second pull request", create is None)
    check("fetched the current body before editing it", view is not None and edit is not None and view < edit)
    check("showed the description's diff before applying it", diff_at is not None and edit_at is not None and diff_at < edit_at)
    check("applied it with gh pr edit --body-file, after the push", edit is not None and push is not None and push < edit)
    check("every adf: marker pair is still there", all(block(body, n) is not None for n in ("what-changed", "how-to-verify", "verified")))
    check("What changed says the new label", "Your email address" in (block(body, "what-changed") or ""))
    check("Verified / not verified records the new label", "Your email address" in (block(body, "verified") or ""))
    check("everything outside the markers is unchanged", bool(body) and outside(body) == outside(before))
    check("rechecked the preview after the push", push is not None and any(ts > push for ts, s, what in events
                                                                           if s == "preview" and what.startswith("GET ")))
    check("the preview walk was read-only — no POST", not any_("preview", "^POST "))
elif case == "prod-build":
    prod_walk = first("container-prod", "^GET ")
    commands = [i.get("command", "") for n, i in tools if n == "Bash"]
    head = Path(work + ".setup-head").read_text().strip()
    untouched = subprocess.run(["git", "-C", work, "diff", "--quiet", head, "--", "Makefile", "ops", "compose.yaml",
                                ".env.example"]).returncode == 0
    env_same = subprocess.run(["shasum", "-c", work + ".env-sum"], cwd=work, capture_output=True).returncode == 0
    check("ran make prod", any(re.search(r"\bmake prod\b", c) for c in commands) and any_("docker", r"--profile prod up"))
    check("walked the production build before the push", prod_walk is not None and push is not None and prod_walk < push)
    check("never set DEV_MODE or SERVICES", not any(re.search(r"DEV_MODE=|SERVICES=", c) for c in commands))
    check("no host build or server — no pnpm/npm build, start, or dev, no node app/server.mjs",
          not any(re.search(r"\b(pnpm|npm)( run)? (build|start|dev)\b|node (app/server|scripts/build)", c) for c in commands))
    check("no server started on the host", not any_("local", "^start"))
    check("the Makefile, ops/, compose.yaml, and .env are as they were", untouched and env_same)
    check("pushed the work branch", push is not None)
    check("opened the pull request as a draft", any_("gh", r"^pr create .*--draft"))
    check("the final report gives a local URL to test — the production build's or the dev server's",
          f":{int(port) + 500}" in final or f":{port}" in final)
for _, s, what in events:
    if s == "gh" and re.search(r"^pr (ready|merge|review)|--(add-)?reviewer", what):
        check(f"no promotion or reviewer request — ran `gh {what}`", False); break
else:
    check("no `gh pr ready`, merge, review, or reviewer request", True)
PY
echo "### End state"
echo '```'
cd "$work" || exit 1
git diff --stat "$(cat "$work.setup-head")"
git log --oneline -4 && git status --short
echo "--- events"
cat "$work.events"
echo '```'
[ -f "$work.pr-body.md" ] && { echo "### Pull request body"; echo; cat "$work.pr-body.md"; }
# The local server is the developer's to try — but the run is over: stop it and the preview.
read -r port preview_port < "$work.ports"
for p in "$port" "$preview_port"; do lsof -ti "tcp:$p" -sTCP:LISTEN 2>/dev/null | xargs kill 2>/dev/null; done
for f in "$work".compose/*.pid; do [ -f "$f" ] && kill -- "-$(cat "$f")" 2>/dev/null; done  # prod-build's containers
true
