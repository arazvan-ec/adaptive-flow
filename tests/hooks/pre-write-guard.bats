#!/usr/bin/env bats
# Tests for hooks/pre-write-guard.sh
# Verifies sensitive file detection and Tier 3 guide suggestions

setup() {
  export TEST_DIR="$(mktemp -d)"
  export CLAUDE_PLUGIN_ROOT="$TEST_DIR"
  mkdir -p "$TEST_DIR/hooks"
  cp "$BATS_TEST_DIRNAME/../../hooks/lib.sh" "$TEST_DIR/hooks/lib.sh"

  HOOK="$BATS_TEST_DIRNAME/../../hooks/pre-write-guard.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset CLAUDE_PLUGIN_ROOT
}

# ── No file_path in input ────────────────────────────────────────

@test "allows write when no file_path in JSON" {
  run bash -c 'echo "{\"content\": \"hello\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
}

@test "allows write when input is empty" {
  run bash -c 'echo "{}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
}

# ── Normal files (no warnings) ───────────────────────────────────

@test "allows write to normal source file without warnings" {
  run bash -c 'echo "{\"file_path\": \"src/utils/helpers.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

# ── Sensitive file detection ─────────────────────────────────────

@test "warns on .env file" {
  run bash -c 'echo "{\"file_path\": \"config/.env\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING"* ]]
  [[ "$output" == *"sensitive"* ]]
}

@test "warns on credentials file" {
  run bash -c 'echo "{\"file_path\": \"config/credentials.json\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING"* ]]
}

@test "warns on .pem file" {
  run bash -c 'echo "{\"file_path\": \"certs/server.pem\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING"* ]]
}

@test "warns on token file" {
  run bash -c 'echo "{\"file_path\": \"auth/token.json\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING"* ]]
}

# ── Tier 3: Security guide suggestion ────────────────────────────

@test "suggests security guide for auth files" {
  run bash -c 'echo "{\"file_path\": \"src/auth/login.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"security-guide.md"* ]]
}

@test "suggests security guide for jwt files" {
  run bash -c 'echo "{\"file_path\": \"src/middleware/jwt-verify.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"security-guide.md"* ]]
}

# ── Tier 3: API patterns guide suggestion ────────────────────────

@test "suggests API guide for controller files" {
  run bash -c 'echo "{\"file_path\": \"src/controllers/userController.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"api-patterns.md"* ]]
}

@test "suggests API guide for route files" {
  run bash -c 'echo "{\"file_path\": \"src/routes/api.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"api-patterns.md"* ]]
}

@test "suggests API guide for middleware files" {
  run bash -c 'echo "{\"file_path\": \"src/middleware/cors.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"api-patterns.md"* ]]
}

# ── Tier 3: Testing guide suggestion ─────────────────────────────

@test "suggests testing guide for .test.ts files" {
  run bash -c 'echo "{\"file_path\": \"src/utils/helpers.test.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"testing-guide.md"* ]]
}

@test "suggests testing guide for .spec.js files" {
  run bash -c 'echo "{\"file_path\": \"tests/app.spec.js\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"testing-guide.md"* ]]
}

@test "suggests testing guide for _test.go files" {
  run bash -c 'echo "{\"file_path\": \"pkg/handler_test.go\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"testing-guide.md"* ]]
}

@test "suggests testing guide for test_*.py files" {
  run bash -c 'echo "{\"file_path\": \"tests/test_auth.py\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"testing-guide.md"* ]]
}

# ── Multiple suggestions ─────────────────────────────────────────

@test "suggests both security and API guide for auth controller" {
  run bash -c 'echo "{\"file_path\": \"src/controllers/authController.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"security-guide.md"* ]]
  [[ "$output" == *"api-patterns.md"* ]]
}

# ── JSON output ──────────────────────────────────────────────────

@test "outputs valid JSON with additionalContext for suggestions" {
  run bash -c 'echo "{\"file_path\": \"src/auth/login.ts\"}" | bash '"$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == "{"* ]]
  [[ "$output" == *"}" ]]
  [[ "$output" == *'"additionalContext"'* ]]
}
