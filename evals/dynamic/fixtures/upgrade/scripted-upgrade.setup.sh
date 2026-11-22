#!/usr/bin/env bash
#
# Replaces the suite's v1.0.0 project in this case's copy with the v2.3.0 packaged one, and gives the
# session what it needs to run the scripted upgrade (decision 0046): ADF_FRAMEWORK, a checkout with the
# release tags (the session's copy of this checkout). Until a release carries scripts/upgrade.py, a shim
# in <copy>.bin/ runs the checkout's own script as an unreleased commit; once the newest tag has it, no
# shim is made, and the session runs adf-upgrade as a project would.
# Usage: scripted-upgrade.setup.sh <copy>      (FW and FWC come from the runner)
#
set -euo pipefail
copy="$1"
find "$copy" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
bash "$(dirname "$0")/project-v2.sh" "$copy" "$FW"
printf 'ADF_FRAMEWORK=%s\nXDG_CACHE_HOME=%s\n' "$FWC" "$copy.cache" > "$copy.env"
newest=$(git -C "$FW" tag --list 'v*' --sort=-v:refname | head -1)
if ! git -C "$FW" cat-file -e "$newest:scripts/upgrade.py" 2>/dev/null; then
  mkdir -p "$copy.bin"
  cat > "$copy.bin/adf-upgrade" <<SHIM
#!/usr/bin/env bash
# No release has the script yet: run this checkout's, as an unreleased commit.
exec "$FWC/plugins/adf/bin/adf-upgrade" --unreleased HEAD "\$@"
SHIM
  chmod +x "$copy.bin/adf-upgrade"
fi
