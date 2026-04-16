# Skill Design Notes (Web references)

Use these guardrails when creating or updating skills in this repository.

## OpenAI Developers: Agent Skills
Source: https://developers.openai.com/codex/skills

- Keep each skill focused on one job.
- Ensure `SKILL.md` contains YAML frontmatter with `name` and `description`.
- Rely on progressive disclosure: concise SKILL body + optional references/scripts/assets.
- Prefer instructions over scripts unless deterministic behavior is required.
- Place repository-shared skills under `.agents/skills`.

## npaka article summary
Source: https://note.com/npaka/n/nfaa42624abd7

- Treat skills as reusable operation modules (instructions + optional scripts/resources).
- Encode team conventions in skills to reduce prompt repetition.
- Validate that trigger descriptions match real user request patterns.

## Commit-derived implications for this repo
- Planning-before-edit and self-review-before-commit are mandatory gates.
- Notes are frequently refreshed with additional references and structural improvements.
- Splitting large topics into focused notes improves maintainability and retrieval quality.
