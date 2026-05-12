---
name: to-prd
description: Turn the current conversation context into a PRD. Synthesizes what's been discussed — does NOT interview. Use when user wants to create a PRD, spec, or requirements doc from the current context.
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---

Synthesize the current conversation context and codebase understanding into a PRD. Do NOT interview the user — work from what's already been discussed. If you need alignment first, suggest running `/grill` or `/grill-with-docs`.

## Process

1. **Explore the repo** to understand current state. Use the project's domain glossary vocabulary throughout. Respect any ADRs in the area you're touching.

2. **Sketch major modules** you need to build or modify. Actively look for opportunities to extract deep modules (large behavior behind small interface, testable in isolation). Check with the user that these modules match expectations.

3. **Write the PRD** using the template below, then save to `docs/specs/[feature-slug]-prd.md`.

## PRD Template

```markdown
# [Feature Name] — PRD

## Problem Statement
The problem from the user's perspective.

## Solution
The solution from the user's perspective.

## User Stories
1. As a [actor], I want [feature], so that [benefit]
2. ...
(Extensive numbered list covering ALL aspects of the feature)

## Implementation Decisions
- Modules to build/modify and their interfaces
- Schema changes
- API contracts
- Architectural decisions

Do NOT include specific file paths or code snippets (they go stale).
Exception: prototype-derived snippets that encode decisions more precisely
than prose (state machines, schemas, type shapes).

## Testing Decisions
- Which modules get tests and why
- What makes a good test for this feature (behavior, not implementation)
- Prior art for similar tests in the codebase

## Out of Scope
Things explicitly NOT included.

## Further Notes
Additional context.
```

$ARGUMENTS
