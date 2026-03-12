# Handoff Guidelines

`HANDOFF.md` is optional, but it is the fastest way for the next agent to resume work without replaying every timeline entry.

## Keep It Short

A good handoff is current, not comprehensive. If it grows long, move durable material into `CONTEXT.md` and trim the handoff back down.

## Required Content

Cover these four points:

1. What changed
2. What is true now
3. What is uncertain
4. Recommended next step

## Writing Tips

- Write in present tense when possible
- Prefer direct bullets over narrative paragraphs
- Include enough detail for the next agent to start immediately
- Name the blocking uncertainty instead of hiding it

## Example Shape

```markdown
# Handoff

## What Changed
- Added verified API rate-limit notes to `CONTEXT.md`
- Committed the update with a structured context message

## What Is True Now
- The shared repo has the latest staging findings
- The frontend impact is still not assessed

## What Is Uncertain
- Whether production has the same rate-limit tier
- Whether retries should be client- or server-side

## Recommended Next Step
- Verify the production tier and decide retry ownership
```
