#!/usr/bin/env bash
#
# The packaged case with the parallel-agents module. v1.4.0's /upgrade won't run in the main checkout of
# a project with the module: the main checkout is the hub, and the upgrade is dispatched to a worktree
# like any task. So the main checkout moves beside the run's path (<run copy>.main), and the run's path
# becomes a worktree of it on the upgrade's branch, where the session starts.
# Usage: packaged-parallel-agents.setup.sh <run copy>   (FW, this checkout, comes from run-session-evals.sh)
#
set -euo pipefail
bash "$(dirname "$0")/packaged.sh" "$1" "$FW" parallel-agents
release="$(git -C "$FW" tag --list 'v*' --sort=-v:refname | head -1)"
mv "$1" "$1.main"
git -C "$1.main" worktree add -q -b "chore/skeleton-upgrade-$(git -C "$FW" rev-parse --short "$release^{commit}")" "$1"
