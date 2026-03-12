#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: prepare_branch.sh --actor NAME --slug TOPIC [--repo DIR] [--base-branch NAME] [--date YYYY-MM-DD]

Create or switch to a branch named context/<actor>/<YYYY-MM-DD>-<slug>.
Run this from a clean checkout of the base branch after syncing.
EOF
}

sanitize() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

repo_dir="."
base_branch="main"
actor=""
slug=""
date_value="$(date +%F)"

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
    --actor)
      [[ $# -ge 2 ]] || { echo "Missing value for --actor" >&2; exit 1; }
      actor="$2"
      shift 2
      ;;
    --slug)
      [[ $# -ge 2 ]] || { echo "Missing value for --slug" >&2; exit 1; }
      slug="$2"
      shift 2
      ;;
    --date)
      [[ $# -ge 2 ]] || { echo "Missing value for --date" >&2; exit 1; }
      date_value="$2"
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

[[ -n "$actor" ]] || { echo "--actor is required" >&2; exit 1; }
[[ -n "$slug" ]] || { echo "--slug is required" >&2; exit 1; }

safe_actor="$(sanitize "$actor")"
safe_slug="$(sanitize "$slug")"

[[ -n "$safe_actor" ]] || { echo "Actor must contain at least one letter or digit" >&2; exit 1; }
[[ -n "$safe_slug" ]] || { echo "Slug must contain at least one letter or digit" >&2; exit 1; }

branch_name="context/${safe_actor}/${date_value}-${safe_slug}"

cd "$repo_dir"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not a Git repository: $repo_dir" >&2
  exit 1
}

if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
  echo "Working tree is not clean. Commit or reconcile changes before preparing a branch." >&2
  exit 1
fi

current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$current_branch" != "$base_branch" ]]; then
  echo "Current branch is ${current_branch}. Check out ${base_branch} before preparing a context branch." >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
  git checkout "$branch_name"
  echo "Switched to existing branch ${branch_name}"
else
  git checkout -b "$branch_name"
  echo "Created and switched to ${branch_name}"
fi
