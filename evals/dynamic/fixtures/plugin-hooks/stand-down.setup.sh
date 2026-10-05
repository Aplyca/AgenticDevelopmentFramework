#!/usr/bin/env bash
# This case's copy is a committed install: the stamp loses `install: packaged`, so the plugin's hooks
# stand down (the project would run its own copies; this one wires none).
cd "$1" || exit 1
sed -i.bak '1s/ · install: packaged//' CLAUDE.md && rm -f CLAUDE.md.bak
git commit -q -am "chore: switch to the committed install"
