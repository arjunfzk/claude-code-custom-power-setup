---
name: new-experiment
description: Create a fully isolated experiment with git worktree, own uv environment, own logs, own Docker — auto-finds free ports
allowed-tools:
  - Bash
  - Write
  - Read
---

Create a parallel experiment using git worktrees with full isolation.

## Process

1. Parse experiment name from $ARGUMENTS (e.g., "chunking-256" or "reranker-cohere")

2. **Find free ports BEFORE creating anything:**
```bash
# Find next available port starting from 8001
python3 -c "
import socket

def is_port_free(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(('127.0.0.1', port))
            return True
        except OSError:
            return False

# Check API port (8001+), Postgres (5433+), Redis (6380+)
api_port = next(p for p in range(8001, 8100) if is_port_free(p))
pg_port = next(p for p in range(5433, 5500) if is_port_free(p))
redis_port = next(p for p in range(6380, 6400) if is_port_free(p))
print(f'API_PORT={api_port}')
print(f'POSTGRES_PORT={pg_port}')
print(f'REDIS_PORT={redis_port}')
"
```
Save these port numbers for use in steps below.

3. Create experiment branch and worktree:
```bash
git stash --include-untracked 2>/dev/null  # save any uncommitted work
git worktree add ../exp-$ARGUMENTS[1] -b exp/$ARGUMENTS[1]
```

4. Set up isolated environment:
```bash
cd ../exp-$ARGUMENTS[1]
cp .env.example .env
uv sync
mkdir -p logs/llm logs/rag
```

5. **Write .env with assigned ports:**
Append to the `.env` file:
```
API_PORT={api_port}
POSTGRES_PORT={pg_port}
REDIS_PORT={redis_port}
```

6. Create experiment config in `configs/experiments/$ARGUMENTS[1].yaml`:
```yaml
experiment:
  name: "$ARGUMENTS[1]"
  hypothesis: "[TO BE FILLED]"
  baseline: "configs/experiments/baseline.yaml"
  ports:
    api: {api_port}
    postgres: {pg_port}
    redis: {redis_port}
  changes:
    # [FILL: what's different from baseline]
  metrics:
    - retrieval_precision_at_5
    - answer_relevance_score
    - latency_p95_ms
    - cost_per_query_usd
```

7. Create experiment README in worktree root:
```markdown
# Experiment: $ARGUMENTS[1]

## Hypothesis
[To be filled]

## Changes from Baseline
[What's different]

## Ports (auto-assigned, verified free)
- API: {api_port}
- PostgreSQL: {pg_port}
- Redis: {redis_port}

## How to Run
```bash
cd ../exp-$ARGUMENTS[1]
docker compose -f docker/docker-compose.yml up -d
uv run uvicorn src.api.main:app --port {api_port} --reload
```

## Results
[To be filled after experiment]
```

8. **Verify ports are still free** (race condition guard):
```bash
python3 -c "
import socket
for port, name in [({api_port}, 'API'), ({pg_port}, 'Postgres'), ({redis_port}, 'Redis')]:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(('127.0.0.1', port))
            print(f'  ✓ {name} port {port}: free')
        except OSError:
            print(f'  ✗ {name} port {port}: IN USE — pick another!')
"
```

9. Report:
```
Experiment ready:
  Branch: exp/{name}
  Worktree: ../exp-{name}/
  Venv: ../exp-{name}/.venv/
  Config: configs/experiments/{name}.yaml
  Logs: ../exp-{name}/logs/

  Ports (verified free):
    API:      {api_port}
    Postgres: {pg_port}
    Redis:    {redis_port}

  Start:
    cd ../exp-{name}
    docker compose up -d
    uv run uvicorn src.api.main:app --port {api_port} --reload

  Compare: spawn experiment-analyzer agent
```

$ARGUMENTS
