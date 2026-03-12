# Shared Context Git Skill

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md)

A skill that provides a standardized workflow for multiple AI agents to share project context through a Git-backed remote repository. Agents read and update a shared memory made of Markdown files, using Git history as the review trail.

## Installation

```bash
npx skills add kuil09/shared-context-git-skill
```

After installation, the skill files are available locally. See [Quick Start](#quick-start) below to begin.

## Quick Start

```bash
# 1. Bootstrap a new shared context repo (first time only)
scripts/bootstrap_repo.sh

# 2. Sync before reading or writing
scripts/sync_context.sh

# 3. Create a context branch for your update
scripts/prepare_branch.sh --actor <your-name> --slug <short-topic>

# 4. Edit CONTEXT.md and/or TIMELINE.md

# 5. Validate, review, and commit
scripts/validate_context.sh
scripts/summarize_context.sh
git add -p && git commit -m "context: <summary>"
git push
```

## Features

- Bootstrap a shared context repository with standard document templates
- Safely sync a local clone before reading or writing
- Record stable facts, active context, decisions, open questions, and handoffs
- Support branch-first context updates reviewable as diffs
- Stop safely when the local state is stale, dirty, or diverged

## Repository Structure

```
├── SKILL.md                    # Skill definition and core rules
├── agents/
│   ├── openai.yaml             # OpenAI agent integration config
│   ├── claude.yaml             # Claude Code agent integration config
│   └── codex.yaml              # OpenAI Codex agent integration config
├── scripts/                    # Automation Bash scripts
│   ├── bootstrap_repo.sh       # Create initial documents from templates
│   ├── check_divergence.sh     # Report context branch divergence and stale branches
│   ├── cleanup_branches.sh     # Remove old merged context/* branches
│   ├── compact_timeline.sh     # Promote old timeline entries to CONTEXT.md stable facts
│   ├── sync_context.sh         # Fetch remote changes and fast-forward
│   ├── prepare_branch.sh       # Create a context branch
│   ├── validate_context.sh     # Validate document structure
│   └── summarize_context.sh    # Print status summary and compaction hints
├── tests/                      # BATS regression tests
│   ├── *.bats                  # Per-script behavior tests
│   ├── test_helper.bash        # Shared test helpers
│   ├── run_tests.sh            # Full test runner
│   └── lib/bats-core/          # BATS runner managed as a Git submodule
├── assets/
│   └── templates/              # Starter document templates
│       ├── CONTEXT.md           # Shared state document
│       ├── TIMELINE.md          # Append-only change history
│       ├── HANDOFF.md           # Handoff notes (optional)
│       └── POLICY.md            # Collaboration policy (optional)
└── references/                 # Detailed reference documents
    ├── schema.md               # Document structure specification
    ├── update-rules.md         # Update rules
    ├── git-workflows.md        # Git workflow patterns
    ├── conflict-policy.md      # Conflict handling policy
    └── handoff-guidelines.md   # Handoff guidelines
```

## Documents

### Required

| Document | Description |
|----------|-------------|
| `CONTEXT.md` | Core document summarizing current project state. Contains overview, stable facts, active context, decisions, and open questions sections. |
| `TIMELINE.md` | Append-only history of meaningful context changes. |

### Optional

| Document | Description |
|----------|-------------|
| `HANDOFF.md` | Handoff notes for the next agent. |
| `POLICY.md` | Team collaboration policies and guidelines. |

## Core Rules

1. **Read before write.** Fetch or sync first, then read `CONTEXT.md` and `TIMELINE.md` before editing.
2. **Keep shared memory in the repo**, not only in session-local notes.
3. **Prefer branch-first updates.** Direct pushes to the default branch should be rare and explicitly justified.
4. **Never overwrite conflicts automatically.** If the repo is dirty or the branch has diverged, stop and reconcile.
5. **Separate facts from inferences.** Verified facts belong in the stable sections; uncertainty stays visible in open questions or clearly labeled hypotheses.
6. **Add timeline entries only for meaningful changes.** Avoid noisy logging for every minor thought.

## Usage

### Workflow

```bash
# 1. Bootstrap if the repo does not exist yet
scripts/bootstrap_repo.sh

# 2. Sync in a local clone
scripts/sync_context.sh

# 3. Read CONTEXT.md, TIMELINE.md, and HANDOFF.md if present

# 4. Create a branch if you expect to share updates
scripts/prepare_branch.sh --actor <name> --slug <topic>

# 5. Update the Markdown files

# 6. Validate document structure
scripts/validate_context.sh

# 7. Review the diff and summarize current state
scripts/summarize_context.sh

# 8. Commit and push only when the change is meaningful and accurate
```

### Script Guide

| Script | Description |
|--------|-------------|
| `bootstrap_repo.sh` | Create the initial document set from templates. |
| `check_divergence.sh` | Report divergence of `context/*` branches from the base branch and flag stale branches. |
| `cleanup_branches.sh` | Remove merged, older `context/*` branches locally and optionally on `origin`. |
| `compact_timeline.sh` | Compact old TIMELINE.md entries by promoting applied changes to CONTEXT.md stable facts. |
| `sync_context.sh` | Fetch remote changes and fast-forward the base branch when safe. |
| `prepare_branch.sh` | Create or switch to a branch named `context/<actor>/<YYYY-MM-DD>-<slug>`. |
| `validate_context.sh` | Check required files, headings, and timeline entry shape. |
| `summarize_context.sh` | Print a compact status summary and compaction hints. |

## Tests

```bash
git submodule update --init --recursive
./tests/run_tests.sh
```

- Tests use BATS to validate normal and error paths for workflow scripts under `scripts/`.
- `tests/run_tests.sh` runs the full `.bats` suite using the bundled `tests/lib/bats-core` submodule.

## Collaboration Modes

- **Local draft only:** sync, read, edit locally, validate, and stop without committing.
- **Commit to branch and push:** create a context branch, update docs, validate, commit, and push.
- **PR proposal:** do the Git work here, then hand off PR creation to provider-specific tooling outside this skill.

## Reference Documents

- [schema.md](references/schema.md) — Document structure specification
- [update-rules.md](references/update-rules.md) — Update rules
- [git-workflows.md](references/git-workflows.md) — Git workflow patterns
- [conflict-policy.md](references/conflict-policy.md) — Conflict handling policy
- [handoff-guidelines.md](references/handoff-guidelines.md) — Handoff guidelines

## Agent Configuration

Configuration files for each agent framework are included in the `agents/` directory.

| Config file | Agent | Default actor name | Branch prefix |
|-------------|-------|--------------------|---------------|
| `agents/openai.yaml` | OpenAI Agents | `openai` | `context/openai` |
| `agents/claude.yaml` | Claude Code | `claude` | `context/claude` |
| `agents/codex.yaml` | OpenAI Codex | `codex` | `context/codex` |

Each config includes skill reference paths (`skill_paths`), default parameters (`parameters`), and workflow hints (`workflow_hints`).

### OpenAI Agents

```bash
# Config file path: agents/openai.yaml
# Example branch creation:
scripts/prepare_branch.sh --actor openai --slug my-topic
```

### Claude Code

```bash
# Config file path: agents/claude.yaml
# Example branch creation:
scripts/prepare_branch.sh --actor claude --slug my-topic
```

### Codex

```bash
# Config file path: agents/codex.yaml
# Example branch creation:
scripts/prepare_branch.sh --actor codex --slug my-topic
```

## Requirements

- Git CLI
- Bash shell
- Standard Unix utilities (grep, awk, etc.)

No external package or library dependencies.
