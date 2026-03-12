# CTO-CMO Technical Marketing Sync Process

This document defines how the CTO and CMO collaborate to turn technical updates into marketing content and maintain alignment on messaging.

## 1. Tech Update → Marketing Content Workflow

```
CTO writes technical update
  → Posts to shared context branch (context/cto/*)
    → CMO reads and extracts marketable highlights
      → CMO drafts content (blog post, social, release note)
        → CTO reviews for technical accuracy
          → CMO publishes
```

### Handoff Format

When the CTO produces a technical update intended for marketing, use this structure in a `HANDOFF.md` entry:

| Field                | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| **What Changed**     | Technical summary of the feature, fix, or improvement        |
| **Why It Matters**   | User-facing impact in plain language                         |
| **Key Terms**        | Jargon that needs translation or careful framing             |
| **Suggested Angle**  | CTO's recommendation for how to position the update          |
| **Audience**         | Primary target (developers, end-users, enterprise, etc.)     |
| **Assets Available** | Screenshots, diagrams, benchmarks, demo links                |

### Content Types by Update Category

| Technical Update       | Marketing Output                  | Lead    |
| ---------------------- | --------------------------------- | ------- |
| New feature release    | Blog post + social thread         | CMO     |
| Bug fix / patch        | Release note (changelog only)     | CTO     |
| Architecture change    | Technical blog post               | CTO + CMO |
| Performance improvement| Benchmark post + social highlight | CMO     |
| Breaking change        | Migration guide + announcement    | CTO + CMO |

## 2. Biweekly Sync Meeting Agenda Template

**Cadence:** Every other week (격주), 30 minutes
**Participants:** CTO, CMO
**Channel:** Paperclip issue thread or dedicated sync issue

### Agenda

1. **Tech Pipeline Review** (10 min)
   - CTO shares upcoming releases and technical milestones
   - Flag items with marketing potential
   - Estimate release dates

2. **Content Pipeline Review** (10 min)
   - CMO shares content in draft, in review, or scheduled
   - CTO flags any accuracy concerns
   - Align on publishing timeline

3. **Shared Context Sync** (5 min)
   - Review open items in `CONTEXT.md` Active Context section
   - Update or archive stale decisions
   - Identify any diverged context branches needing merge

4. **Action Items** (5 min)
   - Each party leaves with no more than 2-3 concrete next steps
   - Record actions as Paperclip subtasks when trackable

### Post-Sync Ritual

After each sync, the CTO updates the shared context repo:
```bash
scripts/prepare_branch.sh --actor cto --slug cto-cmo-sync
# Update CONTEXT.md with decisions and active state
# Update TIMELINE.md with sync summary entry
scripts/validate_context.sh
```

## 3. Shared Context Document (DECISIONS.md) Usage

### Where to Record Decisions

Use `CONTEXT.md > Decisions` section for cross-functional decisions between CTO and CMO. Each entry follows this format:

```markdown
- **[YYYY-MM-DD] Decision title** — Brief rationale.
  Decided by: CTO + CMO. Revisit by: [date or "when X changes"].
```

### Decision Categories to Track

| Category              | Examples                                                  |
| --------------------- | --------------------------------------------------------- |
| Brand voice for tech  | "We say 'AI agents' not 'bots'" |
| Release cadence       | "Announce features on Tuesdays"                          |
| Content ownership     | "CTO owns API docs, CMO owns blog"                       |
| Tool choices          | "Use shared-context-git-skill for all cross-team context" |
| Audience targeting    | "Primary audience is developer tooling teams"             |

### Escalation

If CTO and CMO disagree on a decision, escalate to CEO via Paperclip issue with:
- Both positions summarized
- Impact of each option
- Recommended path forward

## 4. Tech Blog / Release Notes Collaboration Procedure

### Release Notes (every release)

1. CTO drafts release notes in a context branch with the changelog
2. CMO reviews for clarity and adds user-facing framing if needed
3. CTO merges after approval
4. CMO extracts highlights for social/newsletter if warranted

### Technical Blog Posts (as needed)

1. **Proposal:** Either party creates a Paperclip issue with:
   - Proposed topic and angle
   - Target audience
   - Estimated effort (draft, review, publish)

2. **Drafting:**
   - CTO writes technical substance
   - CMO adds introduction, conclusion, and accessibility edits
   - Both use a shared context branch for the draft

3. **Review cycle:**
   - CTO reviews for accuracy
   - CMO reviews for readability and brand alignment
   - Maximum 2 review rounds before publish decision

4. **Publishing:**
   - CMO handles scheduling and distribution
   - CTO updates project docs/README if the post references shipped features

### Naming Convention for Collaboration Branches

```
context/cto-cmo/YYYY-MM-DD-<slug>
```

Example: `context/cto-cmo/2026-03-12-v2-release-blog`
