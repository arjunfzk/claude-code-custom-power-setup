---
name: handoff
description: Compact the current conversation into a handoff document so a fresh agent can continue the work. References existing artifacts instead of duplicating them.
argument-hint: "What will the next session focus on?"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---

Write a handoff document summarizing the current conversation so a fresh agent can continue the work.

## Process

1. Save to `docs/handoffs/handoff-[date]-[slug].md`

2. Include:
   - **Current state** — what's done, what's in progress, what's blocked
   - **Key decisions made** — but reference existing artifacts (PRDs, ADRs, issues, commits) by path/URL instead of duplicating their content
   - **What the next session needs to know immediately** — context that isn't captured anywhere else
   - **Suggested skills** for the next session (e.g. "start with `/grill-with-docs` to align on the payment flow")
   - **Open questions** — things left unresolved

3. Do NOT duplicate content already in:
   - PRDs (`docs/specs/`)
   - ADRs (`docs/adr/`)
   - Issues
   - Commits or diffs
   - `docs/context.md` or `docs/architecture.md`

   Reference them instead: "See `docs/specs/caching-prd.md` for the full spec."

4. If the user passed arguments describing what the next session will focus on, tailor the handoff accordingly — emphasize the relevant context and de-emphasize the rest.

$ARGUMENTS
