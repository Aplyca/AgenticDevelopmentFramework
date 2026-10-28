"""A Vercel or Contentful server /connect wrote before its read-only profile gets it after the merge (decision 0057)."""
import json

PHASE = "after"
HOSTS = {"vercel": ("mcp.vercel.com",), "contentful": ("mcp.contentful.com", "mcp.eu.contentful.com")}
# Vercel's reads that return a decrypted secret: once both are denied, the profile was applied.
VERCEL_DENY = {"mcp__vercel__get_project_env", "mcp__vercel__get_shared_env_var"}


def services(servers):
    """The profiled services the project's .mcp.json connects, by server name or by host."""
    found = set()
    for name, config in servers.items():
        url = str((config or {}).get("url", "")) if isinstance(config, dict) else ""
        host = url.split("://", 1)[-1].split("/", 1)[0]
        for service, hosts in HOSTS.items():
            if name == service or host in hosts:
                found.add(service)
    return sorted(found)


def run(ctx):
    text = ctx.ws.text(".mcp.json")
    if text is None:
        return "done", "no `.mcp.json`"
    try:
        servers = json.loads(text).get("mcpServers") or {}
    except (ValueError, AttributeError):
        return "needs", ("`.mcp.json` doesn't parse: if it connects Vercel or Contentful, run "
                         "`/adf-connect:connect <service>` after the merge to apply its read-only profile")
    connected = services(servers)
    if not connected:
        return "done", "no Vercel or Contentful server in `.mcp.json`"

    settings = ctx.settings() or {}
    deny = set((settings.get("permissions") or {}).get("deny") or [])
    plugin_on = (settings.get("enabledPlugins") or {}).get("adf-connect@aplyca") is True
    queued = []
    for service in connected:
        if service == "vercel" and VERCEL_DENY <= deny:
            continue
        why = f"apply the read-only profile to the `{service}` server in `.mcp.json`"
        if not plugin_on:
            why += ", with `\"adf-connect@aplyca\": true` in enabledPlugins"
        ctx.follow_up(f"/adf-connect:connect {service}", why, f"{ctx.new.tag} decision 0057", "adf-connect")
        queued.append(f"`/adf-connect:connect {service}`")
    if not queued:
        return "done", "the `vercel` server's read-only profile is already applied"
    return "done", f"follow-up {', '.join(queued)}: read-only profiles for servers connected before them"
