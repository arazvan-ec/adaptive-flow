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
if [ -f "$INSIGHTS_FILE" ]; then
  HIGH_INSIGHTS=""
  if command -v python3 &>/dev/null; then
    HIGH_INSIGHTS=$(python3 -c "
import yaml, sys
try:
    with open('$INSIGHTS_FILE') as f:
        data = yaml.safe_load(f)
    if data and 'insights' in data:
        for i in data['insights']:
            if i.get('influence') == 'high' and i.get('status') == 'active':
                print(f\"- [{i['id']}] {i['observation']}\")
except Exception:
    pass
" 2>/dev/null || true)
  fi

  if [ -n "$HIGH_INSIGHTS" ]; then
    CONTEXT="${CONTEXT}

### Active High-Influence Insights
${HIGH_INSIGHTS}"
  fi
fi

# ── Append current task meta ───────────────────────────────────────
META_FILE="$MEMORY_DIR/current-task/meta.yaml"
if [ -f "$META_FILE" ]; then
  CONTEXT="${CONTEXT}

### Current Task
$(cat "$META_FILE" 2>/dev/null || true)"
fi

# ── Output as JSON ─────────────────────────────────────────────────
ESCAPED=$(echo "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' '\a' | sed 's/\a/\\n/g')
echo "{\"additionalContext\": \"$ESCAPED\"}"
