#!/usr/bin/env bats

load test_helper

setup() { setup_git_repo; }
teardown() { teardown_tmpdir; }

# Helper: create a context branch with N commits ahead of main
create_context_branch() {
  local branch_name="$1"
  local num_commits="${2:-1}"

  git -C "$TEST_TMPDIR" checkout -b "$branch_name" >/dev/null 2>&1
  for i in $(seq 1 "$num_commits"); do
    echo "change $i" > "$TEST_TMPDIR/file-${i}.txt"
    git -C "$TEST_TMPDIR" add "file-${i}.txt"
    git -C "$TEST_TMPDIR" commit -m "commit $i on $branch_name" >/dev/null 2>&1
  done
  git -C "$TEST_TMPDIR" checkout main >/dev/null 2>&1
}

# Helper: create a context branch with an old commit date
create_stale_context_branch() {
  local branch_name="$1"
  local days_ago="$2"
  local old_date
  old_date="$(date -v-${days_ago}d +%Y-%m-%dT12:00:00 2>/dev/null || date -d "${days_ago} days ago" +%Y-%m-%dT12:00:00)"

  git -C "$TEST_TMPDIR" checkout -b "$branch_name" >/dev/null 2>&1
  echo "stale content" > "$TEST_TMPDIR/stale.txt"
  git -C "$TEST_TMPDIR" add stale.txt
  GIT_AUTHOR_DATE="$old_date" GIT_COMMITTER_DATE="$old_date" \
    git -C "$TEST_TMPDIR" commit -m "stale commit" >/dev/null 2>&1
  git -C "$TEST_TMPDIR" checkout main >/dev/null 2>&1
}

@test "check_divergence --help prints usage" {
  run "$SCRIPTS_DIR/check_divergence.sh" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "check_divergence reports no branches when none exist" {
  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"No context/* branches found"* ]]
}

@test "check_divergence reports ok for branch within threshold" {
  create_context_branch "context/bot/2026-03-12-test" 3

  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR" --threshold 10

  [ "$status" -eq 0 ]
  [[ "$output" == *"context/bot/2026-03-12-test: ahead=3 behind=0 (ok)"* ]]
  [[ "$output" == *"All context branches are within acceptable divergence"* ]]
}

@test "check_divergence warns when branch exceeds threshold" {
  create_context_branch "context/bot/2026-03-12-diverged" 12

  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR" --threshold 10

  [ "$status" -eq 1 ]
  [[ "$output" == *"context/bot/2026-03-12-diverged: ahead=12 behind=0"* ]]
  [[ "$output" == *"WARNING"* ]]
}

@test "check_divergence detects stale branches" {
  create_stale_context_branch "context/bot/2026-01-01-old" 60

  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR" --stale-days 30

  [ "$status" -eq 1 ]
  [[ "$output" == *"[stale]"* ]]
  [[ "$output" == *"WARNING"* ]]
}

@test "check_divergence exits 0 when stale branch is within stale-days" {
  create_stale_context_branch "context/bot/2026-03-10-recent" 5

  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR" --stale-days 30

  [ "$status" -eq 0 ]
  [[ "$output" == *"(ok)"* ]]
}

@test "check_divergence reports behind count when main has advanced" {
  create_context_branch "context/bot/2026-03-12-behind" 1

  # Add commits to main after branching
  for i in $(seq 1 5); do
    echo "main change $i" > "$TEST_TMPDIR/main-${i}.txt"
    git -C "$TEST_TMPDIR" add "main-${i}.txt"
    git -C "$TEST_TMPDIR" commit -m "main commit $i" >/dev/null 2>&1
  done

  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR" --threshold 10

  [ "$status" -eq 0 ]
  [[ "$output" == *"ahead=1 behind=5 (ok)"* ]]
}

@test "check_divergence rejects invalid --threshold" {
  run "$SCRIPTS_DIR/check_divergence.sh" --threshold abc

  [ "$status" -ne 0 ]
  [[ "$output" == *"non-negative integer"* ]]
}

