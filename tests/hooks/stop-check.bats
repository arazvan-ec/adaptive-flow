#!/usr/bin/env bats
# Tests for hooks/stop-check.sh
# Verifies compound-capture enforcement for gravity 3+ tasks

setup() {
  export TEST_DIR="$(mktemp -d)"
  export CLAUDE_PLUGIN_ROOT="$TEST_DIR"
  mkdir -p "$TEST_DIR/memory/current-task"

  HOOK="$BATS_TEST_DIRNAME/../../hooks/stop-check.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset CLAUDE_PLUGIN_ROOT
}

# ── No active task ───────────────────────────────────────────────

@test "allows stop when no meta.yaml exists" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

# ── Low gravity tasks ────────────────────────────────────────────

@test "allows stop for gravity 1 tasks" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: small-fix
gravity: 1
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

@test "allows stop for gravity 2 tasks" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: medium-task
gravity: 2
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

# ── High gravity tasks without compound-capture ──────────────────

@test "blocks stop for gravity 3 without retrospective" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"decision": "block"'* ]]
  [[ "$output" == *"compound-capture"* ]]
  [[ "$output" == *"gravity 3"* ]]
}

@test "blocks stop for gravity 4 without retrospective" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: complex-refactor
gravity: 4
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"decision": "block"'* ]]
  [[ "$output" == *"gravity 4"* ]]
}

# ── High gravity with compound-capture done ──────────────────────

@test "allows stop for gravity 3 when retrospective exists" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML
  touch "$TEST_DIR/memory/current-task/retrospective.md"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

# ── Infinite loop prevention ─────────────────────────────────────

@test "blocks first and second stop attempt" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML

  # First block
  run bash "$HOOK"
  [[ "$output" == *'"decision": "block"'* ]]

  # Second block
  run bash "$HOOK"
  [[ "$output" == *'"decision": "block"'* ]]
}

@test "allows stop after 2 blocks (infinite loop prevention)" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML
  # Simulate 2 previous blocks
  echo "2" > "$TEST_DIR/memory/current-task/.stop-block-count"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

@test "cleans up counter file after allowing forced stop" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML
  echo "2" > "$TEST_DIR/memory/current-task/.stop-block-count"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/memory/current-task/.stop-block-count" ]
}

# ── Malformed meta.yaml ──────────────────────────────────────────

@test "crashes on missing gravity field (bug: set -e + grep no match, fix in Track A)" {
  # BUG: set -euo pipefail causes script to crash when grep finds no gravity line.
  # The default-to-3 logic never runs because the pipeline exits first.
  # Track A (lib.sh refactor) will fix this by using a safer parsing function.
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: unknown-task
status: in_progress
YAML

  run bash "$HOOK"
  [ "$status" -ne 0 ]
}

@test "crashes on non-numeric gravity (bug: set -e + grep no match, fix in Track A)" {
  # Same bug as above: grep -E '^gravity:\s*[0-9]+' returns no match for 'gravity: high'
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: broken
gravity: high
YAML

  run bash "$HOOK"
  [ "$status" -ne 0 ]
}
