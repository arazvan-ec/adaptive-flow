#!/usr/bin/env bats
# Tests for hooks/post-write-check.sh
# Verifies artifact validation for current-task files

setup() {
  export TEST_DIR="$(mktemp -d)"
  export CLAUDE_PLUGIN_ROOT="$TEST_DIR"
  mkdir -p "$TEST_DIR/memory/current-task"
  mkdir -p "$TEST_DIR/hooks"
  cp "$BATS_TEST_DIRNAME/../../hooks/lib.sh" "$TEST_DIR/hooks/lib.sh"

  HOOK="$BATS_TEST_DIRNAME/../../hooks/post-write-check.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset CLAUDE_PLUGIN_ROOT
}

# ── Files outside current-task ───────────────────────────────────

@test "ignores files outside current-task directory" {
  run bash -c 'echo "{\"file_path\": \"src/app.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
}

@test "ignores when no file_path in input" {
  run bash -c 'echo "{\"content\": \"hello\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
}

# ── spec.md validation ───────────────────────────────────────────

@test "warns when spec.md missing acceptance criteria" {
  SPEC="$TEST_DIR/memory/current-task/spec.md"
  cat > "$SPEC" <<'MD'
# Feature Spec
## Description
Some feature description
MD

  run bash -c 'echo "{\"file_path\": \"'"$SPEC"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Acceptance Criteria"* ]]
}

@test "passes when spec.md has acceptance criteria" {
  SPEC="$TEST_DIR/memory/current-task/spec.md"
  cat > "$SPEC" <<'MD'
# Feature Spec
## Acceptance Criteria
- User can log in
MD

  run bash -c 'echo "{\"file_path\": \"'"$SPEC"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"WARNING: spec.md missing"* ]]
}

@test "suggests out-of-scope section for spec.md" {
  SPEC="$TEST_DIR/memory/current-task/spec.md"
  cat > "$SPEC" <<'MD'
# Feature Spec
## Acceptance Criteria
- Done
MD

  run bash -c 'echo "{\"file_path\": \"'"$SPEC"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Out of Scope"* ]]
}

# ── design.md validation ─────────────────────────────────────────

@test "warns when design.md missing SOLID analysis" {
  DESIGN="$TEST_DIR/memory/current-task/design.md"
  cat > "$DESIGN" <<'MD'
# Design
## Architecture
Microservice approach
MD

  run bash -c 'echo "{\"file_path\": \"'"$DESIGN"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SOLID"* ]]
}

@test "passes when design.md has SOLID section" {
  DESIGN="$TEST_DIR/memory/current-task/design.md"
  cat > "$DESIGN" <<'MD'
# Design
## SOLID Analysis
- SRP: Each service has one responsibility
MD

  run bash -c 'echo "{\"file_path\": \"'"$DESIGN"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"WARNING: design.md"* ]]
}

# ── tasks.md validation ──────────────────────────────────────────

@test "warns when tasks.md has no checkboxes" {
  TASKS="$TEST_DIR/memory/current-task/tasks.md"
  cat > "$TASKS" <<'MD'
# Tasks
1. Do something
2. Do another thing
MD

  run bash -c 'echo "{\"file_path\": \"'"$TASKS"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"checkbox"* ]]
}

@test "passes when tasks.md has checkboxes" {
  TASKS="$TEST_DIR/memory/current-task/tasks.md"
  cat > "$TASKS" <<'MD'
# Tasks
- [ ] Do something
- [x] Already done
MD

  run bash -c 'echo "{\"file_path\": \"'"$TASKS"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"WARNING: tasks.md"* ]]
}

# ── plan-and-tasks.md validation ─────────────────────────────────

@test "warns when plan-and-tasks.md missing required sections" {
  PAT="$TEST_DIR/memory/current-task/plan-and-tasks.md"
  cat > "$PAT" <<'MD'
# Implementation
Just some notes
MD

  run bash -c 'echo "{\"file_path\": \"'"$PAT"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Acceptance Criteria"* ]]
  [[ "$output" == *"Plan"* ]]
  [[ "$output" == *"Tasks"* ]]
}

@test "passes when plan-and-tasks.md has all sections" {
  PAT="$TEST_DIR/memory/current-task/plan-and-tasks.md"
  cat > "$PAT" <<'MD'
# Plan and Tasks
## Acceptance Criteria
- Works
## Plan
Step by step
## Tasks
- [ ] Task 1
MD

  run bash -c 'echo "{\"file_path\": \"'"$PAT"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"WARNING: plan-and-tasks.md"* ]]
}

# ── JSON output ──────────────────────────────────────────────────

@test "outputs JSON with additionalContext for warnings" {
  SPEC="$TEST_DIR/memory/current-task/spec.md"
  echo "# Spec" > "$SPEC"

  run bash -c 'echo "{\"file_path\": \"'"$SPEC"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == "{"* ]]
  [[ "$output" == *'"additionalContext"'* ]]
}

@test "outputs empty JSON when no warnings" {
  SPEC="$TEST_DIR/memory/current-task/spec.md"
  cat > "$SPEC" <<'MD'
## Acceptance Criteria
- Done
## Out of Scope
- Nothing
MD

  run bash -c 'echo "{\"file_path\": \"'"$SPEC"'\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}
