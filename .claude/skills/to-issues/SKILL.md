---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable issues using tracer-bullet vertical slices. Each slice cuts through ALL layers end-to-end. Use when user wants to create tickets, break down work, or convert a plan into issues.
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---

Break a plan into independently-grabbable issues using vertical slices (tracer bullets).

## Process

### 1. Gather context

Work from whatever is in the conversation context. If the user passes an issue reference or path as an argument, read it.

### 2. Explore the codebase (optional)

If you haven't already, explore to understand current state. Use the project's domain glossary vocabulary for issue titles and descriptions.

### 3. Draft vertical slices

Break the plan into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end — NOT a horizontal slice of one layer.

- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, logic, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones

Classify each slice:
- **AFK** — can be implemented and merged autonomously by an agent
- **HITL** — requires human interaction (architectural decision, design review, etc.)

Prefer AFK over HITL where possible.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice show:
- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices must complete first
- **User stories covered**: which user stories this addresses

Ask:
- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split?
- Are the correct slices marked HITL vs AFK?

Iterate until the user approves.

### 5. Create the issues

Save to `docs/issues/[feature-slug]/` as individual markdown files, numbered in dependency order (blockers first).

Each issue follows this template:

```markdown
# [Issue Title]

**Type:** AFK / HITL
**Parent:** [reference to parent PRD or spec]

## What to build
Concise description of this vertical slice. Describe end-to-end behavior, not layer-by-layer.

Avoid file paths or code snippets (they go stale). Exception: prototype-derived snippets.

## Acceptance criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by
- [blocking issue] or "None — can start immediately"
```

$ARGUMENTS
