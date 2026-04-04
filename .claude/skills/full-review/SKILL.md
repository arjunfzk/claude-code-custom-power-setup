---
name: full-review
description: 9-agent parallel code review — tests, security, performance, quality, dependencies, simplification. Use pre-merge for thorough review.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Agent
---

Launch a comprehensive parallel code review using 9 specialist agents. Each agent reviews from a different angle simultaneously. Results synthesized into a prioritized report.

Inspired by the HAMY 9-agent parallel review pattern.

## When to Use

- **Pre-merge**: before merging a feature branch into main
- **Pre-deploy**: before shipping to production
- **Periodic**: weekly quality audit
- NOT for every commit — that's what hooks and `/review` are for

## Process

### Step 1: Identify What to Review

```bash
# Get the diff to review
DIFF=$(git diff main...HEAD --stat)
CHANGED_FILES=$(git diff main...HEAD --name-only -- '*.py')
echo "Files changed: $(echo "$CHANGED_FILES" | wc -l)"
echo "$DIFF"
```

If no diff against main, review all src/ files.

### Step 2: Spawn 9 Agents in Parallel

Launch ALL of these simultaneously (single message, multiple Agent tool calls):

**Agent 1: Test Runner**
- Run `uv run pytest tests/ -v --tb=short`
- Report: which tests pass, which fail, coverage gaps

**Agent 2: Security Reviewer** (use `security-reviewer` agent)
- Prompt injection, secrets, SQL injection, auth, error leakage

**Agent 3: Performance Reviewer** (use `performance-reviewer` agent)
- N+1 queries, blocking async, memory leaks, LLM optimization

**Agent 4: Code Quality**
- Docstrings present? Type hints complete? Functions <30 lines? DRY?

**Agent 5: Test Quality**
- Are tests testing behavior or implementation? Mock quality? Edge cases?
- Coverage ROI: are we testing the risky parts or the trivial parts?

**Agent 6: LLM Engineering Review**
- LLM calls logged? Retry/timeout? Prompts in files? Cost tracked?
- Guardrails on agent input/output? Grounding checks?

**Agent 7: Dependency & Deploy Safety**
- New dependencies: license OK? Security OK? Actively maintained?
- Breaking API changes? Migration safety?

**Agent 8: Architecture Compliance**
- Router→Service→Repository respected? No DB in routers?
- Async patterns correct? Dependency injection used?

**Agent 9: Simplification**
- "Could this be simpler?" Over-engineering? Premature abstraction?
- Dead code? Unused imports? Copy-pasted blocks?

### Step 3: Collect Results

Wait for all 9 agents. Each returns a list of findings.

### Step 4: Synthesize

Merge all findings into a single prioritized report:

```
## Full Code Review: [branch]

**Reviewed by:** 9 parallel agents
**Files:** [N] Python files changed
**Date:** [date]

### Verdict: [READY TO MERGE / NEEDS ATTENTION / NEEDS WORK]

### Critical (block merge)
- [Agent: Security] file:line — Description
- [Agent: Test Runner] 3 tests failing

### High (fix before merge)
- [Agent: Performance] file:line — N+1 query in user listing
- [Agent: LLM] file:line — No timeout on LLM call

### Medium (fix soon)
- [Agent: Quality] file:line — Missing docstring
- [Agent: Simplification] file:line — This function can be 3 lines

### Low (nice to have)
- [Agent: Architecture] file:line — Consider extracting to service

### Summary by Agent
| Agent | Issues | Critical | High | Medium | Low |
|-------|--------|----------|------|--------|-----|
| Test Runner | 2 | 1 | 1 | 0 | 0 |
| Security | 1 | 0 | 1 | 0 | 0 |
| Performance | 3 | 0 | 1 | 2 | 0 |
| ... | ... | ... | ... | ... | ... |

### Tests
- Passed: X
- Failed: Y
- Coverage: Z%
```

Save to: `docs/reviews/[date]-[branch].md`

## Cost Note

This skill spawns 9 agents. Approximate cost: ~$0.50-$1.00 per review (mostly Sonnet, security uses Opus). Worth it for pre-merge reviews. Don't run on every commit.

$ARGUMENTS
