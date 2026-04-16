---
name: research-note-maintainer
description: Maintain and improve existing research notes and logs in this repository. Use when refining note structure, adding evidence, splitting oversized notes, refreshing metadata, and synchronizing change/planning/self-review logs.
---

# Research Note Maintainer

Use this workflow to keep the research knowledge base consistent and current.

## 1) Inspect current state
- Check recent commits for repeated maintenance patterns.
- Identify candidate files in `research/`, `docs/`, and `research/logs/`.
- Detect stale metadata (`review_due`, tags, or missing required sections).

## 2) Choose maintenance action
- **Refresh note quality**: add evidence, code snippets, and constraints.
- **Split note**: move a subtopic into a dedicated file when a note becomes too broad.
- **Normalize metadata**: align headers and naming format with repository conventions.
- **Update logs**: append concise entries to `change-log.md` and related logs.

For recurring patterns, read:
- `references/commit-patterns.md`

## 3) Execute edits safely
- Preserve history; avoid deleting useful context unless obsolete.
- Keep links between parent and split notes.
- Keep language and scope consistent within each note.

## 4) Validate and finalize
- Run `./scripts/self_review.sh`.
- Confirm logs reflect the performed maintenance action.
- Commit with a maintenance-focused message describing user-visible impact.
