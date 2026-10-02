#!/usr/bin/env bash
#
# The project for the adopt cases, built by run-session-evals.sh in place of the newsletter project:
# a new one — a git repository with no commits and a README that says nothing is built yet. The
# framework isn't installed and no plugin is enabled.
#
set -euo pipefail
cd "$1"
git init -q -b main && git config user.email dev@example.com && git config user.name dev
cat > README.md <<'MD'
# Newsletter Site

The marketing site for a publisher: article pages and a newsletter signup. Nothing is built yet —
the team starts next week.
MD
