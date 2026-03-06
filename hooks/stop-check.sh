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
# shellcheck source=lib.sh
source "$PLUGIN_ROOT/hooks/lib.sh"

TASK_DIR="$PLUGIN_ROOT/memory/current-task"
META_FILE="$TASK_DIR/meta.yaml"

# ── Prevent infinite loops ─────────────────────────────────────────
# Track how many times the hook has blocked stop using a counter file.
# Include a session timestamp so stale counters from old sessions
# don't carry over and prevent stopping in new sessions.
BLOCK_COUNTER_FILE="$TASK_DIR/.stop-block-count"
BLOCK_COUNT=0
SESSION_ID="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"

if [ -f "$BLOCK_COUNTER_FILE" ]; then
  STORED_SESSION=$(head -1 "$BLOCK_COUNTER_FILE" 2>/dev/null || echo "")
  STORED_COUNT=$(tail -1 "$BLOCK_COUNTER_FILE" 2>/dev/null || echo "0")

  if [ "$STORED_SESSION" = "$SESSION_ID" ]; then
    BLOCK_COUNT="$STORED_COUNT"
  else
    # Different session — reset counter
    BLOCK_COUNT=0
  fi
fi

# Ensure BLOCK_COUNT is numeric
if ! [[ "$BLOCK_COUNT" =~ ^[0-9]+$ ]]; then
  BLOCK_COUNT=0
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
GRAVITY=$(parse_yaml_field "$META_FILE" "gravity")
if ! [[ "$GRAVITY" =~ ^[0-9]+$ ]]; then
  # If gravity cannot be parsed, default to 3 (enforce) rather than 0 (skip).
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
# Increment block counter with session awareness
printf '%s\n%s\n' "$SESSION_ID" "$((BLOCK_COUNT + 1))" > "$BLOCK_COUNTER_FILE"

json_decision_block "This is a gravity ${GRAVITY} task. Run /adaptive-flow:compound-capture before completing to extract learnings and patterns. This maintains the compound engineering loop."
