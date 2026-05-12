# Claude Code Power Setup — Complete Guide

> A comprehensive walkthrough of every skill, hook, agent, and configuration in the Claude Code Power Setup. Includes architecture diagrams, real conversation examples, and step-by-step workflows.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [How the Three Levels Work Together](#how-the-three-levels-work-together)
- [The Planning Pipeline](#the-planning-pipeline)
- [The Development Pipeline](#the-development-pipeline)
- [Skills Reference](#skills-reference)
  - [Planning & Alignment](#1-planning--alignment)
  - [Architecture & Design](#2-architecture--design)
  - [Development Workflow](#3-development-workflow)
  - [Testing & Debugging](#4-testing--debugging)
  - [Code Review & Quality](#5-code-review--quality)
  - [Research & Productivity](#6-research--productivity)
  - [Experiments](#7-experiments)
  - [LLM Engineering](#8-llm-engineering)
- [Hook System Deep Dive](#hook-system-deep-dive)
- [Subagent System Deep Dive](#subagent-system-deep-dive)
- [MCP Servers](#mcp-servers)
- [Extension Guide](#extension-guide)

---

## Architecture Overview

The Power Setup is a configuration layer that sits on top of any Python/LLM project. It works at three levels:

```mermaid
graph TB
    subgraph Level3["Level 3: KNOWLEDGE"]
        CLAUDE["CLAUDE.md<br/>Project instructions"]
        RULES["rules/<br/>Domain-specific context"]
        MCP["MCP Servers<br/>Live external docs"]
        CONTEXT["CONTEXT.md<br/>Domain glossary"]
    end

    subgraph Level2["Level 2: CAPABILITY"]
        SKILLS["33 Skills<br/>On-demand procedures"]
        AGENTS["12 Agents<br/>Specialist workers"]
    end

    subgraph Level1["Level 1: ENFORCEMENT"]
        PRE["PreToolUse Hooks<br/>Block dangerous actions"]
        POST["PostToolUse Hooks<br/>Auto-format, auto-test"]
        LIFE["Lifecycle Hooks<br/>Session start/end/compact"]
    end

    subgraph PROJECT["YOUR PROJECT"]
        SRC["src/"]
        TESTS["tests/"]
        PROMPTS["prompts/"]
        LOGS["logs/llm/ & logs/rag/"]
    end

    Level3 -->|"informs"| Level2
    Level2 -->|"operates on"| PROJECT
    Level1 -->|"enforces rules on"| PROJECT

    style Level1 fill:#ff6b6b,color:#fff
    style Level2 fill:#4ecdc4,color:#fff
    style Level3 fill:#45b7d1,color:#fff
    style PROJECT fill:#f7f7f7,color:#333
```

### What each level does

| Level | Mechanism | When it runs | Can Claude forget? | Token cost |
|-------|-----------|-------------|-------------------|------------|
| **Enforcement** | Hooks in settings.json | Automatically on every matching tool call | No — it's automatic | Zero |
| **Capability** | Skills + Agents | On demand (you invoke) or auto-dispatched | N/A — you trigger it | Per-invocation |
| **Knowledge** | CLAUDE.md + Rules + MCP | Always loaded or conditionally loaded | Yes — but cost is low | Varies |

---

## How the Three Levels Work Together

Here's what happens when you ask Claude to write a Python file:

```mermaid
sequenceDiagram
    participant You
    participant Claude
    participant PreHook as PreToolUse Hook
    participant File as File System
    participant PostHook as PostToolUse Hook
    participant Test as Test Runner

    You->>Claude: "Add retry logic to embeddings.py"
    
    Note over Claude: Reads CLAUDE.md rules<br/>Loads relevant rules/ context<br/>Uses MCP for library docs
    
    Claude->>PreHook: Write(src/services/embeddings.py)
    
    Note over PreHook: ✓ Not on main branch<br/>✓ No hardcoded secrets<br/>✓ No dangerous SQL<br/>✓ Not a migration file
    
    PreHook->>File: ALLOWED — write proceeds
    File-->>PostHook: File written
    
    Note over PostHook: ✓ Run ruff format<br/>✓ Run ruff check --fix<br/>✓ Find matching test file
    
    PostHook->>Test: pytest tests/test_embeddings.py
    Test-->>Claude: Test results (pass/fail)
    
    Note over Claude: Sees test output<br/>Fixes if needed<br/>Continues to next step

    Claude->>You: "Done. Retry logic added, tests pass."
```

---

## The Planning Pipeline

For non-trivial features, use this pipeline to go from idea to implementation-ready tickets:

```mermaid
graph LR
    IDEA["Vague Idea"]
    BRAINSTORM["/brainstorm<br/>Research + approaches"]
    GRILL["/grill<br/>One question at a time"]
    GRILLDOCS["/grill-with-docs<br/>+ update CONTEXT.md"]
    PRD["/to-prd<br/>Structured spec"]
    ISSUES["/to-issues<br/>Vertical slice tickets"]
    BUILD["Ready to build"]

    IDEA --> BRAINSTORM
    BRAINSTORM --> GRILL
    GRILL --> PRD
    GRILLDOCS --> PRD
    PRD --> ISSUES
    ISSUES --> BUILD

    GRILL -.->|"if project has<br/>domain glossary"| GRILLDOCS

    style IDEA fill:#ffd93d,color:#333
    style BUILD fill:#6bcb77,color:#fff
    style BRAINSTORM fill:#4ecdc4,color:#fff
    style GRILL fill:#4ecdc4,color:#fff
    style GRILLDOCS fill:#4ecdc4,color:#fff
    style PRD fill:#4ecdc4,color:#fff
    style ISSUES fill:#4ecdc4,color:#fff
```

### Step 1: `/brainstorm` — Explore the space

**When:** You have a vague idea and want to understand what's possible.

**What it does:** Searches for prior art (web + GitHub), generates 3-5 approaches with architecture patterns, evaluates tradeoffs, and presents a decision matrix.

**Example conversation:**

```
You:     /brainstorm caching layer for our RAG pipeline

Claude:  Let me understand the problem first.
         
         Q: "What's the primary pain point — latency, cost, or both?
         My recommendation: Based on your logs/llm/ directory showing
         average embedding latency of 200ms and 40% duplicate queries,
         I'd say latency is the bigger win."

You:     Latency mainly, but cost savings would be nice too.

Claude:  [searches web for RAG caching patterns 2025]
         [searches GitHub for popular implementations]
         [checks Context7 for Redis + LangChain docs]
         
         ## Brainstorm: RAG Pipeline Caching
         
         ### Prior Art
         - LangChain has CacheBackedEmbeddings (built-in)
         - Zep project caches at the session level
         - GPTCache uses semantic similarity for cache hits
         
         ### Approaches
         
         | Approach | Architecture | Effort | Risk |
         |----------|-------------|--------|------|
         | A: Exact-match query cache | Redis lookup | Low | Low |
         | B: Semantic cache (GPTCache) | Embedding similarity | Medium | Medium |
         | C: Multi-layer (query + chunk + response) | Redis + LRU | Medium | Low |
         
         ### My Recommendation
         Start with A (exact-match). Your 40% duplicate rate means huge
         wins for minimal complexity. Add semantic later if needed.
```

### Step 2: `/grill` — Stress-test the plan

**When:** You've picked an approach and need to resolve all the design decisions.

**What it does:** Interviews you one question at a time. For each question, provides its recommended answer. Explores the codebase instead of asking when it can find the answer itself.

**Key mechanic:** One question at a time, with a recommended answer. Not an interrogation — a collaborative decision-making session.

```
You:     /grill I want to add exact-match query caching with Redis

Claude:  [explores src/rag/ to understand current flow]
         
         Q1: "Cache key strategy — raw query string, or normalized 
         (lowercased, whitespace-stripped, stop-words-removed)?
         
         My rec: Normalized. I see queries like 'What is X?' and 
         'what is x' in your logs that should be cache hits."

You:     Normalized, good call.

Claude:  Q2: "Cache invalidation — TTL-based, event-driven on 
         document re-ingestion, or manual flush?
         
         My rec: Event-driven. Your ingest.py already has a 
         post-ingestion hook point. TTL risks serving stale results."

You:     Event-driven, but also a TTL as a safety net — 24 hours.

Claude:  Q3: "What gets cached — just the chunk IDs, or the full 
         chunk content + metadata?
         
         My rec: Chunk IDs only. Content is already in your vector DB.
         Caching content duplicates storage and risks staleness."

         ... [continues until all decisions resolved]
```

### Step 3: `/grill-with-docs` — Grill + documentation as side effect

Same as `/grill`, but also updates your project docs during the conversation:

```
Claude:  I notice you said "cache" but your CONTEXT.md doesn't define what
         a cache means in your RAG context. Let me add it:
         
         [writes to CONTEXT.md]
         **Query Cache**: A Redis-backed mapping from normalized query strings
         to retrieved chunk IDs, invalidated on document re-ingestion.
         _Avoid_: result cache, embedding cache (those would be different things)

Claude:  This caching decision is hard to reverse (Redis dependency), surprising
         without context (why not just TTL?), and was a real trade-off.
         Want me to record it as an ADR?

You:     Yes.

Claude:  [writes docs/adr/0003-event-driven-cache-invalidation.md]
         "We chose event-driven invalidation over TTL for the query cache
         because 40% of queries repeat and stale results after doc updates
         would break user trust. Redis is already in the stack."
```

### Step 4: `/to-prd` — Synthesize into a spec

**Input:** A resolved conversation (run `/grill` first).
**Output:** `docs/specs/[feature]-prd.md`

| Section | Contents |
|---------|----------|
| Problem Statement | The user's pain, not the tech problem |
| Solution | High-level approach |
| User Stories | Extensive numbered list (As a... I want... so that...) |
| Implementation Decisions | Modules, schemas, APIs — no file paths (they go stale) |
| Testing Decisions | What gets tested, what makes a good test |
| Out of Scope | Explicit exclusions |

### Step 5: `/to-issues` — Spec → Vertical slice tickets

```mermaid
graph TB
    PRD["PRD / Spec"] --> SLICES["Draft Vertical Slices"]
    SLICES --> QUIZ["Quiz the User"]
    QUIZ -->|"adjust"| SLICES
    QUIZ -->|"approved"| PUBLISH["Publish Issues"]

    PUBLISH --> AFK["AFK Issues<br/>(agent can do alone)"]
    PUBLISH --> HITL["HITL Issues<br/>(needs human decision)"]
    
    style AFK fill:#6bcb77,color:#fff
    style HITL fill:#ffd93d,color:#333
```

**Key concept:** Each issue cuts through ALL layers (schema + API + logic + tests). A completed issue is demoable on its own.

---

## The Development Pipeline

Once you have tickets, this is how each one gets built:

```mermaid
graph TB
    ISSUE["Pick an Issue"]
    TDD["/tdd<br/>Red-Green-Refactor"]
    SEARCH["/search-first<br/>Check existing patterns"]
    CODE["Write Code"]
    
    subgraph AUTO["Automatic via Hooks"]
        FMT["ruff format"]
        TEST["Run matching tests"]
        SYNC["uv sync"]
    end

    REVIEW["/review<br/>LLM-specific review"]
    FULL["/full-review<br/>9 parallel agents"]
    COMMIT["git commit"]
    
    subgraph GUARD["Automatic via Hooks"]
        SECRET["Scan for secrets"]
        MIGRATE["Test migration"]
        BRANCH["Check not on main"]
    end

    ISSUE --> SEARCH
    SEARCH --> TDD
    TDD --> CODE
    CODE --> AUTO
    AUTO --> REVIEW
    REVIEW --> FULL
    FULL --> COMMIT
    COMMIT --> GUARD

    style AUTO fill:#ff6b6b,color:#fff
    style GUARD fill:#ff6b6b,color:#fff
    style TDD fill:#4ecdc4,color:#fff
    style REVIEW fill:#4ecdc4,color:#fff
```

---

## Skills Reference

### 1. Planning & Alignment

| Skill | Purpose | Input | Output |
|-------|---------|-------|--------|
| `/grill` | Stress-test any plan | Your plan | Shared understanding |
| `/grill-with-docs` | Grill + update CONTEXT.md + ADRs | Your plan | Understanding + docs |
| `/to-prd` | Conversation → formal spec | Resolved conversation | `docs/specs/` PRD |
| `/to-issues` | Spec → vertical slice tickets | PRD | `docs/issues/` tickets |
| `/handoff` | Save context for next session | Current session | Handoff document |

---

### 2. Architecture & Design

| Skill | Purpose | Input | Output |
|-------|---------|-------|--------|
| `/design-agent` | Full agent architecture | Requirements | Spec with state graph |
| `/improve-architecture` | Find shallow modules to deepen | Codebase | Refactoring candidates |
| `/prototype` | Answer design questions fast | A question | Throwaway TUI or UI variants |
| `/zoom-out` | See the bigger picture | Current code location | Module map |

#### `/prototype` — Two branches

```mermaid
graph TB
    Q["Design Question"] -->|"logic/state?"| LOGIC["Logic Prototype<br/>(Terminal TUI)"]
    Q -->|"visual/UI?"| UI["UI Prototype<br/>(Multi-variant)"]
    
    LOGIC --> L1["Pure state machine<br/>(portable, no TUI code)"]
    LOGIC --> L2["TUI shell<br/>(throwaway)"]

    UI --> U1["Variant A"]
    UI --> U2["Variant B"]
    UI --> U3["Variant C"]
    UI --> SWITCH["?variant= URL switcher"]

    L1 --> ANSWER["Capture answer"]
    SWITCH --> ANSWER

    style LOGIC fill:#4ecdc4,color:#fff
    style UI fill:#4ecdc4,color:#fff
    style ANSWER fill:#6bcb77,color:#fff
```

**Logic prototype example:**

```
┌─ Order State Machine ──────────────────────────────────┐
│ State: payment_failed                                   │
│ Items: [SKU-001 x2, SKU-042 x1]                       │
│ Reserved: True  ← BUG: items still reserved!           │
│ Payment: failed                                         │
│ Transitions: [r]etry payment  [c]ancel  [q]uit         │
└─────────────────────────────────────────────────────────┘
```

#### `/improve-architecture` — Parallel interface design

```mermaid
graph LR
    CANDIDATE["Picked Candidate"] --> PARALLEL["Spawn Sub-Agents"]
    PARALLEL --> A1["Minimize<br/>interface"]
    PARALLEL --> A2["Maximize<br/>flexibility"]
    PARALLEL --> A3["Optimize for<br/>common caller"]
    A1 --> COMPARE["Compare &<br/>Recommend"]
    A2 --> COMPARE
    A3 --> COMPARE

    style PARALLEL fill:#45b7d1,color:#fff
    style COMPARE fill:#6bcb77,color:#fff
```

---

### 3. Development Workflow

| Skill | Purpose |
|-------|---------|
| `/brainstorm` | Research before building — prior art, approaches, decision matrix |
| `/brainstorm-panel` | Three models (Claude + Codex + Gemini) brainstorm in parallel |
| `/search-first` | Find existing patterns before writing new code |
| `/update-context` | Rewrite docs/context.md and docs/architecture.md |
| `/new-project` | Full project scaffold with Docker, logging, tests |

---

### 4. Testing & Debugging

#### `/tdd` — Vertical slice TDD

```mermaid
graph LR
    PLAN["Plan"] --> T1["RED"]
    T1 --> I1["GREEN"]
    I1 --> T2["RED"]
    T2 --> I2["GREEN"]
    I2 --> T3["RED"]
    T3 --> I3["GREEN"]
    I3 --> REFACTOR["REFACTOR"]

    style T1 fill:#ff6b6b,color:#fff
    style T2 fill:#ff6b6b,color:#fff
    style T3 fill:#ff6b6b,color:#fff
    style I1 fill:#6bcb77,color:#fff
    style I2 fill:#6bcb77,color:#fff
    style I3 fill:#6bcb77,color:#fff
    style REFACTOR fill:#45b7d1,color:#fff
```

**WRONG:** Write all tests first → all implementation. **RIGHT:** One test → one implementation → repeat.

**Mocking rules:** Mock at system boundaries ONLY. NEVER mock your own classes.

#### `/diagnose` — Six-phase structured debugging

```mermaid
graph TB
    BUG["Bug Report"] --> P1["Phase 1:<br/>Build Feedback Loop<br/>(10 strategies,<br/>cheapest first)"]
    P1 --> P2["Phase 2:<br/>Reproduce<br/>(verify it matches report)"]
    P2 --> P3["Phase 3:<br/>3-5 Hypotheses<br/>(ranked, before testing)"]
    P3 --> P4["Phase 4:<br/>Instrument<br/>(tagged: [DEBUG-a4f2])"]
    P4 --> P5["Phase 5:<br/>Fix<br/>(regression test FIRST)"]
    P5 --> P6["Phase 6:<br/>Cleanup + Post-mortem<br/>(what would prevent this?)"]
    
    P6 -->|"arch gap"| ARCH["/improve-architecture"]
    P6 -->|"missing tests"| TDD2["/tdd"]

    style BUG fill:#ff6b6b,color:#fff
    style P5 fill:#6bcb77,color:#fff
```

**Example:**

```
You:     /diagnose embedding service returns empty for queries > 200 chars

Claude:  Phase 1 — Feedback loop via failing test:
         
         test_long_query_returns_results()
         query = "a" * 201 + " machine learning"
         assert len(embed_and_search(query)) > 0  # FAILS ✓
         
         Phase 3 — Hypotheses:
         1. [HIGH] Token limit truncation at 512 tokens
         2. [MEDIUM] normalize_query() truncates input
         3. [LOW] Cosine similarity drops for long embeddings
         
         Testing #1: [DEBUG-e3f1] token count = 847, model max = 512
         Meaningful terms at positions 600-847 — past cutoff.
         
         Root cause confirmed. Writing regression test, then fix.
```

---

### 5. Code Review & Quality

#### `/review` — LLM-specific review

Catches: missing LLM logging, no token counting, temperature not set, unclosed async clients, inline prompts, no cost tracking.

#### `/full-review` — 9 parallel specialist agents

```mermaid
graph TB
    CODE["Your Code"] --> D["Dispatch"]
    
    D --> A1["Tests"]
    D --> A2["Security"]
    D --> A3["Performance"]
    D --> A4["Quality"]
    D --> A5["Dependencies"]
    D --> A6["Simplicity"]
    D --> A7["Docs"]
    D --> A8["Logging"]
    D --> A9["Architecture"]
    
    A1 --> M["Aggregate"]
    A2 --> M
    A3 --> M
    A4 --> M
    A5 --> M
    A6 --> M
    A7 --> M
    A8 --> M
    A9 --> M
    
    M --> R["Prioritized Report"]

    style R fill:#6bcb77,color:#fff
```

#### `/second-opinion` — Cross-model review

Sends diff to Codex CLI. Two models flagging the same issue = high confidence.

#### `/deploy-check` — Pre-deploy automation

Tests, lint, Docker build, health check, zombie scan, memory check.

---

### 6. Research & Productivity

| Skill | Purpose |
|-------|---------|
| `/deep-research` | Multi-round research loop with completeness evaluation |
| `/inspiration` | Analyze a GitHub repo → Keep / Adapt / Discard breakdown |
| `/self-learn` | Extract session knowledge into persistent rules |
| `/caveman` | ~75% token reduction, persists across session |
| `/autoloop` | Run any command on a recurring interval |
| `/offload` | Delegate long tasks to a background subagent |

#### `/caveman` — Before and after

```
Normal:  "Sure! I'd be happy to help you with that. The issue 
         you're experiencing is likely caused by a race condition 
         in the authentication middleware where the token validation
         check is not performed atomically..."

Caveman: "Race condition in auth middleware. Token check not atomic.
         Fix: wrap in transaction. Code:"
```

Auto-suspends for security warnings. Resumes after.

---

### 7. Experiments

| Skill | Purpose |
|-------|---------|
| `/new-experiment` | Fully isolated git worktree + uv env + logs |
| `/compare-experiments` | Side-by-side metrics comparison |
| `/cleanup-experiments` | Remove stale worktrees |
| `/freeze [path]` | Restrict Claude to one directory |
| `/unfreeze` | Remove restriction |

---

### 8. LLM Engineering

| Skill | Purpose |
|-------|---------|
| `/debug-llm` | Parse logs/llm/ for failures, cost, latency |
| `/cost-aware-pipeline` | Audit chain architecture for token waste |
| `/design-agent` | Full agent spec with state graph and guardrails |

---

## Hook System Deep Dive

```mermaid
graph TB
    subgraph PRE["PreToolUse — Gatekeepers"]
        H1["Block writes on main"]
        H2["Block pip install"]
        H3["Block dangerous SQL"]
        H4["Block migration edits"]
        H5["Block secrets on commit"]
        H6["Test migration reversibility"]
    end

    subgraph POST_HOOKS["PostToolUse — Reactors"]
        H7["Auto-format Python"]
        H8["Auto-test on save"]
        H9["Auto-sync deps"]
    end

    subgraph LIFE["Lifecycle"]
        H10["SessionStart: stale docs warning"]
        H11["SessionEnd: kill dev servers"]
        H12["Stop: notification sound"]
        H13["PreCompact: save state"]
        H14["PostCompact: restore state"]
    end

    WRITE["Claude writes a file"] --> PRE
    PRE -->|"exit 0"| FILE["File saved"]
    PRE -->|"exit 2"| BLOCKED["BLOCKED"]
    FILE --> POST_HOOKS

    style PRE fill:#ff6b6b,color:#fff
    style POST_HOOKS fill:#4ecdc4,color:#fff
    style LIFE fill:#45b7d1,color:#fff
    style BLOCKED fill:#ff0000,color:#fff
```

### How hooks receive data

The hook receives the tool call's input as JSON on stdin:

```json
{
  "file_path": "src/services/payment.py",
  "content": "import os\nSECRET_KEY = 'sk-abc123'..."
}
```

Exit codes: **0** = allow, **2** = BLOCK, **other** = allow with warning.

---

## Subagent System Deep Dive

```mermaid
graph LR
    subgraph ARCH["Architecture"]
        A1["llm-architect"]
        A2["architect"]
    end
    
    subgraph QUALITY["Code Quality"]
        A3["code-reviewer"]
        A4["security-reviewer"]
        A5["performance-reviewer"]
    end
    
    subgraph ANALYSIS["Analysis"]
        A6["llm-reviewer"]
        A7["rag-debugger"]
        A8["prompt-optimizer"]
    end
    
    subgraph OPS["Operations"]
        A9["test-writer"]
        A10["docker-deployer"]
        A11["agent-evaluator"]
        A12["log-cleaner"]
    end

    style ARCH fill:#45b7d1,color:#fff
    style QUALITY fill:#4ecdc4,color:#fff
    style ANALYSIS fill:#ffd93d,color:#333
    style OPS fill:#ff6b6b,color:#fff
```

| Agent | Specialty | Example invocation |
|-------|-----------|-------------------|
| `llm-architect` | Model selection, serving, caching | "Evaluate our model routing strategy" |
| `architect` | LangGraph state graphs, agent patterns | "Design the state graph for our RAG agent" |
| `code-reviewer` | LLM-specific Python review | Auto-dispatched by `/full-review` |
| `security-reviewer` | Prompt injection, secrets, auth | "Audit the auth middleware" |
| `performance-reviewer` | N+1, async blocking, memory | "Find async blocking in the API layer" |
| `llm-reviewer` | Cost, latency, quality from logs | "Which prompts have the highest retry rate?" |
| `rag-debugger` | Chunks, scores, embeddings | "Why are similarity scores all near 0.5?" |
| `test-writer` | pytest with mocked LLM fixtures | "Write tests for the new search service" |
| `docker-deployer` | Images, compose, health checks | Auto-dispatched by `/deploy-check` |
| `prompt-optimizer` | Token efficiency, clarity | "Optimize the prompts/ directory" |
| `agent-evaluator` | Trajectory, guardrails, loops | "Stress-test the agent for infinite loops" |
| `log-cleaner` | Zombies, old logs, disk usage | "Clean up orphaned processes" |

---

## MCP Servers

```mermaid
graph LR
    CLAUDE["Claude Code"] -->|"tool call"| C7["context7<br/>Live library docs"]
    CLAUDE -->|"tool call"| ST["sequential-thinking<br/>Multi-step reasoning"]
    
    C7 --> DOCS["LangChain, FastAPI,<br/>Pydantic v2, SQLAlchemy 2.0,<br/>any library"]
    
    ST --> STEPS["Sequential reasoning<br/>with intermediate<br/>conclusions"]

    style CLAUDE fill:#4ecdc4,color:#fff
    style C7 fill:#45b7d1,color:#fff
    style ST fill:#45b7d1,color:#fff
```

---

## Extension Guide

### Decision guide

```mermaid
graph TB
    WANT["I want Claude to..."] 
    WANT -->|"always do X automatically"| HOOK["Hook<br/>(settings.json)"]
    WANT -->|"follow a procedure on demand"| SKILL["Skill<br/>(.claude/skills/)"]
    WANT -->|"use specialist expertise"| AGENT["Agent<br/>(.claude/agents/)"]
    WANT -->|"know domain rules in context"| RULE["Rule<br/>(.claude/rules/)"]
    WANT -->|"look up live external data"| MCP_S["MCP Server<br/>(.mcp.json)"]
    WANT -->|"follow rules every message"| CMD["CLAUDE.md"]
    WANT -->|"NEVER be allowed to do X"| DENY["Permission deny<br/>(settings.json)"]

    style HOOK fill:#ff6b6b,color:#fff
    style SKILL fill:#4ecdc4,color:#fff
    style AGENT fill:#4ecdc4,color:#fff
    style RULE fill:#45b7d1,color:#fff
    style MCP_S fill:#45b7d1,color:#fff
    style CMD fill:#45b7d1,color:#fff
    style DENY fill:#ff6b6b,color:#fff
```

### Add a skill

```bash
mkdir -p .claude/skills/my-command
```

```markdown
# .claude/skills/my-command/SKILL.md
---
name: my-command
description: What this does
---

Instructions Claude follows when /my-command is invoked.
```

### Add an agent

```markdown
# .claude/agents/my-specialist.md
---
name: my-specialist
description: When to invoke this agent
tools: Read, Bash, Grep
---

You are an expert in X. When called, always...
```

### Add a hook

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{"type": "command", "command": "your-script.sh"}]
    }]
  }
}
```

---

*Generated for the [Claude Code Power Setup](https://github.com/arjunfzk/claude-code-custom-power-setup)*
