"""The parallel-agents guide ships in the plugin; the project keeps docs/SHARED-SERVICES.md (decision 0044)."""
import re

PHASE = "before"
GUIDE = "docs/PARALLEL-AGENTS.md"
PAGE = "docs/SHARED-SERVICES.md"
OWNER = re.compile(r"^<!-- owner:.*-->$", re.M)
MARKER = "<!-- CUSTOMIZE: what worktrees share, what a task may copy, and what that costs -->"


def sections(text):
    """{heading: body} for each `## ` section, and the text before the first under ''."""
    parts = re.split(r"^(## .*)$", text, flags=re.M)
    out = {"": parts[0]}
    for heading, body in zip(parts[1::2], parts[2::2]):
        out[heading] = body
    return out


def normalized(text):
    return OWNER.sub("<!-- owner -->", text).strip()


def run(ctx):
    if "parallel-agents" not in ctx.modules:
        return "done", "the project doesn't use the parallel-agents module"
    copy = ctx.ws.text(GUIDE)
    if copy is None or not (OWNER.search(copy) and "## Shared services" in copy):
        return "done", f"no project copy of `{GUIDE}` to split"
    old = (ctx.old_file("modules/parallel-agents/files/docs/PARALLEL-AGENTS.md") or b"").decode()
    page = ctx.new_file("modules/parallel-agents/files/docs/SHARED-SERVICES.md").decode()
    ctx.claim(GUIDE)
    ctx.claim(PAGE)

    mine, theirs = sections(copy), sections(old)
    shared = mine.get("## Shared services", "")
    template = theirs.get("## Shared services", "")
    recorded = shared.replace(template.strip(), "").replace(MARKER, "").strip() if template else shared.strip()

    if ctx.ws.text(PAGE) is None:
        owner = OWNER.search(copy).group(0)
        page = OWNER.sub(lambda _: owner, page, count=1)
        if recorded:
            page = page.replace(MARKER, recorded + "\n\n" + MARKER)
        ctx.write(PAGE, page, executable=False)
        wrote = f"wrote `{PAGE}` with the copy's owner line" + (" and what the team recorded in § Shared services"
                                                                 if recorded else "")
    else:
        wrote = f"`{PAGE}` already exists"

    edited = [h[3:] for h in mine if h != "## Shared services" and normalized(mine[h]) != normalized(theirs.get(h, ""))]
    edited += [h[3:] for h in theirs if h not in mine and h != "## Shared services"]
    mentions = [h for h in ctx.grep("Shared services") if not h.startswith((GUIDE, PAGE))]
    if not old or edited:
        what = ", ".join(f"§ {h or '(the top)'}" for h in edited) if old else "every section (no copy at the old release)"
        return "needs", (f"{wrote}. `{GUIDE}` was edited elsewhere — {what}: each moves into `{PAGE}`, stays under a "
                         f"name of its own, or goes upstream; nothing was replaced"
                         + ("" if not mentions else ". Name `docs/SHARED-SERVICES.md` where these name § Shared services:\n"
                            + "\n".join(f"  {m}" for m in mentions[:20])))
    if ctx.packaged:
        ctx.delete(GUIDE)
        done = f"deleted `{GUIDE}`: the plugin carries the guide"
    else:
        ctx.write(GUIDE, ctx.new_machinery(GUIDE), executable=False)
        done = f"replaced `{GUIDE}` with the guide build-committed.py writes"
    if mentions:
        return "needs", (f"{wrote}; {done}. Name `docs/SHARED-SERVICES.md` where these name § Shared services:\n"
                         + "\n".join(f"  {m}" for m in mentions[:20]))
    return "applied", f"{wrote}; {done}"
