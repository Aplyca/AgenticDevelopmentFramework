"""`make run` is decided by the approve-container-run hook, so its ask rule goes (decision 0077).

An ask rule wins over a hook's approval: while `Bash(make run *)` is in permissions.ask, `make run`
prompts in Docker mode too. The rule leaves only once the hook is there to ask in native mode."""
import json

PHASE = "after"
RULE = "Bash(make run *)"
HOOK = "approve-container-run.sh"


def run(ctx):
    if "docker" not in ctx.modules:
        return "done", "no `docker` module"
    settings = ctx.settings()
    if settings is None:
        return "needs", (f"`.claude/settings.json` doesn't parse: once it does, remove `{RULE}` from "
                         "`permissions.ask` by hand, so the hook decides `make run`")
    permissions = settings.get("permissions")
    ask = permissions.get("ask") if isinstance(permissions, dict) else None
    if not isinstance(ask, list) or RULE not in ask:
        return "done", f"no `{RULE}` ask rule"
    if not ctx.packaged and not (HOOK in json.dumps(settings.get("hooks") or {})
                                 and ctx.ws.exists(f".claude/hooks/{HOOK}")):
        return "needs", (f"`{RULE}` stays in `permissions.ask`, so `make run` still asks in every mode: "
                         f"`.claude/hooks/{HOOK}` isn't there or `.claude/settings.json` doesn't wire it on "
                         "`Bash`. Wire it, then remove the rule by hand")
    permissions["ask"] = [rule for rule in ask if rule != RULE]
    ctx.save_settings(settings)
    return "applied", (f"removed `{RULE}` from `permissions.ask`: the approve-container-run hook now approves "
                       "`make run` in Docker mode, where it runs in the app's container, and asks in native "
                       "mode. It asks in Docker mode too until the `run` task in `ops/docker/Makefile` meets "
                       "the specification's C10 (`/dev-env set up` audits it)")
