---
name: grill-with-docs
description: Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallize. Use when user wants to stress-test a plan against project language and documented decisions.
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

## Rules

- Ask questions **one at a time**, waiting for feedback before continuing.
- For each question, **provide your recommended answer**.
- If a question can be answered by exploring the codebase, explore the codebase instead of asking.

## Domain Awareness

During codebase exploration, look for existing documentation:

- `CONTEXT.md` or `docs/context.md` — domain glossary
- `docs/adr/` — architecture decision records
- `docs/architecture.md` — system architecture

Create files lazily — only when you have something to write.

## During the Session

### Challenge against the glossary

When I use a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When I use vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force precision about boundaries between concepts.

### Cross-reference with code

When I state how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there — don't batch these up. Use this format:

```markdown
**Term**:
One-sentence definition.
_Avoid_: aliases to not use

## Relationships
- A **Term** has one or more **OtherTerms**
```

Only include terms specific to this project's context. General programming concepts don't belong.

### Offer ADRs sparingly

Only offer to create an ADR when ALL THREE are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

ADRs go in `docs/adr/` with sequential numbering: `0001-slug.md`. An ADR can be a single paragraph — the value is in recording *that* a decision was made and *why*.

$ARGUMENTS
