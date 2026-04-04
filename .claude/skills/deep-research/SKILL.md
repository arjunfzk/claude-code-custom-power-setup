---
name: deep-research
description: Multi-round deep research with thinking loop — searches, evaluates completeness, searches again or synthesizes. Uses WebSearch + Context7 + Sequential Thinking.
context: fork
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - mcp__context7__resolve-library-id
  - mcp__context7__get-library-docs
  - mcp__sequential-thinking__sequentialthinking
---

Deep research on a topic using a thinking loop. Searches multiple sources, evaluates if it has enough info, searches more or synthesizes.

## Process

### Phase 1: Understand the Question
- Parse $ARGUMENTS for the research question
- Use Sequential Thinking MCP to break the question into sub-questions
- Identify: what do I already know? What do I need to find out?

### Phase 2: Research Loop (max 5 rounds)

```
Round N:
  1. SEARCH: Use the best source for each sub-question:
     - WebSearch → general web (blog posts, papers, discussions, GitHub repos)
     - Context7 → library documentation (if question involves a specific library)
     - WebFetch → read specific URLs found in search results
     - Grep/Glob → search local codebase for relevant patterns

  2. EVALUATE: Use Sequential Thinking MCP to assess:
     - Which sub-questions are now answered with HIGH confidence?
     - Which sub-questions still have gaps?
     - Did I find new sub-questions I didn't anticipate?
     - Confidence score: 0-1 for overall understanding

  3. DECIDE:
     - Confidence >= 0.8 → proceed to synthesis
     - Confidence < 0.8 AND round < 5 → refine queries, search again
     - Round >= 5 → synthesize with what we have, note gaps
```

### Phase 3: Synthesize

Produce a structured research report:

```markdown
# Research: [Topic]

**Date:** [date]
**Rounds:** [N] search rounds
**Confidence:** [score] — [HIGH/MEDIUM/LOW]
**Sources:** [count] unique sources consulted

## Key Findings

1. **[Finding]** — [evidence + source]
2. **[Finding]** — [evidence + source]
3. **[Finding]** — [evidence + source]

## Detailed Analysis

### [Sub-topic 1]
[What we found, with inline source citations]

### [Sub-topic 2]
[What we found]

## Relevant Code/Libraries

| Library/Tool | Purpose | Maturity | Link |
|-------------|---------|----------|------|
| [name] | [what it does] | [stable/beta/experimental] | [url] |

## Popular GitHub Repos

| Repo | Stars | Why Relevant |
|------|-------|-------------|
| [repo] | [stars] | [description] |

## Open Questions / Gaps

- [What we couldn't find or aren't confident about]

## Recommendations

1. [Actionable recommendation based on findings]
2. [Next step]

## Sources

1. [URL] — [what it contributed]
2. [URL] — [what it contributed]
```

Save report to: `docs/research/[topic-slug].md`

### Rules
- ALWAYS cite sources with URLs
- ALWAYS note confidence level per finding
- ALWAYS check GitHub repos for star count and recent activity (stale repos are not reliable)
- If Context7 has docs for a library mentioned, USE IT — live docs beat blog posts
- Search for "2025" or "2026" to find recent content, not outdated articles
- Look for BOTH: "how to do X" AND "problems with X" / "X alternatives"

$ARGUMENTS
