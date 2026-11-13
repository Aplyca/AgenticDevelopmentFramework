"""The docker module asks before no docker or make command, so the rules it added go (decision 0078).

Only the rules the module's installer wrote, by their exact text: a rule the project added itself
stays. `Bash(make run *)` is the first migration's, which waits for the hook."""
PHASE = "after"
RULES = (
    "Bash(docker compose down *-v*)",
    "Bash(docker compose * down *-v*)",
    "Bash(docker compose down *--rmi*)",
    "Bash(docker compose * down *--rmi*)",
    "Bash(docker-compose down *-v*)",
    "Bash(docker compose rm)",
    "Bash(docker compose rm *)",
    "Bash(docker rm *)",
    "Bash(docker rmi *)",
    "Bash(docker * rm *)",
    "Bash(docker * prune)",
    "Bash(docker * prune *)",
    "Bash(docker push *)",
    "Bash(docker inspect *)",
    "Bash(docker compose config)",
    "Bash(docker *exec *env*)",
    "Bash(docker compose run *env*)",
    "Bash(make *reset*)",
    # What earlier releases of the module asked before.
    "Bash(make reset)",
    "Bash(make reset *)",
)


def run(ctx):
    if "docker" not in ctx.modules:
        return "done", "no `docker` module"
    settings = ctx.settings()
    if settings is None:
        return "needs", ("`.claude/settings.json` doesn't parse: once it does, remove the docker module's rules "
                         "from `permissions.ask` by hand (`modules/docker/MODULE.md`)")
    permissions = settings.get("permissions")
    ask = permissions.get("ask") if isinstance(permissions, dict) else None
    found = [rule for rule in ask if rule in RULES] if isinstance(ask, list) else []
    if not found:
        return "done", "none of the docker module's ask rules"
    permissions["ask"] = [rule for rule in ask if rule not in RULES]
    ctx.save_settings(settings)
    return "applied", (f"removed the docker module's {len(found)} ask rule(s) for `docker` and `make` commands: "
                       "they run without a prompt, `make reset` and `docker compose down -v` included. "
                       "To keep a prompt for one, add the rule back to `permissions.ask`")
