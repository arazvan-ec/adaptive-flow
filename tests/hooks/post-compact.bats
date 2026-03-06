#!/usr/bin/env bats
# Tests for hooks/post-compact.sh
# Verifies post-compaction context re-injection

setup() {
  export TEST_DIR="$(mktemp -d)"
  export CLAUDE_PLUGIN_ROOT="$TEST_DIR"
  mkdir -p "$TEST_DIR/memory/current-task"
  mkdir -p "$TEST_DIR/hooks"
  cp "$BATS_TEST_DIRNAME/../../hooks/lib.sh" "$TEST_DIR/hooks/lib.sh"

  HOOK="$BATS_TEST_DIRNAME/../../hooks/post-compact.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset CLAUDE_PLUGIN_ROOT
}

# ── Basic output ─────────────────────────────────────────────────

@test "exits 0 and produces output" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "outputs JSON with additionalContext" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == "{"* ]]
  [[ "$output" == *'"additionalContext"'* ]]
}

# ── Routing table always present ─────────────────────────────────

@test "includes routing table in output" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Routing Table"* ]]
  [[ "$output" == *"Gravedad"* ]]
}

@test "includes all four severity levels" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"direct.md"* ]]
  [[ "$output" == *"plan-execute.md"* ]]
  [[ "$output" == *"full-cycle.md"* ]]
  [[ "$output" == *"shape-first.md"* ]]
}

# ── Memory pointers always present ───────────────────────────────

@test "includes memory pointers" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"user-insights.yaml"* ]]
  [[ "$output" == *"learnings.yaml"* ]]
  [[ "$output" == *"current-task"* ]]
}

# ── Current task meta injection ──────────────────────────────────

@test "includes current task meta when present" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: Implement OAuth
severity: 3
flow: full-cycle
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Current Task"* ]]
  [[ "$output" == *"Implement OAuth"* ]]
}

@test "works without current task meta file" {
  rm -f "$TEST_DIR/memory/current-task/meta.yaml"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Current Task"* ]]
}

# ── High-influence insights injection ────────────────────────────

@test "includes high-influence active insights when python3 and pyyaml available" {
  # Only run if python3 with yaml is available
  if ! python3 -c "import yaml" 2>/dev/null; then
    skip "python3 with pyyaml not available"
  fi

  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights:
  - id: USR-001
    observation: "Prefiere commits atomicos"
    influence: high
    status: active
  - id: USR-002
    observation: "Le gusta TypeScript"
    influence: medium
    status: active
  - id: USR-003
    observation: "Evita frameworks pesados"
    influence: high
    status: deprecated
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"High-Influence Insights"* ]]
  [[ "$output" == *"USR-001"* ]]
  [[ "$output" == *"Prefiere commits atomicos"* ]]
  # Medium influence should NOT appear
  [[ "$output" != *"USR-002"* ]]
  # Deprecated should NOT appear
  [[ "$output" != *"USR-003"* ]]
}

@test "works without insights file" {
  rm -f "$TEST_DIR/memory/user-insights.yaml"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"High-Influence Insights"* ]]
}

@test "works with empty insights file" {
  echo "" > "$TEST_DIR/memory/user-insights.yaml"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  # Should still have routing table
  [[ "$output" == *"Routing Table"* ]]
}

# ── Full context combination ─────────────────────────────────────

@test "combines routing + meta + insights in a single output" {
  if ! python3 -c "import yaml" 2>/dev/null; then
    skip "python3 with pyyaml not available"
  fi

  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: Add pagination
severity: 2
YAML

  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights:
  - id: USR-010
    observation: "Prefiere REST sobre GraphQL"
    influence: high
    status: active
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Routing Table"* ]]
  [[ "$output" == *"Add pagination"* ]]
  [[ "$output" == *"USR-010"* ]]
  [[ "$output" == *'"additionalContext"'* ]]
}

# ── CLAUDE_PLUGIN_ROOT fallback ──────────────────────────────────

@test "defaults to current dir when CLAUDE_PLUGIN_ROOT unset" {
  unset CLAUDE_PLUGIN_ROOT
  cd "$TEST_DIR"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Routing Table"* ]]
}
