#!/usr/bin/env bats

load test_helper

setup() { setup_git_repo; }
teardown() { teardown_tmpdir; }

@test "prepare_branch creates context branch with correct name" {
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "alice" --slug "feature" --date "2026-01-15"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Created and switched to context/alice/2026-01-15-feature"* ]]
  branch="$(git -C "$TEST_TMPDIR" rev-parse --abbrev-ref HEAD)"
  [ "$branch" = "context/alice/2026-01-15-feature" ]
}

@test "prepare_branch switches to existing branch" {
  "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "alice" --slug "feat" --date "2026-01-15"
  git -C "$TEST_TMPDIR" checkout main >/dev/null 2>&1
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "alice" --slug "feat" --date "2026-01-15"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Switched to existing branch"* ]]
}

@test "prepare_branch sanitizes actor to lowercase and replaces special chars" {
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "John Doe" --slug "test" --date "2026-01-15"
  [ "$status" -eq 0 ]
  branch="$(git -C "$TEST_TMPDIR" rev-parse --abbrev-ref HEAD)"
  [ "$branch" = "context/john-doe/2026-01-15-test" ]
}

@test "prepare_branch sanitizes slug" {
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "bot" --slug "My Feature!!" --date "2026-01-15"
  [ "$status" -eq 0 ]
  branch="$(git -C "$TEST_TMPDIR" rev-parse --abbrev-ref HEAD)"
  [ "$branch" = "context/bot/2026-01-15-my-feature" ]
}

@test "prepare_branch fails when actor is missing" {
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --slug "test"
  [ "$status" -ne 0 ]
  [[ "$output" == *"--actor is required"* ]]
}

@test "prepare_branch fails when slug is missing" {
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "alice"
  [ "$status" -ne 0 ]
  [[ "$output" == *"--slug is required"* ]]
}

@test "prepare_branch fails when actor sanitizes to empty" {
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "!!!" --slug "test"
  [ "$status" -ne 0 ]
  [[ "$output" == *"at least one letter or digit"* ]]
}

@test "prepare_branch fails when slug sanitizes to empty" {
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "alice" --slug "!!!"
  [ "$status" -ne 0 ]
  [[ "$output" == *"at least one letter or digit"* ]]
}

@test "prepare_branch fails on dirty working tree" {
  echo "dirty" > "$TEST_TMPDIR/dirty.txt"
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "alice" --slug "test"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not clean"* ]]
}

@test "prepare_branch fails when not on base branch" {
  git -C "$TEST_TMPDIR" checkout -b other >/dev/null 2>&1
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "alice" --slug "test"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Check out main"* ]]
}

@test "prepare_branch fails when not a git repo" {
  local nongit="$(mktemp -d)"
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$nongit" --actor "alice" --slug "test"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Not a Git repository"* ]]
  rm -rf "$nongit"
}

@test "prepare_branch --help prints usage" {
  run "$SCRIPTS_DIR/prepare_branch.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "prepare_branch respects custom --base-branch" {
  git -C "$TEST_TMPDIR" checkout -b develop >/dev/null 2>&1
  run "$SCRIPTS_DIR/prepare_branch.sh" --repo "$TEST_TMPDIR" --actor "alice" --slug "test" --base-branch "develop" --date "2026-01-15"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Created and switched to"* ]]
}
