# Git Workflows

This skill standardizes when agents read, branch, validate, and share updates. It does not replace normal Git review practices.

## Local Draft Only

Use this when you are still exploring or the update is not ready to share.

1. Open or clone the shared context repo
2. Run `scripts/sync_context.sh`
3. Read the current context files
4. Edit locally
5. Run `scripts/validate_context.sh`
6. Review `git diff`
7. Stop without committing if the notes are still private or provisional

## Commit To Branch And Push

Use this when the update is meaningful and ready for review or shared use.

1. Run `scripts/sync_context.sh`
2. Run `scripts/prepare_branch.sh --actor <name> --slug <topic>`
3. Edit the context files
4. Run `scripts/validate_context.sh`
5. Review `git diff`
6. Commit with a focused message
7. Push the branch

## PR Proposal

The skill supports a PR proposal workflow boundary, but PR creation itself is outside the core automation.

Recommended pattern:

1. Do the normal branch workflow
2. Capture the proposed review summary in your agent response or commit message
3. Use provider-specific tooling outside this skill to open the PR

Examples of provider-specific tooling:

- GitHub CLI or web UI
- GitLab CLI or web UI
- Bitbucket web UI

Keep the actual context management generic so the same repo can work with any Git host.
