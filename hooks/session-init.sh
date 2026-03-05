#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: session-init — Loads memory into context on session start
# ─────────────────────────────────────────────────────────────────────
# Triggered on SessionStart (startup/resume).
# Implements TIER 1 memory loading: high-influence insights,
# architecture profile, and current task meta.
# Outputs JSON with additionalContext for Claude.
#
# Memory Loading Tiers:
#   Tier 1 (always, here): user-insights.yaml (high influence only),
#          architecture-profile.yaml, current-task/meta.yaml
#   Tier 2 (flow activation): Full user-insights.yaml (all influences),
#          learnings.yaml, next-briefing.md — loaded by flows (gravity 2+)
#   Tier 3 (on demand): core/security-guide.md, core/solid-reference.md,
#          core/api-patterns.md, core/testing-guide.md — loaded by
#          pre-write-guard.sh when relevant file patterns detected
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
MEMORY_DIR="$PLUGIN_ROOT/memory"

CONTEXT_PARTS=()

# ── TIER 1: Always loaded ─────────────────────────────────────────
# Loaded on every session start. Minimal context for immediate use.
# Tier 2 (learnings, full insights, briefing) loaded by flow files.
# Tier 3 (core guides) loaded on demand by pre-write-guard.sh.

# ── Load high-influence user insights ──────────────────────────────
INSIGHTS_FILE="$MEMORY_DIR/user-insights.yaml"
if [ -f "$INSIGHTS_FILE" ]; then
  # Extract high-influence active insights (simple grep-based parsing)
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

  if [ -z "$HIGH_INSIGHTS" ]; then
    # Fallback: grep-based extraction for high-influence insights
    HIGH_INSIGHTS=$(grep -B2 'influence: high' "$INSIGHTS_FILE" 2>/dev/null | grep 'observation:' | sed 's/.*observation: *"\?\(.*\)"\?/- \1/' || true)
  fi

  if [ -n "$HIGH_INSIGHTS" ]; then
    CONTEXT_PARTS+=("## Active High-Influence Insights
$HIGH_INSIGHTS")
  fi
fi

# ── Load architecture profile (if exists) ──────────────────────────
ARCH_FILE="$MEMORY_DIR/architecture-profile.yaml"
if [ -f "$ARCH_FILE" ]; then
  # Extract key fields: language, framework, patterns
  ARCH_SUMMARY=""
  if command -v python3 &>/dev/null; then
    ARCH_SUMMARY=$(python3 -c "
import yaml, sys
try:
    with open('$ARCH_FILE') as f:
        data = yaml.safe_load(f)
    if data:
        for key in ['language', 'framework', 'architecture', 'test_runner']:
            if key in data:
                print(f'- {key}: {data[key]}')
except Exception:
    pass
" 2>/dev/null || true)
  fi

  if [ -n "$ARCH_SUMMARY" ]; then
    CONTEXT_PARTS+=("## Architecture Profile
$ARCH_SUMMARY")
  fi
fi

# ── Learnings: moved to Tier 2 ─────────────────────────────────────
# learnings.yaml is now loaded by flow files (gravity 2+), not here.
# See: flows/plan-execute.md, flows/full-cycle.md, flows/shape-first.md

# ── Detect plan mode ──────────────────────────────────────────────
# If CLAUDE_PERMISSION_MODE is set, detect plan mode for flow optimization.
# When plan mode is active + gravity 2, the planner skill is redundant.
if [ "${CLAUDE_PERMISSION_MODE:-}" = "plan" ]; then
  CONTEXT_PARTS+=("## Session Mode
- plan_mode: true (planner skill redundant for gravity 2 tasks)")
fi

# ── Load current task meta (if exists) ─────────────────────────────
META_FILE="$MEMORY_DIR/current-task/meta.yaml"
if [ -f "$META_FILE" ]; then
  META_SUMMARY=$(cat "$META_FILE" 2>/dev/null || true)
  if [ -n "$META_SUMMARY" ]; then
    CONTEXT_PARTS+=("## Current Task
\`\`\`yaml
$META_SUMMARY
\`\`\`")
  fi
fi

# ── Output combined context ────────────────────────────────────────
if [ ${#CONTEXT_PARTS[@]} -gt 0 ]; then
  COMBINED=""
  for part in "${CONTEXT_PARTS[@]}"; do
    COMBINED="${COMBINED}${part}

"
  done
  # Output as JSON with additionalContext
  # Escape for JSON: backslashes, quotes, newlines
  ESCAPED=$(echo "$COMBINED" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' '\a' | sed 's/\a/\\n/g')
  echo "{\"additionalContext\": \"$ESCAPED\"}"
else
  echo "{}"
fi
