---
paths:
  - "experiments/**"
  - "configs/experiments/**"
---

# Experiment Rules

Git worktree pattern for parallel experiments:
```bash
git worktree add ../exp-{name} -b exp/{name}
cd ../exp-{name}
cp .env.example .env
uv sync
mkdir -p logs/llm logs/rag
```

Each worktree: own .env, own uv venv, own logs/, own docker-compose port.

Every experiment MUST have:
- Config in `configs/experiments/{name}.yaml` (hypothesis, changes, metrics)
- Its own `logs/` directory (NEVER share logs between experiments)
- README in experiment branch documenting results

Experiment config:
```yaml
experiment:
  name: "{name}"
  hypothesis: "{what you expect}"
  baseline: "configs/experiments/baseline.yaml"
  changes:
    key: value
  metrics:
    - retrieval_precision_at_5
    - answer_relevance_score
    - latency_p95_ms
    - cost_per_query_usd
```
