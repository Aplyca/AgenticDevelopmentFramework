#!/usr/bin/env bash
#
# Top-level eval runner. Runs static evals and (optionally) prints next-steps for dynamic evals.
#
# Usage:
#   ./run-evals.sh              # static only
#   ./run-evals.sh --all        # static + list dynamic fixtures to run manually
#

set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "========================================"
echo "Framework evals"
echo "========================================"
echo ""

# Static evals — always run
"$SCRIPT_DIR/static/check-skills.sh"
STATIC_EXIT=$?

if [ "${1:-}" = "--all" ]; then
    echo ""
    echo "----------------------------------------"
    echo "Dynamic evals — manual cases to run"
    echo "----------------------------------------"
    echo ""
    echo "Dynamic evals require an AI tool (Claude Code, Cursor, etc.) and aren't run automatically."
    echo "Run each fixture manually following the steps in dynamic/run-dynamic.md."
    echo ""
    echo "Available fixtures:"
    find "$SCRIPT_DIR/dynamic/fixtures" -name '*.input.md' 2>/dev/null | sort | while read -r f; do
        rel=${f#$SCRIPT_DIR/}
        echo "  - $rel"
    done
    echo ""
    echo "For automated dynamic evals, see dynamic/run-dynamic.md (Anthropic SDK / Braintrust / DeepEval patterns)."
    echo ""
fi

exit $STATIC_EXIT