@test "check_divergence rejects invalid --stale-days" {
  run "$SCRIPTS_DIR/check_divergence.sh" --stale-days xyz

  [ "$status" -ne 0 ]
  [[ "$output" == *"non-negative integer"* ]]
}

@test "check_divergence fails when not a git repo" {
  local non_repo
  non_repo="$(mktemp -d)"

  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$non_repo"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Not a Git repository"* ]]
  rm -rf "$non_repo"
}

@test "check_divergence rejects unknown argument" {
  run "$SCRIPTS_DIR/check_divergence.sh" --unknown-flag

  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown argument"* ]]
}

@test "check_divergence fails when base branch does not exist" {
  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR" --base-branch nonexistent

  [ "$status" -ne 0 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "check_divergence respects custom --base-branch" {
  # Create a develop branch and a context branch off of it
  git -C "$TEST_TMPDIR" checkout -b develop >/dev/null 2>&1
  git -C "$TEST_TMPDIR" checkout -b "context/bot/2026-03-12-feature" >/dev/null 2>&1
  echo "change" > "$TEST_TMPDIR/feat.txt"
  git -C "$TEST_TMPDIR" add feat.txt
  git -C "$TEST_TMPDIR" commit -m "feat commit" >/dev/null 2>&1
  git -C "$TEST_TMPDIR" checkout develop >/dev/null 2>&1

  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR" --base-branch develop --threshold 10

  [ "$status" -eq 0 ]
  [[ "$output" == *"context/bot/2026-03-12-feature: ahead=1 behind=0 (ok)"* ]]
}

@test "check_divergence rejects --repo with missing value" {
  run "$SCRIPTS_DIR/check_divergence.sh" --repo

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing value for --repo"* ]]
}

@test "check_divergence rejects --base-branch with missing value" {
  run "$SCRIPTS_DIR/check_divergence.sh" --base-branch

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing value for --base-branch"* ]]
}

@test "check_divergence rejects --threshold with missing value" {
  run "$SCRIPTS_DIR/check_divergence.sh" --threshold

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing value for --threshold"* ]]
}

@test "check_divergence rejects --stale-days with missing value" {
  run "$SCRIPTS_DIR/check_divergence.sh" --stale-days

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing value for --stale-days"* ]]
}

@test "check_divergence warns when behind count exceeds threshold" {
  create_context_branch "context/bot/2026-03-12-behind-warn" 1

  # Add many commits to main so the context branch is far behind
  for i in $(seq 1 12); do
    echo "main change $i" > "$TEST_TMPDIR/main-extra-${i}.txt"
    git -C "$TEST_TMPDIR" add "main-extra-${i}.txt"
    git -C "$TEST_TMPDIR" commit -m "main commit $i" >/dev/null 2>&1
  done

  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR" --threshold 10

  [ "$status" -eq 1 ]
  [[ "$output" == *"ahead=1 behind=12"* ]]
  [[ "$output" == *"WARNING"* ]]
}

@test "check_divergence reports branch that is both stale and diverged" {
  local old_date
  old_date="$(date -v-60d +%Y-%m-%dT12:00:00 2>/dev/null || date -d "60 days ago" +%Y-%m-%dT12:00:00)"

  git -C "$TEST_TMPDIR" checkout -b "context/bot/2026-01-01-stale-diverged" >/dev/null 2>&1
  for i in $(seq 1 12); do
    echo "change $i" > "$TEST_TMPDIR/sd-${i}.txt"
    git -C "$TEST_TMPDIR" add "sd-${i}.txt"
    GIT_AUTHOR_DATE="$old_date" GIT_COMMITTER_DATE="$old_date" \
      git -C "$TEST_TMPDIR" commit -m "old commit $i" >/dev/null 2>&1
  done
  git -C "$TEST_TMPDIR" checkout main >/dev/null 2>&1

  run "$SCRIPTS_DIR/check_divergence.sh" --repo "$TEST_TMPDIR" --threshold 10 --stale-days 30

  [ "$status" -eq 1 ]
  [[ "$output" == *"[stale]"* ]]
  [[ "$output" == *"WARNING"* ]]
}
