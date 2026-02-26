#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: post-plan — Validates plan completeness after planner worker
# ─────────────────────────────────────────────────────────────────────
# Runs after the planner worker returns.
# Checks: spec.md has acceptance criteria, design.md has SOLID verdicts.
#
# Exit 0 = pass (may emit warnings), Exit 1 = block.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

# Find the most recent openspec/changes/ directory
CHANGES_DIR="openspec/changes"
if [ ! -d "$CHANGES_DIR" ]; then
  echo "INFO: No openspec/changes/ directory found. Skipping post-plan validation."
  exit 0
fi

# Get the most recently modified subdirectory
LATEST_SLUG=$(ls -t "$CHANGES_DIR" 2>/dev/null | head -1)
if [ -z "$LATEST_SLUG" ]; then
  echo "INFO: No change directories found. Skipping."
  exit 0
fi

SLUG_DIR="$CHANGES_DIR/$LATEST_SLUG"

# ── Check for plan-and-tasks.md (gravity 2) ─────────────────────────
if [ -f "$SLUG_DIR/plan-and-tasks.md" ]; then
  if ! grep -q "Acceptance Criteria" "$SLUG_DIR/plan-and-tasks.md"; then
    echo "WARNING: plan-and-tasks.md missing 'Acceptance Criteria' section."
  else
    echo "Plan (gravity 2): Acceptance criteria found."
  fi
  exit 0
fi

# ── Check for spec.md (gravity 3-4) ─────────────────────────────────
if [ -f "$SLUG_DIR/spec.md" ]; then
  if ! grep -qi "acceptance criteria\|acceptance criterion" "$SLUG_DIR/spec.md"; then
    echo "WARNING: spec.md missing acceptance criteria."
  else
    echo "Spec: Acceptance criteria found."
  fi
else
  echo "WARNING: spec.md not found in $SLUG_DIR"
fi

# ── Check for design.md (gravity 3-4) ───────────────────────────────
if [ -f "$SLUG_DIR/design.md" ]; then
  if ! grep -qi "SOLID\|solid" "$SLUG_DIR/design.md"; then
    echo "WARNING: design.md missing SOLID analysis section."
  else
    echo "Design: SOLID analysis found."
  fi
else
  echo "WARNING: design.md not found in $SLUG_DIR"
fi

# ── Check for tasks.md ───────────────────────────────────────────────
if [ ! -f "$SLUG_DIR/tasks.md" ]; then
  echo "WARNING: tasks.md not found in $SLUG_DIR"
else
  echo "Tasks: File found."
fi

echo "Post-plan validation completed."
exit 0
