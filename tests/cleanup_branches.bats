#!/usr/bin/env bats

load test_helper

OLD_DATE="2020-01-15T12:00:00Z"

setup() { setup_tracking_repo; }
teardown() { teardown_tmpdir; }

create_context_branch_commit() {
  local branch_name="$1"
  local file_name="$2"
  local file_content="$3"
  local commit_date="${4:-}"

  git -C "$TRACKING_REPO_DIR" checkout -b "$branch_name" >/dev/null 2>&1
  printf '%s\n' "$file_content" > "$TRACKING_REPO_DIR/$file_name"
  git -C "$TRACKING_REPO_DIR" add "$file_name"

  if [[ -n "$commit_date" ]]; then
    GIT_AUTHOR_DATE="$commit_date" GIT_COMMITTER_DATE="$commit_date" \
      git -C "$TRACKING_REPO_DIR" commit -m "add $branch_name" >/dev/null 2>&1
  else
    git -C "$TRACKING_REPO_DIR" commit -m "add $branch_name" >/dev/null 2>&1
  fi
}

merge_context_branch_into_main() {
  local branch_name="$1"

  git -C "$TRACKING_REPO_DIR" checkout main >/dev/null 2>&1
  git -C "$TRACKING_REPO_DIR" merge --ff-only "$branch_name" >/dev/null 2>&1
}

@test "cleanup_branches deletes merged local context branches older than threshold" {
  create_context_branch_commit "context/alice/2020-01-15-old-local" "old-local.txt" "old local" "$OLD_DATE"
  merge_context_branch_into_main "context/alice/2020-01-15-old-local"

  run "$SCRIPTS_DIR/cleanup_branches.sh" --repo "$TRACKING_REPO_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted local branch: context/alice/2020-01-15-old-local"* ]]
  [[ "$output" == *"Total: 1 branch(es) deleted."* ]]
  run git -C "$TRACKING_REPO_DIR" rev-parse --verify "context/alice/2020-01-15-old-local"
  [ "$status" -ne 0 ]
}

@test "cleanup_branches dry-run reports deletions without removing branches" {
  create_context_branch_commit "context/alice/2020-01-15-dry-run" "dry-run.txt" "dry run" "$OLD_DATE"
  merge_context_branch_into_main "context/alice/2020-01-15-dry-run"

  run "$SCRIPTS_DIR/cleanup_branches.sh" --repo "$TRACKING_REPO_DIR" --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run] Would delete: context/alice/2020-01-15-dry-run"* ]]
  [[ "$output" == *"Total: 1 branch(es) would be deleted."* ]]
  run git -C "$TRACKING_REPO_DIR" rev-parse --verify "context/alice/2020-01-15-dry-run"
  [ "$status" -eq 0 ]
}

@test "cleanup_branches skips recent merged context branches" {
  create_context_branch_commit "context/alice/2026-03-12-recent" "recent.txt" "recent branch"
  merge_context_branch_into_main "context/alice/2026-03-12-recent"

  run "$SCRIPTS_DIR/cleanup_branches.sh" --repo "$TRACKING_REPO_DIR" --days 30

  [ "$status" -eq 0 ]
  [[ "$output" == *"No context branches to clean up."* ]]
  run git -C "$TRACKING_REPO_DIR" rev-parse --verify "context/alice/2026-03-12-recent"
  [ "$status" -eq 0 ]
}

@test "cleanup_branches skips unmerged context branches" {
  create_context_branch_commit "context/alice/2020-01-15-unmerged" "unmerged.txt" "unmerged branch" "$OLD_DATE"
  git -C "$TRACKING_REPO_DIR" checkout main >/dev/null 2>&1

  run "$SCRIPTS_DIR/cleanup_branches.sh" --repo "$TRACKING_REPO_DIR" --days 0

  [ "$status" -eq 0 ]
  [[ "$output" == *"No context branches to clean up."* ]]
  run git -C "$TRACKING_REPO_DIR" rev-parse --verify "context/alice/2020-01-15-unmerged"
  [ "$status" -eq 0 ]
}

@test "cleanup_branches deletes merged remote context branches when requested" {
  create_context_branch_commit "context/alice/2020-01-15-old-remote" "old-remote.txt" "old remote" "$OLD_DATE"
  git -C "$TRACKING_REPO_DIR" push -u origin "context/alice/2020-01-15-old-remote" >/dev/null 2>&1
  merge_context_branch_into_main "context/alice/2020-01-15-old-remote"
  git -C "$TRACKING_REPO_DIR" push origin main >/dev/null 2>&1
  git -C "$TRACKING_REPO_DIR" branch -D "context/alice/2020-01-15-old-remote" >/dev/null 2>&1

  run "$SCRIPTS_DIR/cleanup_branches.sh" --repo "$TRACKING_REPO_DIR" --remote

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted remote branch: origin/context/alice/2020-01-15-old-remote"* ]]
  [[ "$output" == *"Total: 1 branch(es) deleted."* ]]
  run git -C "$TRACKING_REPO_DIR" ls-remote --heads origin "context/alice/2020-01-15-old-remote"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "cleanup_branches rejects invalid --days values" {
  run "$SCRIPTS_DIR/cleanup_branches.sh" --repo "$TRACKING_REPO_DIR" --days nope

  [ "$status" -ne 0 ]
  [[ "$output" == *"--days must be a non-negative integer"* ]]
}

@test "cleanup_branches --help prints usage" {
  run "$SCRIPTS_DIR/cleanup_branches.sh" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}
