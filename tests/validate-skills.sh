#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# validate-skills.sh — Validates skill SKILL.md files
# ─────────────────────────────────────────────────────────────────────
# Checks each skill for:
#   1. YAML frontmatter exists (between --- delimiters)
#   2. context: fork is declared
#   3. allowed-tools list is present and non-empty
#   4. Skill has a title (# Skill: ...)
#
# Usage: ./tests/validate-skills.sh [plugin_root]
# Exit 0 = all valid, Exit 1 = errors found
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${1:-${CLAUDE_PLUGIN_ROOT:-.}}"
SKILLS_DIR="$PLUGIN_ROOT/skills"
ERRORS=0
CHECKED=0

if [ ! -d "$SKILLS_DIR" ]; then
  echo "ERROR: Skills directory not found: $SKILLS_DIR"
  exit 1
fi

for SKILL_FILE in "$SKILLS_DIR"/*/SKILL.md; do
  if [ ! -f "$SKILL_FILE" ]; then
    echo "WARNING: No SKILL.md files found in $SKILLS_DIR"
    exit 1
  fi

  SKILL_NAME=$(basename "$(dirname "$SKILL_FILE")")
  CHECKED=$((CHECKED + 1))

  # ── Check frontmatter delimiters ──────────────────────────────
  FIRST_LINE=$(head -1 "$SKILL_FILE")
  if [ "$FIRST_LINE" != "---" ]; then
    echo "ERROR [$SKILL_NAME]: Missing YAML frontmatter (first line must be ---)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Find closing delimiter (second ---)
  CLOSING_LINE=$(awk 'NR>1 && /^---$/{print NR; exit}' "$SKILL_FILE")
  if [ -z "$CLOSING_LINE" ]; then
    echo "ERROR [$SKILL_NAME]: Missing closing frontmatter delimiter (---)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Extract frontmatter content
  FRONTMATTER=$(sed -n "2,$((CLOSING_LINE - 1))p" "$SKILL_FILE")

  # ── Check context: fork ───────────────────────────────────────
  if ! echo "$FRONTMATTER" | grep -q '^context: fork'; then
    echo "ERROR [$SKILL_NAME]: Missing 'context: fork' in frontmatter"
    ERRORS=$((ERRORS + 1))
  fi

  # ── Check allowed-tools ───────────────────────────────────────
  if ! echo "$FRONTMATTER" | grep -q '^allowed-tools:'; then
    echo "ERROR [$SKILL_NAME]: Missing 'allowed-tools' in frontmatter"
    ERRORS=$((ERRORS + 1))
  else
    # Check that there's at least one tool listed
    TOOL_COUNT=$(echo "$FRONTMATTER" | grep -c '^ *- ' || true)
    if [ "$TOOL_COUNT" -eq 0 ]; then
      echo "ERROR [$SKILL_NAME]: 'allowed-tools' list is empty"
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # ── Check title ───────────────────────────────────────────────
  if ! grep -q '^# Skill:' "$SKILL_FILE"; then
    echo "ERROR [$SKILL_NAME]: Missing skill title (# Skill: ...)"
    ERRORS=$((ERRORS + 1))
  fi

  # ── Check invocable skills have Help block ──────────────────
  # Invocable skills (user-facing) should have a > **Help**: line
  if grep -qi '## Invocacion\|## Invocation' "$SKILL_FILE"; then
    if ! grep -q '> \*\*Help\*\*:' "$SKILL_FILE"; then
      echo "WARNING [$SKILL_NAME]: Invocable skill missing inline help (> **Help**: ...)"
    fi
  fi

  # ── Check worker skills have inputs/outputs ─────────────────
  # Worker skills (planner, implementer, reviewer, researcher) should
  # document what context they receive and what they produce
  if grep -qi '## Contexto que recibe\|## Context.*recei\|## Inputs' "$SKILL_FILE"; then
    # Has inputs section — check for outputs too
    if ! grep -qi '## Output\|## Formato del\|## Resultado' "$SKILL_FILE"; then
      echo "WARNING [$SKILL_NAME]: Has inputs section but missing outputs/format section"
    fi
  fi

  # ── Check output schema for skills with output section ──────
  # Skills that document output should use a structured format
  if grep -qi '^## Output' "$SKILL_FILE"; then
    if ! grep -q '```yaml\|```json\|```markdown' "$SKILL_FILE"; then
      echo "WARNING [$SKILL_NAME]: Output section exists but lacks structured format (yaml/json/markdown block)"
    fi
  fi
done

# ── Summary ─────────────────────────────────────────────────────
if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "FAILED: $ERRORS error(s) found in $CHECKED skill(s)"
  exit 1
else
  echo "OK: $CHECKED skill(s) validated successfully"
  exit 0
fi
