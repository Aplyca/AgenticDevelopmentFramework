"""`make run`'s ask rule goes: no rule or hook asks before it (decisions 0077, 0089).

The docker module's installer once added `Bash(make run *)` to permissions.ask, so `make run` prompted
in every mode. Now `Bash(make *)` covers it and the session's permission mode decides it, in Docker mode
and native mode alike. A project that wants a prompt in native mode, where the command runs on the
host, adds the rule back itself."""
PHASE = "after"
RULE = "Bash(make run *)"


def run(ctx):
    if "docker" not in ctx.modules:
        return "done", "no `docker` module"
    settings = ctx.settings()
    if settings is None:
        return "needs", (f"`.claude/settings.json` doesn't parse: once it does, remove `{RULE}` from "
                         "`permissions.ask` by hand, unless you want `make run` to prompt in every mode")
    permissions = settings.get("permissions")
    ask = permissions.get("ask") if isinstance(permissions, dict) else None
    if not isinstance(ask, list) or RULE not in ask:
        return "done", f"no `{RULE}` ask rule"
    permissions["ask"] = [rule for rule in ask if rule != RULE]
    ctx.save_settings(settings)
    return "applied", (f"removed `{RULE}` from `permissions.ask`: `make run` runs without a prompt in both modes "
                       "(decision 0089). In native mode its command runs on the host: add the rule back for a "
                       "prompt there, which prompts in Docker mode too")
