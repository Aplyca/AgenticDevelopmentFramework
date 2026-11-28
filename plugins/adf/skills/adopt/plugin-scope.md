# The plugin outside the documented install

`/adf:adopt` reads this when the plugin's settings are missing from `.claude/settings.json`
(Step 5), or this machine's copy of the marketplace isn't at the pin (Step 6).

**The settings are missing** — a user- or local-scope install: offer to add them (the marketplace
key must be `aplyca`, the name `enabledPlugins` refers to), and for a user-scope install, give the
commands that remove it (the plugin's README § Install).

**Why the pin isn't enough on this machine:** Claude Code keeps its copy of the marketplace at the
ref it was first added with (decision 0091). A pin that later moves reaches each machine through the
commands `/adf:upgrade` gives (decision 0090).

**The marketplace isn't at the pin** — its `ref` differs from the settings' `"ref"`, or is missing
(added without a release, it follows the default branch). It's a GAP, fixed after the merge, from
the project's folder: `claude plugin marketplace add <source>#v<X.Y.Z> --scope project`, then
`claude plugin uninstall` and `claude plugin install` (`--scope project`) for each plugin the
settings turn on, then `git restore .claude/settings.json`. `claude plugin update` isn't enough: at
the release's version it keeps the files it installed from the default branch (decision 0091).
