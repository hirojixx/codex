---
name: codex-research-workflow
description: Execute this repository's mandatory research operating procedure when creating or updating files under docs/ or research/. Use when tasks require planning logs, web-grounded research, metadata updates, and self-review before commit.
---

# Codex Research Workflow

Follow this workflow exactly for repository research work.

## 1) Define task boundaries
- Write one-line statements for: purpose, success criteria, and constraints.
- Confirm target files and expected output language before editing.

## 2) Run pre-planning gate (required)
- Run `./scripts/preplan.sh <task_title> <query1> <query2> ...` before any content edit.
- Use at least two concrete search queries.
- Verify that `research/logs/planning/YYYY-MM-DD__<task-slug>.md` is created or updated for the current task.

## 3) Perform web-grounded collection
- Check primary sources first (official docs/specs/vendor docs).
- Record concrete dates for volatile facts.
- Keep source URLs in the note body and changelog-friendly summaries.

For skill design rules, read:
- `references/skill-design-notes.md`

## 4) Apply repository documentation standards
- Keep note naming format `YYYY-MM-DD__topic-slug.md`.
- Ensure required sections are complete (conclusion, evidence, constraints, next actions).
- Update supporting logs when scope changes materially.

## 5) Run self-review gate (required)
- Run `./scripts/self_review.sh <task_title>` after edits, using the same task title passed to `./scripts/preplan.sh`.
- Resolve any reported issues before commit.
- Confirm taxonomy and update policy consistency when touching research notes.

## 6) Commit hygiene
- Summarize what changed, why, and what was validated.
- Prefer small, reviewable commits aligned with one research objective.
