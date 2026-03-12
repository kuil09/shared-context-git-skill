# Update Rules

These rules keep the shared context useful instead of noisy.

## Read-Before-Write

Before any edit:

1. Fetch or sync the repo
2. Read `CONTEXT.md`
3. Read recent `TIMELINE.md` entries
4. Read `HANDOFF.md` if it exists

Do not update the shared context from memory alone when the remote may have changed.

## What Belongs Where

- Put verified information in `Stable Facts` when it is expected to remain broadly true.
- Put current status, near-term focus, and live observations in `Active Context`.
- Put accepted choices in `Decisions`.
- Put uncertainty, missing evidence, and competing hypotheses in `Open Questions`.
- Put change history in `TIMELINE.md`, not in `CONTEXT.md`.

## Facts vs. Inference

Use explicit language:

- Fact: "The API returns HTTP 429 after 60 requests per minute."
- Inference: "This likely means the staging environment uses the default rate-limit tier."

Rules:

- If you did not verify it directly, do not present it as a stable fact.
- If a claim comes from another agent, keep it as active context or an open question until validated.
- When evidence is partial, name the evidence source or label the item as a hypothesis.

## When To Update

Update the shared context when at least one of these is true:

- A new verified fact changes how future work should proceed
- A decision has been made or reversed
- A meaningful blocker or risk has appeared
- A handoff would be incomplete without the new information

Avoid updates when:

- The change is only stylistic
- The note is still private scratch work
- The same point is already captured clearly elsewhere

## Compaction Guidance

Compaction is manual in v1. The goal is to reduce repetition without losing important facts.

Good compaction:

- Merge duplicate bullets that express the same fact
- Move stale items out of `Active Context` once they become stable or obsolete
- Rewrite long narrative sections into short, factual bullets
- Update `HANDOFF.md` to reflect only the latest next-step state

Bad compaction:

- Deleting unresolved questions because they are uncomfortable
- Rewriting history in `TIMELINE.md` to make the record cleaner
- Removing rationale from a decision that future agents will need
