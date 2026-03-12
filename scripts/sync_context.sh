#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sync_context.sh [--repo DIR] [--remote NAME] [--base-branch NAME]

Fetch the remote and fast-forward the local base branch when it is safe to do so.
This script refuses to proceed on dirty state, detached HEAD, divergence, or unpublished base-branch commits.
EOF
}

repo_dir="."
remote_name="origin"
base_branch="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || { echo "Missing value for --repo" >&2; exit 1; }
      repo_dir="$2"
      shift 2
      ;;
    --remote)
      [[ $# -ge 2 ]] || { echo "Missing value for --remote" >&2; exit 1; }
      remote_name="$2"
      shift 2
      ;;
    --base-branch)
      [[ $# -ge 2 ]] || { echo "Missing value for --base-branch" >&2; exit 1; }
      base_branch="$2"
      shift 2
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

cd "$repo_dir"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not a Git repository: $repo_dir" >&2
  exit 1
}

if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
  echo "Working tree is not clean. Reconcile local changes before syncing." >&2
  exit 1
fi

current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$current_branch" == "HEAD" ]]; then
  echo "Detached HEAD is not supported for sync. Check out ${base_branch} first." >&2
  exit 1
fi

if [[ "$current_branch" != "$base_branch" ]]; then
  echo "Current branch is ${current_branch}. Check out ${base_branch} before syncing." >&2
  exit 1
fi

git remote get-url "$remote_name" >/dev/null 2>&1 || {
  echo "Remote not found: $remote_name" >&2
  exit 1
}

git fetch --prune "$remote_name"

git show-ref --verify --quiet "refs/remotes/${remote_name}/${base_branch}" || {
  echo "Remote branch not found: ${remote_name}/${base_branch}" >&2
  exit 1
}

read -r ahead behind <<<"$(git rev-list --left-right --count "${base_branch}...${remote_name}/${base_branch}")"

if [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
  echo "Local ${base_branch} and ${remote_name}/${base_branch} have diverged. Reconcile manually." >&2
  exit 1
fi

if [[ "$ahead" -gt 0 ]]; then
  echo "Local ${base_branch} is ahead of ${remote_name}/${base_branch}. Push or move the work intentionally." >&2
  exit 1
fi

if [[ "$behind" -gt 0 ]]; then
  git merge --ff-only "${remote_name}/${base_branch}"
  echo "Fast-forwarded ${base_branch} to ${remote_name}/${base_branch}"
else
  echo "${base_branch} is already up to date with ${remote_name}/${base_branch}"
fi
