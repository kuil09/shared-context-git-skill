#!/usr/bin/env bats

load test_helper

setup() { setup_tmpdir; }
teardown() { teardown_tmpdir; }

@test "bootstrap creates CONTEXT.md and TIMELINE.md by default" {
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR"
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMPDIR/CONTEXT.md" ]
  [ -f "$TEST_TMPDIR/TIMELINE.md" ]
  [[ "$output" == *"Created"* ]]
}

@test "bootstrap with --with-handoff creates HANDOFF.md" {
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR" --with-handoff
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMPDIR/HANDOFF.md" ]
}

@test "bootstrap with --with-policy creates POLICY.md" {
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR" --with-policy
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMPDIR/POLICY.md" ]
}

@test "bootstrap with all optional flags creates all 4 files" {
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR" --with-handoff --with-policy
  [ "$status" -eq 0 ]
  [ -f "$TEST_TMPDIR/CONTEXT.md" ]
  [ -f "$TEST_TMPDIR/TIMELINE.md" ]
  [ -f "$TEST_TMPDIR/HANDOFF.md" ]
  [ -f "$TEST_TMPDIR/POLICY.md" ]
}

@test "bootstrap refuses to overwrite existing files without --force" {
  "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR"
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Refusing to overwrite"* ]]
}

@test "bootstrap --force overwrites existing files" {
  "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR"
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR" --force
  [ "$status" -eq 0 ]
}

@test "bootstrap creates target directory if it does not exist" {
  local new_dir="$TEST_TMPDIR/subdir/nested"
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$new_dir"
  [ "$status" -eq 0 ]
  [ -f "$new_dir/CONTEXT.md" ]
}

@test "bootstrap warns when target is not a git repo" {
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"does not look like a Git repository"* ]]
}

@test "bootstrap does not warn when target is a git repo" {
  git -C "$TEST_TMPDIR" init -b main >/dev/null 2>&1
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR"
  [ "$status" -eq 0 ]
  [[ "$output" != *"does not look like a Git repository"* ]]
}

@test "bootstrap --help prints usage and exits 0" {
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "bootstrap unknown argument fails" {
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown argument"* ]]
}

@test "bootstrap --target with missing value fails" {
  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target
  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing value"* ]]
}

@test "bootstrap refuses to overwrite existing CONTEXT.md even when TIMELINE.md is absent" {
  # Only place CONTEXT.md in the target — TIMELINE.md is not there yet
  cp "$TEMPLATES_DIR/CONTEXT.md" "$TEST_TMPDIR/CONTEXT.md"

  run "$SCRIPTS_DIR/bootstrap_repo.sh" --target "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Refusing to overwrite"* ]]
  # TIMELINE.md should NOT have been created
  [ ! -f "$TEST_TMPDIR/TIMELINE.md" ]
}
