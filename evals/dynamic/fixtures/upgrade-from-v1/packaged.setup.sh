#!/usr/bin/env bash
# The packaged case: the run's copy becomes a packaged adoption at v1.4.0 (packaged.sh).
# Usage: packaged.setup.sh <run copy>   (FW, this checkout, comes from run-session-evals.sh)
bash "$(dirname "$0")/packaged.sh" "$1" "$FW"
