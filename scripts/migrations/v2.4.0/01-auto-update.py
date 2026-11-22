"""The aplyca marketplace entry auto-updates (decision 0041)."""
PHASE = "after"


def run(ctx):
    settings = ctx.settings()
    if settings is None:
        return "needs", "`.claude/settings.json` doesn't parse: add `\"autoUpdate\": true` to the `aplyca` entry by hand"
    entry = (settings.get("extraKnownMarketplaces") or {}).get("aplyca")
    if not isinstance(entry, dict):
        return "done", "no `aplyca` marketplace entry"
    if entry.get("autoUpdate") is True:
        return "done", "`autoUpdate` is already on"
    entry["autoUpdate"] = True
    ctx.save_settings(settings)
    return "applied", "added `\"autoUpdate\": true` to the `aplyca` marketplace entry"
