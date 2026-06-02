---
name: spec-to-readable-docs
description: Use this skill to create detailed technical documents optimized for the user's own understanding first, and implementer/team sharing second
argument-hint: '[lang]'
arguments: lang
---

Skill: Japanese Readable Technical Docs

Use this skill to create detailed technical documents optimized for the user's own understanding first, and implementer/team sharing second.

MANDATORY LANGUAGE RULE:
All generated documents, explanations, headings, tables, diagrams, notes, and summaries MUST be written in Japanese. Do not write the final document in English unless the user explicitly requests English output. English technical terms may be kept only when they are standard in Japanese engineering practice.

Use "/spec-to-readable-html" for final document generation.

Output format

Create polished, readable HTML documents by default.

Use a calm technical-document style as the base. Add cards, badges, grids, and callouts where they improve scanning, but do not make the document look like a marketing dashboard.

Navigation should be simple: a title, overview, and table of contents are enough.

Audience priority

1. User's own understanding
2. Implementers and team members
3. Customers or non-engineers are not the main audience

Do not simplify into sales-style material. Preserve enough depth for understanding, implementation, operation, and explanation to others.

Structure

Use this flow:

1. What this is about
2. Why it matters
3. Quick overview and basic policy
4. Overall map / structure / diagram
5. Comparison with similar or easily confused concepts
6. Basic concepts and assumptions
7. Detailed explanations
8. Mechanisms, internals, and constraints
9. Practical comparison and decision criteria
10. Minimal example, practical example, and failure example
11. Pitfalls, cautions, and edge cases
12. Summary and review points
13. References and further reading

Start with an easy-to-grasp overview, then move into rigorous details.

Depth

Prefer detailed and long documents over short summaries.

Do not remove important explanation for brevity. Include mechanisms, comparisons, implementation impact, operational impact, assumptions, alternatives, pitfalls, examples, and judgment criteria.

Minor tips, side notes, and extra context should be placed in short callouts or appendices.

Accuracy

In overview sections, prioritize understandability over strict precision, but clearly mark simplifications with phrases like “理解のために単純化すると” or “厳密には後述する”.

In detailed sections, prioritize accuracy. Clearly separate confirmed facts, assumptions, implementation-dependent behavior, version-dependent behavior, vendor-specific behavior, uncertainty, and items requiring verification.

State confirmed facts directly. State conditional facts with their conditions. Mark assumptions and unknowns explicitly.

Diagrams and tables

Use many diagrams and tables, but never rely on them alone.

Every diagram or table must have surrounding explanation:

- what it shows
- how to read it
- why it matters
- what is simplified
- how it affects practical judgment

Use diagrams for structure, relationships, flows, timelines, layers, and dependencies.
Use tables for comparisons, decision criteria, trade-offs, pitfalls, and specification differences.

Comparison

Use three-layer comparison:

1. Overview: compare conceptual boundaries and similar terms
2. Detail: compare mechanisms, specifications, constraints, and implementation differences
3. Practice: compare adoption criteria, operational impact, risks, alternatives, and when to avoid each option

Do not end with feature lists. Always explain how to decide.

Examples

For important concepts, include:

1. Minimal example
2. Practical example
3. Failure or pitfall example

Explain the purpose of each example, what to look at, how to interpret it, and what changes in real-world use.

Callouts

Place pitfalls and notes near the relevant text, not only at the end.

Use short callouts:

- Info: useful background
- Tip: practical hint
- Note: small clarification
- Caution: design, implementation, or operation risk
- Warning: serious risk such as outage, data loss, security issue, or major rework

Do not hide core explanations inside callouts.

Sources

Keep the main text readable. Do not overload it with citations.

Use inline sources only for important specifications, version differences, security risks, performance claims, operational risks, or major design decisions. Put most references at the end of the document or section.

Prefer official documentation, standards, RFCs, vendor documentation, and primary sources.

Unknowns

Do not stop document creation for minor unknowns.

Infer reasonable assumptions, continue writing, and clearly mark assumptions, unknowns, verification items, and implementation-dependent areas. Ask questions only when the missing information could change the document’s purpose, audience, safety, or major design direction.

Review before finalizing

Before final output, review and revise the structure so that it teaches in the right order.

Check:

- overview before details
- similar concepts compared early
- diagrams are explained by text
- details are accurate
- assumptions are marked
- examples include minimal, practical, and failure cases
- pitfalls are near the relevant sections
- decision criteria are practical
- the final document is fully written in Japanese
