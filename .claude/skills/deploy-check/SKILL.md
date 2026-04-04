---
name: deploy-check
description: Pre-deployment checklist — tests, types, lint, Docker build, health check, zombies, memory
context: fork
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

Run the full pre-deployment checklist.

## Checks

1. **Port availability** (FIRST — before starting anything):
```bash
python3 -c "
import socket
ports = {'API': 8000, 'Postgres': 5432, 'Redis': 6379}
# Override from .env if exists
import os
if os.path.exists('.env'):
    for line in open('.env'):
        if '=' in line and not line.startswith('#'):
            k, v = line.strip().split('=', 1)
            if k == 'API_PORT': ports['API'] = int(v)
            if k == 'POSTGRES_PORT': ports['Postgres'] = int(v)
            if k == 'REDIS_PORT': ports['Redis'] = int(v)
for name, port in ports.items():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(('127.0.0.1', port))
            print(f'  ✓ {name}:{port} free')
        except OSError:
            print(f'  ✗ {name}:{port} IN USE — will conflict!')
"
```
2. **Tests**: `uv run pytest tests/ -x -q --tb=short`
3. **Type check**: `uv run mypy src/ --no-error-summary`
4. **Lint**: `uv run ruff check src/`
5. **Docker build**: `docker compose build`
6. **Docker up**: `docker compose up -d`
7. **Health check**: `sleep 5 && curl -sf http://localhost:${API_PORT:-8000}/health | jq .`
8. **Zombie processes**: `ps aux | grep -E 'uvicorn|celery|python' | grep -v grep`
9. **Memory**: `docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"`
10. **Open ports audit**: `lsof -i -P -n | grep LISTEN | grep -E '800[0-9]|543[0-9]|637[0-9]' | head -20`
11. **No .env in git**: `git diff --cached --name-only | grep -E '\.env'`
12. **No debug code**: `grep -rn "breakpoint()\|pdb\|import pdb\|print(" src/ --include="*.py" | grep -v "structlog\|loguru\|logger"`

## Output

| Check | Status | Detail |
|-------|--------|--------|
| Tests | PASS/FAIL | X passed, Y failed |
| ... | ... | ... |

Overall: READY / NOT READY

$ARGUMENTS
