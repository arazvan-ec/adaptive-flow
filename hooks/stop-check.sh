#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: stop-check — Enforces compound-capture for gravity 3+ tasks
# ─────────────────────────────────────────────────────────────────────
# Triggered on Stop.
# Checks if the current task is gravity 3+ and whether compound-capture
# was executed (retrospective.md exists).
#
# IMPORTANT: Checks stop_hook_active to prevent infinite loops.
# Exit 0 = allow stop. Non-zero or decision:block = prevent stop.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
TASK_DIR="$PLUGIN_ROOT/memory/current-task"
META_FILE="$TASK_DIR/meta.yaml"

# ── Prevent infinite loops ─────────────────────────────────────────
# Track how many times the hook has blocked stop using a counter file.
# The counter lives inside the task directory (not /tmp) so it can't be
# trivially deleted without also modifying the task workspace.
BLOCK_COUNTER_FILE="$TASK_DIR/.stop-block-count"
BLOCK_COUNT=0
if [ -f "$BLOCK_COUNTER_FILE" ]; then
  BLOCK_COUNT=$(cat "$BLOCK_COUNTER_FILE" 2>/dev/null || echo "0")
fi
# After blocking twice, allow stop to prevent truly infinite loops
if [ "$BLOCK_COUNT" -ge 2 ]; then
  rm -f "$BLOCK_COUNTER_FILE"
  echo "{}"
  exit 0
fi

# ── Check if there is an active task with gravity ──────────────────
if [ ! -f "$META_FILE" ]; then
  # No active task, allow stop
  echo "{}"
  exit 0
fi

# ── Parse gravity from meta.yaml ───────────────────────────────────
# Use grep as the primary parser (no external dependencies).
# Only accept numeric values; default to 3 (safe/strict) if unparseable
# to avoid silently bypassing enforcement for high-gravity tasks.
GRAVITY=$(grep -E '^gravity:\s*[0-9]+' "$META_FILE" 2>/dev/null | head -1 | awk '{print $2}')
if ! [[ "$GRAVITY" =~ ^[0-9]+$ ]]; then
  # If gravity cannot be parsed, default to 3 (enforce) rather than 0 (skip).
  # This prevents bypassing enforcement when the file is malformed.
  GRAVITY=3
fi

# ── Only enforce for gravity 3+ ───────────────────────────────────
if [ "$GRAVITY" -lt 3 ] 2>/dev/null; then
  echo "{}"
  exit 0
fi

# ── Check if compound-capture was executed ─────────────────────────
if [ -f "$TASK_DIR/retrospective.md" ]; then
  # Compound capture was done, allow stop
  echo "{}"
  exit 0
fi

# ── Block stop and remind about compound-capture ───────────────────
# Increment block counter (stored in task dir, not /tmp)
echo $((BLOCK_COUNT + 1)) > "$BLOCK_COUNTER_FILE"
echo "{\"decision\": \"block\", \"reason\": \"This is a gravity ${GRAVITY} task. Run /adaptive-flow:compound-capture before completing to extract learnings and patterns. This maintains the compound engineering loop.\"}"
