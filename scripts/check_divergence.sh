#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check_divergence.sh [--repo DIR] [--base-branch NAME] [--threshold N] [--stale-days N]

Report divergence of context/* branches from the base branch.

Options:
  --repo DIR          Repository path (default: .)
  --base-branch NAME  Base branch to compare against (default: main)
  --threshold N       Warn if a branch is N+ commits ahead or behind (default: 10)
  --stale-days N      Report branches with no commits in N+ days (default: 30)
  -h, --help          Show this help message

Exit codes:
  0  No warnings
  1  One or more branches exceed the divergence threshold or are stale
EOF
}

repo_dir="."
base_branch="main"
threshold=10
stale_days=30

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
    --threshold)
      [[ $# -ge 2 ]] || { echo "Missing value for --threshold" >&2; exit 1; }
      threshold="$2"
      shift 2
      ;;
    --stale-days)
      [[ $# -ge 2 ]] || { echo "Missing value for --stale-days" >&2; exit 1; }
      stale_days="$2"
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

if ! [[ "$threshold" =~ ^[0-9]+$ ]]; then
  echo "--threshold must be a non-negative integer" >&2
  exit 1
fi

if ! [[ "$stale_days" =~ ^[0-9]+$ ]]; then
  echo "--stale-days must be a non-negative integer" >&2
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

cutoff_epoch=$(( $(date +%s) - stale_days * 86400 ))
has_warnings=0
branch_count=0

while IFS= read -r branch; do
  [[ -n "$branch" ]] || continue
  branch="${branch#"${branch%%[![:space:]]*}"}"
  branch_count=$((branch_count + 1))

  merge_base="$(git merge-base "$base_branch" "$branch" 2>/dev/null)" || continue
  ahead="$(git rev-list --count "${merge_base}..${branch}" 2>/dev/null)" || ahead=0
  behind="$(git rev-list --count "${merge_base}..${base_branch}" 2>/dev/null)" || behind=0

  commit_epoch="$(git log -1 --format='%ct' "$branch" 2>/dev/null)" || commit_epoch=0

  diverged=0
  stale=0

  if (( ahead >= threshold || behind >= threshold )); then
    diverged=1
    has_warnings=1
  fi

  if (( commit_epoch > 0 && commit_epoch < cutoff_epoch )); then
    stale=1
    has_warnings=1
  fi

  if (( diverged || stale )); then
    printf '%s: ahead=%d behind=%d' "$branch" "$ahead" "$behind"
    if (( stale )); then
      printf ' [stale]'
    fi
    printf '\n'
  else
    printf '%s: ahead=%d behind=%d (ok)\n' "$branch" "$ahead" "$behind"
  fi
done < <(git branch --list 'context/*' --format='%(refname:short)')

if (( branch_count == 0 )); then
  echo "No context/* branches found."
  exit 0
fi

if (( has_warnings )); then
  echo "WARNING: One or more context branches are diverged or stale."
  exit 1
else
  echo "All context branches are within acceptable divergence."
  exit 0
fi
