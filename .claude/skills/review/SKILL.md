---
name: review
description: Code review for LLM engineering — logging, resource cleanup, security, types, tests, docstrings
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

Review code changes against LLM engineering best practices.

## Checklist

### Documentation
- [ ] Module docstring at top of every new .py file
- [ ] Google-style docstring on every new function
- [ ] Inline comments on non-obvious logic

### LLM Calls
- [ ] Timeout + retry with exponential backoff
- [ ] Full logging: model, tokens, latency, cost, status
- [ ] Request/response saved to logs/llm/
- [ ] API keys from pydantic-settings, never hardcoded
- [ ] Temperature explicit with comment
- [ ] Prompt templates in prompts/, not inline

### Resources
- [ ] Async clients closed in lifespan
- [ ] No fire-and-forget tasks
- [ ] Context managers for all resources
- [ ] gc.collect() after batch operations

### API
- [ ] Pydantic v2 models for request/response
- [ ] Streaming with backpressure (is_disconnected check)
- [ ] Proper HTTP status codes
- [ ] Health endpoint checks all deps

### Security
- [ ] No secrets in code
- [ ] SQL parameterized
- [ ] Input validated before LLM (prompt injection)

### Testing
- [ ] New code has tests
- [ ] LLM calls mocked (no real APIs)

## Output

```
## Code Review

### Critical (must fix)
- [file:line] Issue

### Warnings (should fix)
- [file:line] Issue

### Good Practices Found
- [description]

Score: X/10
```

Review: `git diff main...HEAD -- '*.py'`

$ARGUMENTS
