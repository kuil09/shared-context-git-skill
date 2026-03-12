# Conflict Policy

This skill uses conservative Git behavior. When in doubt, stop instead of overwriting.

## Dirty Working Tree

If `git status --porcelain` is not empty:

- Do not run automatic sync steps that switch branches or fast-forward the base branch
- Review the local edits first
- Either commit them, stash them intentionally, or discard them intentionally outside this skill

## Diverged Base Branch

If the local base branch and `origin/<base-branch>` have both moved:

- Do not merge automatically
- Do not rebase automatically
- Read the remote changes and reconcile the Markdown manually
- Validate the result before committing again

## Local Base Ahead Of Remote

If the local base branch is ahead of the remote:

- Treat it as unpublished work, not safe sync state
- Push intentionally if policy allows, or move the work onto a branch and review it there

## Feature Branches

Branch-first is the default:

- Sync the base branch first
- Create a new context branch for your change
- Keep the branch focused on one topic when possible

If your feature branch becomes stale relative to the base branch:

- Reconcile intentionally
- Re-run validation after the reconcile step

## Conflicted Pulls Or Rebases

If Git reports conflicts:

- Stop editing automation
- Open the conflicting files and reconcile them manually
- Preserve both the latest verified facts and the latest unresolved questions
- Use a structured commit message if the reconcile materially changes the shared understanding
