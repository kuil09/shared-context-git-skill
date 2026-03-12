# Shared Context Schema

This skill uses a small, predictable document model so agents can read and update the shared context consistently.

## Required Files

- `CONTEXT.md`
- `TIMELINE.md`

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

## `TIMELINE.md`

`TIMELINE.md` is append-only history for meaningful context changes. New entries go at the top or bottom of the `Entries` section as long as the team is consistent. Do not rewrite old entries except to fix clear factual mistakes.

Required structure:

```markdown
# Timeline

## Entry Template
### 2026-03-12T09:15:00Z | agent-name
- Timestamp: 2026-03-12T09:15:00Z
- Actor: agent-name
- Trigger: What caused this update
- Applied Changes:
  - Bullet summary
- Unresolved Items:
  - Bullet summary or `- None`

## Entries
```

Entry rules:

- Each real entry uses a `### <timestamp> | <actor>` heading
- Each entry must include `Timestamp`, `Actor`, `Trigger`, `Applied Changes`, and `Unresolved Items`
- `Actor` must be human-readable; tool or model metadata is optional
- `Applied Changes` should summarize the actual change, not just the intent

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
