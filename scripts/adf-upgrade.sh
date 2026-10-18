#!/usr/bin/env bash
# Upgrade this project to a framework release: find a framework checkout with history, fetch it, and
# run the release's own scripts/upgrade.py (decision 0046). This wrapper is the pinned plugin's code,
# as old as the project's release, so it does nothing a release could change: the upgrade itself is
# the new release's.
#
# Usage: adf-upgrade [<tag>] [--dry-run] [--offline] [--unreleased <ref>] [--add-modules a,b] [-- <script options>]
#   <tag>               the release to upgrade to (default: the newest v* tag)
#   --dry-run           change nothing; print the report of what the upgrade would do
#   --offline           use the checkout as it is, without fetching
#   --unreleased <ref>  upgrade to a commit that isn't a release (working on the framework)
#   other options       passed to scripts/upgrade.py
#
# The checkout, in order: $ADF_FRAMEWORK; the aplyca marketplace's folder, when it was added from a
# local clone with full history; else a bare clone cached at ${XDG_CACHE_HOME:-~/.cache}/adf/framework.git
# from $ADF_FRAMEWORK_URL (default: the framework's GitHub repository). A release's tree is extracted
# once, to ${XDG_CACHE_HOME:-~/.cache}/adf/trees/<commit>/, where /adf:upgrade also reads its skill.
set -euo pipefail

PROTOCOL=1
URL="${ADF_FRAMEWORK_URL:-https://github.com/aplyca/AgenticDevelopmentFramework.git}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/adf"

die() { echo "adf-upgrade: $*" >&2; exit 2; }

if ! REPO="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  die "not inside a git repository"
fi

TAG="" OFFLINE=0 UNRELEASED="" PASS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --offline) OFFLINE=1 ;;
    --unreleased) [ $# -ge 2 ] || die "--unreleased needs a ref"; UNRELEASED="$2"; shift ;;
    --) shift; PASS+=("$@"); break ;;
    v[0-9]*) TAG="$1" ;;
    *) PASS+=("$1") ;;
  esac
  shift
done

# A clone with full history, or nothing: a marketplace added from GitHub sits at the pin, shallow.
has_history() {
  [ -n "$1" ] && git -C "$1" rev-parse --git-dir >/dev/null 2>&1 &&
    [ "$(git -C "$1" rev-parse --is-shallow-repository 2>/dev/null)" = "false" ] &&
    [ -n "$(git -C "$1" tag --list 'v*' | head -1)" ]
}

marketplace_folder() {
  command -v claude >/dev/null 2>&1 || return 0
  claude plugin marketplace list --json 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except ValueError:
    sys.exit(0)
items = data if isinstance(data, list) else data.get("marketplaces", [])
for m in items:
    if isinstance(m, dict) and m.get("name") == "aplyca" and m.get("installLocation"):
        print(m["installLocation"])
' || true
}

BARE=0
if [ -n "${ADF_FRAMEWORK:-}" ]; then
  has_history "$ADF_FRAMEWORK" || die "\$ADF_FRAMEWORK ($ADF_FRAMEWORK) isn't a framework checkout with full history"
  HISTORY="$ADF_FRAMEWORK"
elif LOCAL="$(marketplace_folder)" && has_history "$LOCAL"; then
  HISTORY="$LOCAL"
else
  HISTORY="$CACHE/framework.git" BARE=1
  if [ ! -d "$HISTORY" ]; then
    [ "$OFFLINE" -eq 0 ] || die "--offline, and no cached checkout at $HISTORY"
    mkdir -p "$CACHE"
    git clone --quiet --bare "$URL" "$HISTORY" || die "couldn't clone $URL"
  fi
fi

if [ "$OFFLINE" -eq 0 ]; then
  if [ "$BARE" -eq 1 ]; then
    git -C "$HISTORY" fetch --quiet --prune --tags origin '+refs/heads/*:refs/heads/*' ||
      die "couldn't fetch $URL (rerun with --offline to use the cached releases)"
  else
    git -C "$HISTORY" fetch --quiet --tags origin 2>/dev/null ||
      echo "adf-upgrade: couldn't fetch in $HISTORY; using the releases it has" >&2
  fi
fi

if [ -n "$UNRELEASED" ]; then
  COMMIT="$(git -C "$HISTORY" rev-parse --verify -q "$UNRELEASED^{commit}")" || die "no such ref: $UNRELEASED"
  PASS+=(--unreleased)
else
  [ -n "$TAG" ] || TAG="$(git -C "$HISTORY" tag --list 'v*' --sort=-v:refname | head -1)"
  [ -n "$TAG" ] || die "no release tags in $HISTORY"
  COMMIT="$(git -C "$HISTORY" rev-parse --verify -q "$TAG^{commit}")" || die "no such release: $TAG"
fi

TREE="$CACHE/trees/$COMMIT"
if [ ! -f "$TREE/.complete" ]; then
  rm -rf "$TREE" && mkdir -p "$TREE"
  git -C "$HISTORY" archive "$COMMIT" | tar -x -C "$TREE"
  touch "$TREE/.complete"
fi

if [ ! -f "$TREE/scripts/upgrade.py" ]; then
  die "${TAG:-$COMMIT} predates the scripted upgrade: follow /adf:upgrade's manual procedure for this one"
fi

exec python3 "$TREE/scripts/upgrade.py" "$REPO" --history "$HISTORY" --new-ref "$COMMIT" \
  --protocol "$PROTOCOL" ${PASS[@]+"${PASS[@]}"}
