"""A Vercel or Contentful server /connect wrote before its read-only profile gets it after the merge (decisions 0057, 0068)."""
import json

PHASE = "after"
HOSTS = {"vercel": ("mcp.vercel.com",), "contentful": ("mcp.contentful.com", "mcp.eu.contentful.com")}
# Vercel's reads that return a decrypted secret: once both are denied, the profile was applied.
VERCEL_DENY = {"mcp__vercel__get_project_env", "mcp__vercel__get_shared_env_var"}


def services(servers):
    """The profiled services the project's .mcp.json connects, by server name or by host, each with
    the names of its servers."""
    found = {}
    for name, config in servers.items():
        url = str((config or {}).get("url", "")) if isinstance(config, dict) else ""
        host = url.split("://", 1)[-1].split("/", 1)[0]
        for service, hosts in HOSTS.items():
            if name == service or host in hosts:
                found.setdefault(service, []).append(name)
    return found


def profiled(service, names, allow, deny):
    """Whether every server of the service already has its profile."""
    if service == "vercel":
        return VERCEL_DENY <= deny
    # Contentful: named after the project (0068), with its reads allowed under that name.
    return all(name.startswith("contentful-") and any(rule.startswith(f"mcp__{name}__") for rule in allow)
               for name in names)


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
    permissions = settings.get("permissions") or {}
    allow, deny = set(permissions.get("allow") or []), set(permissions.get("deny") or [])
    plugin_on = (settings.get("enabledPlugins") or {}).get("adf-connect@aplyca") is True
    queued = []
    for service in sorted(connected):
        names = connected[service]
        if profiled(service, names, allow, deny):
            continue
        servers_named = ", ".join(f"`{name}`" for name in names)
        if service == "contentful":
            why = (f"apply the read-only profile to the Contentful server ({servers_named}) in `.mcp.json`, "
                   "named after the project as `contentful-<project>`, so its sign-in and space are its own")
            source = "decisions 0057 and 0068"
        else:
            why = f"apply the read-only profile to the `{service}` server in `.mcp.json`"
            source = "decision 0057"
        if not plugin_on:
            why += ", with `\"adf-connect@aplyca\": true` in enabledPlugins"
        ctx.follow_up(f"/adf-connect:connect {service}", why, f"{ctx.new.tag} {source}", "adf-connect")
        queued.append(f"`/adf-connect:connect {service}`")
    if not queued:
        return "done", "the read-only profiles are already applied"
    return "done", f"follow-up {', '.join(queued)}: read-only profiles for servers connected before them"
