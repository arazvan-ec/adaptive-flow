#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: post-compact — Re-injects core context after compaction
# ─────────────────────────────────────────────────────────────────────
# Triggered on SessionStart(compact).
# After context compaction, critical routing and memory references
# may be lost. This hook re-injects the essentials.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
# shellcheck source=lib.sh
source "$PLUGIN_ROOT/hooks/lib.sh"

MEMORY_DIR="$PLUGIN_ROOT/memory"

CONTEXT="## Adaptive Flow — Post-Compaction Context

### Routing Table
| Gravedad | Criterio | Flow |
|----------|----------|------|
| 1 | ≤3 archivos, cambio claro | flows/direct.md |
| 2 | 4-8 archivos, scope claro | flows/plan-execute.md |
| 3 | >8 archivos o multi-capa | flows/full-cycle.md |
| 4 | Scope ambiguo, investigacion | flows/shape-first.md |

### Memory Pointers
- Insights: memory/user-insights.yaml
- Learnings: memory/learnings.yaml
- Current task: memory/current-task/"

# ── Append high-influence insights ─────────────────────────────────
INSIGHTS_FILE="$MEMORY_DIR/user-insights.yaml"
HIGH_INSIGHTS=$(parse_yaml_insights "$INSIGHTS_FILE" "high")

if [ -n "$HIGH_INSIGHTS" ]; then
  CONTEXT="${CONTEXT}

### Active High-Influence Insights
${HIGH_INSIGHTS}"
fi

# ── Append current task meta ───────────────────────────────────────
META_FILE="$MEMORY_DIR/current-task/meta.yaml"
if [ -f "$META_FILE" ]; then
  CONTEXT="${CONTEXT}

### Current Task
$(cat "$META_FILE" 2>/dev/null || true)"
fi

# ── Output as JSON ─────────────────────────────────────────────────
json_context "$CONTEXT"
