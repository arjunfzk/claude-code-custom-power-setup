---
name: cost-aware-pipeline
description: Design or audit an LLM pipeline for cost efficiency — model routing, caching, token optimization, budget tracking
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - mcp__context7__resolve-library-id
  - mcp__context7__get-library-docs
---

Design or audit an LLM call pipeline for cost efficiency.

## Two Modes

### Mode 1: AUDIT (default — run on existing code)

Analyze current LLM usage and find savings:

```bash
# 1. Find all LLM call sites
grep -rn "ChatOpenAI\|ChatAnthropic\|openai\..*create\|agent\.run\|chain\.ainvoke" src/ --include="*.py"

# 2. Analyze log files for actual costs
python3 -c "
import json, glob, collections
logs = glob.glob('logs/llm/*.json')
by_model = collections.defaultdict(lambda: {'calls': 0, 'cost': 0, 'tokens': 0})
by_chain = collections.defaultdict(lambda: {'calls': 0, 'cost': 0, 'tokens': 0})
for f in logs[-500:]:  # last 500 calls
    try:
        d = json.load(open(f))
        m = d.get('model', 'unknown')
        c = d.get('chain', 'unknown')
        cost = d.get('cost_usd', 0)
        tokens = d.get('tokens', {})
        total_t = tokens.get('prompt_tokens', 0) + tokens.get('completion_tokens', 0)
        by_model[m]['calls'] += 1
        by_model[m]['cost'] += cost
        by_model[m]['tokens'] += total_t
        by_chain[c]['calls'] += 1
        by_chain[c]['cost'] += cost
        by_chain[c]['tokens'] += total_t
    except: pass
print('=== BY MODEL ===')
for m, d in sorted(by_model.items(), key=lambda x: -x[1]['cost']):
    print(f'{m}: {d[\"calls\"]} calls, \${d[\"cost\"]:.4f}, {d[\"tokens\"]:,} tokens, \${d[\"cost\"]/max(d[\"calls\"],1):.6f}/call')
print()
print('=== BY CHAIN ===')
for c, d in sorted(by_chain.items(), key=lambda x: -x[1]['cost']):
    print(f'{c}: {d[\"calls\"]} calls, \${d[\"cost\"]:.4f}, {d[\"tokens\"]:,} tokens')
"
```

### Output (Audit Mode):

```
## Cost Audit

### Current Spend
| Model | Calls | Cost | Avg Cost/Call | Tokens |
|-------|-------|------|---------------|--------|
| gpt-4o | 340 | $12.40 | $0.036 | 580K |
| gpt-4o-mini | 89 | $0.12 | $0.001 | 120K |
| claude-sonnet | 56 | $1.80 | $0.032 | 95K |

### Optimization Opportunities

1. **Model downgrade**: 45% of gpt-4o calls are simple classification
   → Switch to gpt-4o-mini: saves $5.58/day (45% reduction)
   Affected chains: intent_classifier, sentiment_analyzer

2. **Prompt compression**: rag_chat system prompt is 800 tokens
   → Can be reduced to 200 tokens with same quality
   Saves: $0.02/call × 200 calls/day = $4.00/day

3. **Caching**: 30% of embedding calls are for unchanged documents
   → Content hash cache saves 30% of embedding costs
   Saves: $1.20/day

4. **Token limit**: max_tokens=4096 but avg completion is 150 tokens
   → Set max_tokens=500 for classification chains
   (Doesn't save on input, but prevents accidental expensive completions)

### Total Potential Savings: $10.78/day → $323/month
```

### Mode 2: DESIGN (build a new cost-aware pipeline)

When $ARGUMENTS includes "design" or "new":

1. Ask: what are the LLM tasks? (classify, generate, summarize, etc.)
2. For each task, recommend:
   - Model: cheapest that meets quality bar
   - Caching: what can be cached and for how long
   - Token optimization: prompt compression opportunities
   - Budget: max cost per call
3. Design the routing logic:

```python
class ModelRouter:
    """Route LLM calls to cheapest adequate model."""

    ROUTING = {
        "classification": {"model": "gpt-4o-mini", "max_tokens": 50, "temperature": 0},
        "extraction": {"model": "gpt-4o-mini", "max_tokens": 200, "temperature": 0},
        "summarization": {"model": "claude-haiku", "max_tokens": 500, "temperature": 0.3},
        "generation": {"model": "gpt-4o", "max_tokens": 1024, "temperature": 0.7},
        "complex_reasoning": {"model": "claude-sonnet", "max_tokens": 2048, "temperature": 0.5},
    }

    async def route(self, task_type: str, prompt: str) -> LLMConfig:
        config = self.ROUTING.get(task_type, self.ROUTING["generation"])
        # Check cache first
        cache_key = hash_prompt(prompt, config["model"])
        cached = await self.cache.get(cache_key)
        if cached:
            logger.info("cache_hit", task=task_type, model=config["model"])
            return cached
        return config
```

4. Produce: routing table, caching strategy, budget per endpoint, monitoring rules.

$ARGUMENTS
