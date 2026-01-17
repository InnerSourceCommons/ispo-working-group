#!/bin/bash
# Helper script to test the stale workflow locally with act
# Usage: ./test-stale-workflow.sh [--dryrun]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_DIR"

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️  Warning: GITHUB_TOKEN not set. The stale action may fail."
    echo "   Set it with: export GITHUB_TOKEN=your_token"
    echo "   Or run with --dryrun to test workflow syntax only"
    echo ""
fi

# Run act with the workflow
if [[ "$*" == *"--dryrun"* ]]; then
    echo "Running in dry-run mode (validates workflow syntax only)..."
    act schedule -W .github/workflows/stale.yml --eventpath .github/events/schedule.json --dryrun
else
    echo "Running workflow (stale action may fail without GitHub API access)..."
    act schedule -W .github/workflows/stale.yml --eventpath .github/events/schedule.json
fi

