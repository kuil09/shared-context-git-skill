---
name: shared-context-git-skill
description: Use when multiple AI agents need to share durable project context through a Git-backed remote repository. This skill standardizes how agents bootstrap a shared context repo, sync before reading or writing, record facts and decisions in Markdown, prepare branch-first updates, detect conflicts, and leave a clean handoff using only standard Git CLI and bundled Bash helpers.
license: MIT
compatibility: Requires git CLI. Works with any skills-compatible agent.
allowed-tools: "Bash(git:*) Bash(scripts/*) Read"
metadata:
  author: kuil09
  version: 1.0.0
---

# Shared Context Git Skill

Use this skill when agents need a shared, reviewable memory outside any single chat session.

The shared memory lives in a separate Git repository made of Markdown files. Agents read the latest context before work, update it when meaningful facts or decisions change, and use Git history as the review trail.

## Use This Skill For

- Bootstrapping a shared context repository with standard documents
- Syncing a local clone before reading or writing shared context
- Recording stable facts, active context, decisions, open questions, and handoffs
- Preparing branch-first context updates that can be reviewed as diffs
- Stopping safely when the local state is stale, dirty, or diverged

## Core Rules

1. Read before write. Fetch or sync first, then read `CONTEXT.md` before editing.
2. Keep shared memory in the repo, not only in session-local notes.
3. Prefer branch-first updates. Direct pushes to the default branch should be rare and explicitly justified.
4. Never overwrite conflicts automatically. If the repo is dirty or the branch has diverged, stop and reconcile.
5. Separate facts from inferences. Verified facts belong in the stable sections; uncertainty stays visible in open questions or clearly labeled hypotheses.
6. Add timeline entries only for meaningful changes. Avoid noisy logging for every minor thought.

## Recommended Workflow

1. If the repo does not exist yet, run `scripts/bootstrap_repo.sh`.
2. In a local clone of the shared context repo, run `scripts/sync_context.sh`.
3. Read `CONTEXT.md` and `HANDOFF.md` if present.
4. If you expect to share updates, run `scripts/prepare_branch.sh --actor <name> --slug <topic>`.
5. Update the Markdown files using the schema in [references/schema.md](references/schema.md).
6. Run `scripts/validate_context.sh`.
7. Review the diff and summarize the current state with `scripts/summarize_context.sh`.
8. Commit and push only when the context change is meaningful and accurate.

## Collaboration Modes

- Local draft only: sync, read, edit locally, validate, and stop without committing.
- Commit to branch and push: create a context branch, update docs, validate, commit, and push.
- PR proposal: do the Git work here, then hand off PR creation to provider-specific tooling outside this skill.

## Repo Shape

Required documents:

- `CONTEXT.md`

Optional documents:

- `HANDOFF.md`
- `POLICY.md`

Use the templates in `assets/templates/` and the detailed rules in the reference docs:

- [references/schema.md](references/schema.md)
- [references/update-rules.md](references/update-rules.md)
- [references/conflict-policy.md](references/conflict-policy.md)
- [references/handoff-guidelines.md](references/handoff-guidelines.md)
- [references/git-workflows.md](references/git-workflows.md)

## Script Guide

- `scripts/bootstrap_repo.sh`: create the initial document set from templates
- `scripts/check_divergence.sh`: report divergence of `context/*` branches from the base branch and flag stale branches
- `scripts/cleanup_branches.sh`: remove merged, older `context/*` branches locally and optionally on `origin`
- `scripts/sync_context.sh`: fetch remote changes and fast-forward the base branch when safe
- `scripts/prepare_branch.sh`: create or switch to a branch named `context/<actor>/<YYYY-MM-DD>-<slug>`
- `scripts/validate_context.sh`: check required files and headings
- `scripts/summarize_context.sh`: print a compact status summary and compaction hints

If a task needs host-specific PR creation or repo policy enforcement, keep this skill focused on the Git-native workflow and use separate tooling for the provider-specific step.
