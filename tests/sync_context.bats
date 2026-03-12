#!/usr/bin/env bats

load test_helper

setup() { setup_tracking_repo; }
teardown() { teardown_tmpdir; }

@test "sync_context fast-forwards when remote is ahead" {
  push_remote_commit "remote.txt" "from remote" "remote update"

  run "$SCRIPTS_DIR/sync_context.sh" --repo "$TRACKING_REPO_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Fast-forwarded main to origin/main"* ]]
  [ -f "$TRACKING_REPO_DIR/remote.txt" ]
}

@test "sync_context reports up to date when no changes exist" {
  run "$SCRIPTS_DIR/sync_context.sh" --repo "$TRACKING_REPO_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"main is already up to date with origin/main"* ]]
}

@test "sync_context fails on dirty working tree" {
  printf 'dirty\n' > "$TRACKING_REPO_DIR/dirty.txt"

  run "$SCRIPTS_DIR/sync_context.sh" --repo "$TRACKING_REPO_DIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Working tree is not clean"* ]]
}

@test "sync_context fails when local branch is ahead" {
  printf 'local\n' > "$TRACKING_REPO_DIR/local.txt"
  git -C "$TRACKING_REPO_DIR" add local.txt
  git -C "$TRACKING_REPO_DIR" commit -m "local change" >/dev/null 2>&1

  run "$SCRIPTS_DIR/sync_context.sh" --repo "$TRACKING_REPO_DIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Local main is ahead of origin/main"* ]]
}

@test "sync_context fails when local and remote have diverged" {
  push_remote_commit "remote.txt" "from remote" "remote update"
  printf 'local\n' > "$TRACKING_REPO_DIR/local.txt"
  git -C "$TRACKING_REPO_DIR" add local.txt
  git -C "$TRACKING_REPO_DIR" commit -m "local change" >/dev/null 2>&1

  run "$SCRIPTS_DIR/sync_context.sh" --repo "$TRACKING_REPO_DIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"have diverged"* ]]
}

@test "sync_context fails when current branch is not base branch" {
  git -C "$TRACKING_REPO_DIR" checkout -b feature >/dev/null 2>&1

  run "$SCRIPTS_DIR/sync_context.sh" --repo "$TRACKING_REPO_DIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Check out main before syncing"* ]]
}

@test "sync_context respects custom base branch" {
  git -C "$TRACKING_REPO_DIR" checkout -b develop >/dev/null 2>&1
  git -C "$TRACKING_REPO_DIR" push -u origin develop >/dev/null 2>&1
  git -C "$TRACKING_REPO_DIR" checkout develop >/dev/null 2>&1

  run "$SCRIPTS_DIR/sync_context.sh" --repo "$TRACKING_REPO_DIR" --base-branch develop

  [ "$status" -eq 0 ]
  [[ "$output" == *"develop is already up to date with origin/develop"* ]]
}

@test "sync_context fails when remote is missing" {
  run "$SCRIPTS_DIR/sync_context.sh" --repo "$TRACKING_REPO_DIR" --remote upstream

  [ "$status" -ne 0 ]
  [[ "$output" == *"Remote not found: upstream"* ]]
}

@test "sync_context fails when remote base branch is missing" {
  git -C "$TRACKING_REPO_DIR" checkout -b develop >/dev/null 2>&1

  run "$SCRIPTS_DIR/sync_context.sh" --repo "$TRACKING_REPO_DIR" --base-branch develop

  [ "$status" -ne 0 ]
  [[ "$output" == *"Remote branch not found: origin/develop"* ]]
}

@test "sync_context --help prints usage" {
  run "$SCRIPTS_DIR/sync_context.sh" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}
