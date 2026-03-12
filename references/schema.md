# Shared Context Schema

This skill uses a small, predictable document model so agents can read and update the shared context consistently.

## Required Files

- `CONTEXT.md`

## Optional Files

- `HANDOFF.md`
- `POLICY.md`

## `CONTEXT.md`

`CONTEXT.md` is the compact, current-state view. It should stay readable in one pass and prefer synthesis over raw history.

Required headings:

```markdown
# Shared Context

## Overview
## Stable Facts
## Active Context
## Decisions
## Open Questions
```

Section intent:

- `Overview`: short summary of the project or workstream this repo represents
- `Stable Facts`: verified statements that should remain true until contradicted by new evidence
- `Active Context`: current work state, near-term focus, and relevant recent observations
- `Decisions`: accepted decisions with brief rationale when useful
- `Open Questions`: unresolved issues, assumptions to validate, and explicit hypotheses

## `HANDOFF.md`

Use `HANDOFF.md` only for what the next agent needs immediately. It should be short and current.

Recommended headings:

```markdown
# Handoff

## What Changed
## What Is True Now
## What Is Uncertain
## Recommended Next Step
```

## `POLICY.md`

Use `POLICY.md` for team-specific rules such as who may write to the default branch, when PR review is required, or what counts as a meaningful update.
