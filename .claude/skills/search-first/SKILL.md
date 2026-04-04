---
name: search-first
description: Before writing new code, search the existing codebase for patterns, utilities, and solutions that already exist. Prevents reinventing the wheel.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

BEFORE writing any new code, search the existing codebase for things that already solve (or partially solve) the problem.

## Why This Exists

Claude's default behavior is to write new code. But in a growing codebase, there are often:
- Utility functions that do what you need
- Patterns established in other modules you should follow
- Similar features already implemented that you can adapt
- Helper classes, base classes, mixins that handle boilerplate

Writing new code when existing code solves the problem creates duplication, inconsistency, and maintenance burden.

## Process

### Step 1: Understand What's Needed

Parse $ARGUMENTS for the task description. Identify:
- What functionality is needed?
- What patterns would it use? (HTTP client, DB query, LLM call, file processing)
- What similar things might already exist?

### Step 2: Search the Codebase (5 targeted searches)

```bash
# 1. Search for similar function names
grep -rn "def.*{keyword}" src/ --include="*.py" | head -20

# 2. Search for similar class names
grep -rn "class.*{keyword}" src/ --include="*.py" | head -20

# 3. Search for similar imports (what libraries are already used for this)
grep -rn "from.*import\|import.*" src/ --include="*.py" | grep -i "{keyword}" | head -20

# 4. Search for similar patterns in utils/helpers
find src/ -name "utils*.py" -o -name "helpers*.py" -o -name "common*.py" | xargs grep -l "{keyword}" 2>/dev/null

# 5. Search tests for similar test patterns
grep -rn "def test.*{keyword}" tests/ --include="*.py" | head -20
```

### Step 3: Report Findings

```
## Search-First Report: {task}

### Existing Code Found
- `src/utils/http.py:45` — `async_retry_request()` — handles HTTP retries with backoff
  → You can REUSE this instead of writing retry logic
- `src/chains/qa_chain.py` — similar RAG pattern already implemented
  → You should FOLLOW this pattern for consistency

### Established Patterns
- HTTP calls: always use `app.state.http_client` (not create new client)
- LLM calls: always go through `src/services/llm_logger.py`
- DB queries: always use repository pattern in `src/db/repositories/`

### Nothing Found (write new)
- No existing [X] — safe to write from scratch
- But follow the pattern in [nearest similar module]

### Recommendation
[Reuse X, adapt Y, write Z from scratch following pattern in W]
```

### Step 4: Proceed with Implementation

After reporting, continue with the original task — but now Claude knows:
- What to reuse (don't reinvent)
- What patterns to follow (consistency)
- What's genuinely new (write from scratch)

## Rules

- Run this BEFORE writing code, not after
- Search at least 5 different angles (function names, class names, imports, utils, tests)
- If you find existing code, use it or follow its pattern — don't write a competing version
- If you find nothing, note that explicitly so we know we searched

$ARGUMENTS
