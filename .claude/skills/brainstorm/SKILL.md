---
name: brainstorm
description: Brainstorm ideas with web research — finds prior art, generates approaches, evaluates tradeoffs, presents decision matrix
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

Brainstorm approaches for a problem or feature. Searches for prior art, generates multiple approaches, evaluates tradeoffs, and helps you decide.

## Process

### Phase 1: Understand the Problem (2-3 questions)

Ask the user to clarify (via plain text, not long questionnaires):
- What are you trying to build/solve?
- Any constraints? (timeline, tech stack, budget, existing code)
- What have you already considered or tried?

### Phase 2: Research Prior Art

Search for existing solutions and approaches:

```
1. WebSearch: "[problem] best practices 2025"
2. WebSearch: "[problem] architecture patterns"
3. WebSearch: "[problem] python langchain" (or relevant stack)
4. WebSearch: "github [problem] agent" → find popular repos
5. WebFetch: Read top 3-5 most relevant results
6. Context7: If specific libraries are mentioned, get their docs
```

Summarize what exists:
- Who has solved this before?
- What approaches did they use?
- What worked? What didn't?
- Any popular open-source implementations?

### Phase 3: Generate Approaches (3-5)

For each approach:
- **Name**: Short descriptive name
- **How it works**: 3-5 sentences
- **Architecture**: Which agent pattern? (Router / Orchestrator / Thinking Loop / etc.)
- **Key libraries**: What you'd use
- **Pros**: What's good about this approach
- **Cons**: What's risky or hard
- **Effort**: Low / Medium / High
- **Prior art**: Who has done something similar

### Phase 4: Present Decision Matrix

```markdown
## Brainstorm: [Topic]

### Prior Art
- [What exists, who solved it, links]

### Approaches

| Approach | Architecture | Effort | Risk | Best When |
|----------|-------------|--------|------|-----------|
| A: [name] | Router pattern | Low | Low | Simple use case, fast MVP |
| B: [name] | Orchestrator | Medium | Medium | Complex multi-step tasks |
| C: [name] | Thinking loop | Medium | Low | Info gathering, variable depth |
| D: [name] | Multi-agent | High | High | Parallel processing needed |

### Approach Details

#### A: [Name]
**How:** [description]
**Architecture:**
```
Input → [flow diagram] → Output
```
**Libraries:** [list]
**Pros:** [list]
**Cons:** [list]
**Similar to:** [prior art reference]

[... repeat for each approach ...]

### My Recommendation
[Which approach and why, considering your constraints]

### Next Steps
1. [First thing to build]
2. [How to validate the approach early]
```

### Phase 5: Drill Down

After presenting the matrix, ask:
"Which approach interests you? I can drill deeper — sketch the LangGraph state graph, identify components, estimate the API calls per request, or prototype the core logic."

If user picks one:
- Sketch the state graph (Mermaid diagram)
- List the nodes and edges
- Identify where guardrails go
- Identify what to log
- Produce a spec ready for implementation

### Rules
- ALWAYS search before generating approaches — ground ideas in reality
- ALWAYS include effort estimates
- ALWAYS identify risks and failure modes for each approach
- Search GitHub for recent repos (sort by stars, check last commit date)
- If user mentions a specific library, use Context7 to get current API
- Prefer approaches with existing open-source implementations you can adapt
- Be opinionated — don't just list options, recommend one

Save brainstorm to: `docs/brainstorms/[topic-slug].md`

$ARGUMENTS
