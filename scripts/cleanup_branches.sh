#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: cleanup_branches.sh [--repo DIR] [--base-branch NAME] [--days N] [--dry-run] [--remote]

Delete merged context/* branches from the local repository.

Options:
  --repo DIR          Repository path (default: .)
  --base-branch NAME  Base branch to check merge status against (default: main)
  --days N            Only target branches older than N days (default: 30)
  --dry-run           Print branches that would be deleted without deleting
  --remote            Also delete matching remote branches (origin)
  -h, --help          Show this help message
EOF
}

repo_dir="."
base_branch="main"
max_days=30
dry_run=false
delete_remote=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || { echo "Missing value for --repo" >&2; exit 1; }
      repo_dir="$2"
      shift 2
      ;;
    --base-branch)
      [[ $# -ge 2 ]] || { echo "Missing value for --base-branch" >&2; exit 1; }
      base_branch="$2"
      shift 2
      ;;
    --days)
      [[ $# -ge 2 ]] || { echo "Missing value for --days" >&2; exit 1; }
      max_days="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --remote)
      delete_remote=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! [[ "$max_days" =~ ^[0-9]+$ ]]; then
  echo "--days must be a non-negative integer" >&2
  exit 1
fi

cd "$repo_dir"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not a Git repository: $repo_dir" >&2
  exit 1
}

git rev-parse --verify --quiet "refs/heads/${base_branch}" >/dev/null 2>&1 || {
  echo "Base branch '${base_branch}' does not exist" >&2
  exit 1
}

current_branch="$(git rev-parse --abbrev-ref HEAD)"
cutoff_epoch=$(( $(date +%s) - max_days * 86400 ))
deleted_count=0

# Get local context/* branches that are fully merged into base_branch
while IFS= read -r branch; do
  [[ -n "$branch" ]] || continue
  branch="${branch#"${branch%%[![:space:]]*}"}"

  # Never delete the current branch or the base branch
  [[ "$branch" != "$current_branch" ]] || continue
  [[ "$branch" != "$base_branch" ]] || continue

  # Check branch age via last commit date
  commit_epoch="$(git log -1 --format='%ct' "$branch" 2>/dev/null)" || continue
  if (( commit_epoch > cutoff_epoch )); then
    continue
  fi

  if $dry_run; then
    echo "[dry-run] Would delete: $branch"
  else
    git branch -D "$branch" >/dev/null 2>&1
    echo "Deleted local branch: $branch"
  fi
  deleted_count=$((deleted_count + 1))
done < <(git branch --merged "$base_branch" --list 'context/*' --format='%(refname:short)')

# Handle remote branches if --remote is set
if $delete_remote; then
  remote="origin"
  while IFS= read -r ref; do
    [[ -n "$ref" ]] || continue
    ref="${ref#"${ref%%[![:space:]]*}"}"
    # ref looks like "origin/context/actor/date-slug"
    branch="${ref#${remote}/}"

    # Never delete remote tracking for current or base branch
    [[ "$branch" != "$current_branch" ]] || continue
    [[ "$branch" != "$base_branch" ]] || continue

    # Check age
    commit_epoch="$(git log -1 --format='%ct' "$ref" 2>/dev/null)" || continue
    if (( commit_epoch > cutoff_epoch )); then
      continue
    fi

    # Check if merged into base
    if ! git merge-base --is-ancestor "$ref" "$base_branch" 2>/dev/null; then
      continue
    fi

    if $dry_run; then
      echo "[dry-run] Would delete remote: ${remote}/${branch}"
    else
      git push "$remote" --delete "$branch" >/dev/null 2>&1
      echo "Deleted remote branch: ${remote}/${branch}"
    fi
    deleted_count=$((deleted_count + 1))
  done < <(git branch -r --list "${remote}/context/*" --format='%(refname:short)')
fi

if (( deleted_count == 0 )); then
  echo "No context branches to clean up."
else
  if $dry_run; then
    echo "Total: ${deleted_count} branch(es) would be deleted."
  else
    echo "Total: ${deleted_count} branch(es) deleted."
  fi
fi
