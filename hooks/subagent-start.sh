#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: subagent-start — Injects context into subagents
# ─────────────────────────────────────────────────────────────────────
# Triggered on SubagentStart.
# Ensures subagents spawned during flows receive relevant context:
# high-influence insights and current task meta.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
# shellcheck source=lib.sh
source "$PLUGIN_ROOT/hooks/lib.sh"

MEMORY_DIR="$PLUGIN_ROOT/memory"

CONTEXT_PARTS=()

# ── Inject high-influence insights ─────────────────────────────────
INSIGHTS_FILE="$MEMORY_DIR/user-insights.yaml"
HIGH_INSIGHTS=$(parse_yaml_insights "$INSIGHTS_FILE" "high")

if [ -n "$HIGH_INSIGHTS" ]; then
  CONTEXT_PARTS+=("## User Insights (high influence — apply proactively)
$HIGH_INSIGHTS")
fi

# ── Inject current task context ────────────────────────────────────
META_FILE="$MEMORY_DIR/current-task/meta.yaml"
if [ -f "$META_FILE" ]; then
  GRAVITY=$(parse_yaml_field "$META_FILE" "gravity")
  FLOW=$(parse_yaml_field "$META_FILE" "flow")
  TASK_NAME=$(parse_yaml_field "$META_FILE" "name")

  if [ -n "$GRAVITY" ]; then
    CONTEXT_PARTS+=("## Task Context
- Task: ${TASK_NAME:-unknown}
- Gravity: ${GRAVITY}
- Flow: ${FLOW:-unknown}")
  fi
fi

# ── Output ─────────────────────────────────────────────────────────
if [ ${#CONTEXT_PARTS[@]} -gt 0 ]; then
  COMBINED=""
  for part in "${CONTEXT_PARTS[@]}"; do
    COMBINED="${COMBINED}${part}

"
  done
  json_context "$COMBINED"
else
  echo "{}"
fi
