#!/usr/bin/env bats

load test_helper

setup() { setup_tmpdir; }
teardown() { teardown_tmpdir; }

@test "validate_context accepts bootstrapped template state" {
  bootstrap_context

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Shared context structure is valid"* ]]
}

@test "validate_context rejects missing required context heading" {
  bootstrap_context
  python3 - <<'PY' "$TEST_TMPDIR/CONTEXT.md"
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace("## Decisions\n\n", "", 1))
PY

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"CONTEXT.md is missing required heading matching: ^## Decisions$"* ]]
}

@test "validate_context --help prints usage" {
  run "$SCRIPTS_DIR/validate_context.sh" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "validate_context rejects unknown argument" {
  run "$SCRIPTS_DIR/validate_context.sh" --unknown-flag

  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown argument"* ]]
}

@test "validate_context fails when CONTEXT.md is missing" {
  setup_tmpdir

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing CONTEXT.md"* ]]
}

@test "validate_context rejects --repo with missing value" {
  run "$SCRIPTS_DIR/validate_context.sh" --repo

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing value for --repo"* ]]
}

@test "validate_context rejects missing Stable Facts heading" {
  bootstrap_context
  python3 - <<'PY' "$TEST_TMPDIR/CONTEXT.md"
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace("## Stable Facts\n\n", "", 1))
PY

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"CONTEXT.md is missing required heading matching: ^## Stable Facts$"* ]]
}

@test "validate_context passes when CONTEXT.md has duplicate required heading" {
  bootstrap_context
  # Add a second ## Decisions heading — grep -Eq still finds the pattern, so should pass
  printf '\n## Decisions\n\n- Duplicate section\n' >> "$TEST_TMPDIR/CONTEXT.md"

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Shared context structure is valid"* ]]
}
