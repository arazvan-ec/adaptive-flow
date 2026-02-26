#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: pre-work — Verifies plan exists before implementation starts
# ─────────────────────────────────────────────────────────────────────
# Runs before the implementer worker is spawned.
# Blocks work if no plan/tasks file exists.
#
# Exit 0 = allow work, Exit 1 = block work.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

CHANGES_DIR="openspec/changes"
if [ ! -d "$CHANGES_DIR" ]; then
  echo "BLOCKED: No openspec/changes/ directory. Run the planner first."
  exit 1
fi

LATEST_SLUG=$(ls -t "$CHANGES_DIR" 2>/dev/null | head -1)
if [ -z "$LATEST_SLUG" ]; then
  echo "BLOCKED: No change directories found. Run the planner first."
  exit 1
fi

SLUG_DIR="$CHANGES_DIR/$LATEST_SLUG"

# Check for either plan-and-tasks.md (gravity 2) or tasks.md (gravity 3-4)
if [ -f "$SLUG_DIR/plan-and-tasks.md" ] || [ -f "$SLUG_DIR/tasks.md" ]; then
  echo "Pre-work check passed. Plan found in $SLUG_DIR"
  exit 0
fi

echo "BLOCKED: No plan found in $SLUG_DIR"
echo "Run the planner worker before starting implementation."
exit 1
