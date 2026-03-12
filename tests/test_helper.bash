#!/usr/bin/env bash
# Common test helper for all BATS test files.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
TEMPLATES_DIR="${PROJECT_ROOT}/assets/templates"

# Create a fresh temporary directory for each test.
setup_tmpdir() {
  TEST_TMPDIR="$(mktemp -d)"
}

# Remove the temporary directory after each test.
teardown_tmpdir() {
  [[ -n "${TEST_TMPDIR:-}" && -d "$TEST_TMPDIR" ]] && rm -rf "$TEST_TMPDIR"
}

# Initialise a bare-bones Git repo in TEST_TMPDIR with an initial commit on main.
setup_git_repo() {
  setup_tmpdir
  git -C "$TEST_TMPDIR" init -b main >/dev/null 2>&1
  git -C "$TEST_TMPDIR" config user.email "test@test.com"
  git -C "$TEST_TMPDIR" config user.name "Test"
  touch "$TEST_TMPDIR/.gitkeep"
  git -C "$TEST_TMPDIR" add .gitkeep
  git -C "$TEST_TMPDIR" commit -m "initial" >/dev/null 2>&1
}

# Bootstrap shared-context files in the given directory (defaults to TEST_TMPDIR).
bootstrap_context() {
  local dir="${1:-$TEST_TMPDIR}"
  cp "$TEMPLATES_DIR/CONTEXT.md" "$dir/CONTEXT.md"
  cp "$TEMPLATES_DIR/TIMELINE.md" "$dir/TIMELINE.md"
}

setup_tracking_repo() {
  setup_tmpdir

  REMOTE_REPO_DIR="$TEST_TMPDIR/remote.git"
  TRACKING_REPO_DIR="$TEST_TMPDIR/repo"
  local seed_dir="$TEST_TMPDIR/seed"

  git init --bare "$REMOTE_REPO_DIR" >/dev/null 2>&1
  git -C "$REMOTE_REPO_DIR" symbolic-ref HEAD refs/heads/main
  git init -b main "$seed_dir" >/dev/null 2>&1
  git -C "$seed_dir" config user.email "test@test.com"
  git -C "$seed_dir" config user.name "Test"
  touch "$seed_dir/.gitkeep"
  git -C "$seed_dir" add .gitkeep
  git -C "$seed_dir" commit -m "initial" >/dev/null 2>&1
  git -C "$seed_dir" remote add origin "$REMOTE_REPO_DIR"
  git -C "$seed_dir" push -u origin main >/dev/null 2>&1

  git clone "$REMOTE_REPO_DIR" "$TRACKING_REPO_DIR" >/dev/null 2>&1
  git -C "$TRACKING_REPO_DIR" config user.email "test@test.com"
  git -C "$TRACKING_REPO_DIR" config user.name "Test"
}

push_remote_commit() {
  local file_name="$1"
  local file_content="$2"
  local commit_message="$3"
  local worktree_dir="$TEST_TMPDIR/remote-work"

  rm -rf "$worktree_dir"
  git clone "$REMOTE_REPO_DIR" "$worktree_dir" >/dev/null 2>&1
  git -C "$worktree_dir" config user.email "test@test.com"
  git -C "$worktree_dir" config user.name "Test"
  printf '%s\n' "$file_content" > "$worktree_dir/$file_name"
  git -C "$worktree_dir" add "$file_name"
  git -C "$worktree_dir" commit -m "$commit_message" >/dev/null 2>&1
  git -C "$worktree_dir" push origin main >/dev/null 2>&1
  rm -rf "$worktree_dir"
}
