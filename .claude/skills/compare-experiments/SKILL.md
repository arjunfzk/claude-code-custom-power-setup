---
name: compare-experiments
description: Side-by-side comparison of experiment results — metrics, configs, costs, quality scores from logs
context: fork
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

Compare results across experiment worktrees using their logs and configs.

## Process

1. **Find experiments to compare:**

If $ARGUMENTS specifies experiment names, use those. Otherwise:
```bash
# List all experiment worktrees
git worktree list | grep "exp-" | awk '{print $1}'
```

If only one experiment exists, compare it against the main project.
If multiple exist, compare all against main (baseline).

2. **Read each experiment's config:**
```bash
# For each experiment path:
cat <path>/configs/experiments/*.yaml 2>/dev/null
```
Extract: hypothesis, what changed from baseline.

3. **Analyze LLM logs from each experiment:**
```bash
# For each experiment path:
python3 -c "
import json, glob, statistics

logs = glob.glob('<path>/logs/llm/*.json')
if not logs:
    print('No LLM logs found')
    exit()

latencies = []
costs = []
errors = 0
total = len(logs)
models = {}

for f in logs:
    try:
        d = json.load(open(f))
        latencies.append(d.get('latency_ms', 0))
        costs.append(d.get('cost_usd', 0))
        if d.get('status') == 'error':
            errors += 1
        m = d.get('model', 'unknown')
        models[m] = models.get(m, 0) + 1
    except: pass

print(f'Total calls: {total}')
print(f'Errors: {errors} ({errors/total*100:.1f}%)')
print(f'Avg latency: {statistics.mean(latencies):.0f}ms')
print(f'P95 latency: {sorted(latencies)[int(len(latencies)*0.95)]:.0f}ms')
print(f'Total cost: \${sum(costs):.4f}')
print(f'Avg cost/call: \${statistics.mean(costs):.6f}')
print(f'Models: {models}')
"
```

4. **Analyze RAG logs (if exist):**
```bash
python3 -c "
import json, glob, statistics

logs = glob.glob('<path>/logs/rag/*.json')
if not logs:
    print('No RAG logs')
    exit()

scores = []
for f in logs:
    try:
        d = json.load(open(f))
        scores.extend(d.get('scores', []))
    except: pass

if scores:
    print(f'Queries: {len(logs)}')
    print(f'Avg top score: {statistics.mean([max(s) if s else 0 for s in [json.load(open(f)).get(\"scores\",[]) for f in logs]]):.3f}')
    print(f'Avg score: {statistics.mean(scores):.3f}')
    print(f'Scores < 0.7: {sum(1 for s in scores if s < 0.7)} ({sum(1 for s in scores if s < 0.7)/len(scores)*100:.0f}%)')
"
```

5. **Diff the configs:**
```bash
# Show what changed between baseline and experiment
diff <(cat configs/experiments/baseline.yaml 2>/dev/null || echo "no baseline") \
     <(cat <exp_path>/configs/experiments/*.yaml 2>/dev/null || echo "no config")
```

6. **Present comparison table:**

```
## Experiment Comparison

### What Changed

| Experiment | Hypothesis | Key Changes |
|-----------|-----------|-------------|
| main (baseline) | — | Default config |
| exp-chunking-256 | Smaller chunks improve precision | chunk_size: 512→256, overlap: 50→25 |
| exp-reranker | Reranking improves relevance | Added Cohere rerank-v3 after retrieval |

### LLM Metrics

| Metric | main | exp-chunking-256 | exp-reranker | Winner |
|--------|------|-------------------|--------------|--------|
| Total calls | 156 | 142 | 161 | — |
| Error rate | 2.1% | 1.4% (-33%) | 3.1% (+48%) | chunking |
| Avg latency | 890ms | 720ms (-19%) | 1,240ms (+39%) | chunking |
| P95 latency | 4,200ms | 3,100ms (-26%) | 5,800ms (+38%) | chunking |
| Total cost | $12.34 | $8.91 (-28%) | $14.56 (+18%) | chunking |
| Avg cost/call | $0.079 | $0.063 (-20%) | $0.090 (+14%) | chunking |

### RAG Metrics (if available)

| Metric | main | exp-chunking-256 | exp-reranker | Winner |
|--------|------|-------------------|--------------|--------|
| Avg top score | 0.85 | 0.91 (+7%) | 0.93 (+9%) | reranker |
| Avg score | 0.72 | 0.78 (+8%) | 0.81 (+12%) | reranker |
| Low scores (<0.7) | 23% | 12% (-48%) | 8% (-65%) | reranker |

### Recommendation

[Based on the metrics, which experiment should be adopted and why.
Consider tradeoffs: e.g., reranker has better retrieval quality but
higher latency and cost — is the quality improvement worth it?]
```

7. **If the user asks, show the commands to adopt the winning experiment:**
```bash
cd ~/projects/my-project
git merge exp/<winner-branch>
git worktree remove ../exp-<winner>
git branch -d exp/<winner>
```

$ARGUMENTS
