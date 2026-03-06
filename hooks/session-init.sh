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
# shellcheck source=lib.sh
source "$PLUGIN_ROOT/hooks/lib.sh"

MEMORY_DIR="$PLUGIN_ROOT/memory"

CONTEXT_PARTS=()

# ── TIER 1: Always loaded ─────────────────────────────────────────
# Loaded on every session start. Minimal context for immediate use.
# Tier 2 (learnings, full insights, briefing) loaded by flow files.
# Tier 3 (core guides) loaded on demand by pre-write-guard.sh.

# ── Load high-influence user insights ──────────────────────────────
INSIGHTS_FILE="$MEMORY_DIR/user-insights.yaml"
HIGH_INSIGHTS=$(parse_yaml_insights "$INSIGHTS_FILE" "high")

if [ -n "$HIGH_INSIGHTS" ]; then
  CONTEXT_PARTS+=("## Active High-Influence Insights
$HIGH_INSIGHTS")
fi

# ── Load architecture profile (if exists) ──────────────────────────
ARCH_FILE="$MEMORY_DIR/architecture-profile.yaml"
if [ -f "$ARCH_FILE" ]; then
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

# ── Detect plan mode ──────────────────────────────────────────────
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
  json_context "$COMBINED"
else
  echo "{}"
fi
