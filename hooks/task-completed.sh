#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: task-completed — Updates task state on completion
# ─────────────────────────────────────────────────────────────────────
# Triggered on TaskCompleted.
# Updates meta.yaml status and reminds about compound-capture for
# gravity 3+ tasks.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
# shellcheck source=lib.sh
source "$PLUGIN_ROOT/hooks/lib.sh"

TASK_DIR="$PLUGIN_ROOT/memory/current-task"
META_FILE="$TASK_DIR/meta.yaml"

if [ ! -f "$META_FILE" ]; then
  echo "{}"
  exit 0
fi

GRAVITY=$(parse_yaml_field "$META_FILE" "gravity")

CONTEXT=""

# ── Remind about compound-capture for gravity 3+ ──────────────────
if [[ "$GRAVITY" =~ ^[0-9]+$ ]] && [ "$GRAVITY" -ge 3 ]; then
  if [ ! -f "$TASK_DIR/retrospective.md" ]; then
    CONTEXT="Task completed (gravity ${GRAVITY}). Remember to run /adaptive-flow:compound-capture to extract learnings and patterns before ending the session."
  fi
fi

if [ -n "$CONTEXT" ]; then
  json_context "$CONTEXT"
else
  echo "{}"
fi
