---
name: debug-llm
description: Analyze LLM call logs for failures, slow calls, cost spikes, and quality issues
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

Analyze the LLM call logs in `logs/llm/` and `logs/rag/`.

## Analysis

1. **Recent logs**: `ls -lt logs/llm/ | head -30`
2. **Failures**: `grep -rl '"status": "error"' logs/llm/`
3. **Slow calls**: Find logs where `latency_ms > 5000`
4. **Cost analysis**: Sum `cost_usd` across recent logs
5. **Token waste**: Find calls where `completion_tokens` is very low relative to `prompt_tokens`
6. **RAG quality**: Check `logs/rag/` for low similarity scores (<0.7)

## Output

```
## LLM Debug Report

### Summary
- Logs analyzed: X
- Failures: Y (Z%)
- Avg latency: Xms (p95: Xms)
- Total cost: $X.XX

### Issues Found
1. [CRITICAL/WARNING] Description — file — fix

### Cost Optimization
- Estimated savings: $X.XX/day

### Recommendations
- ...
```

$ARGUMENTS
