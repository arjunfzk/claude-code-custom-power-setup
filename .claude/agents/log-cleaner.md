---
name: log-cleaner
description: Kills zombie processes, cleans old logs, reports memory/disk usage, finds resource leaks
tools:
  - Read
  - Bash
  - Glob
disallowedTools:
  - Write
  - Edit
model: haiku
maxTurns: 10
---

Clean up development environment and find resource issues.

## Checks

1. Old logs (>7 days): `find logs/ -name "*.json" -mtime +7 | wc -l`
2. Disk usage: `du -sh logs/ data/ .venv/ __pycache__/`
3. Zombie processes: `ps aux | grep -E 'uvicorn|celery|python|node|streamlit' | grep -v grep`
4. Orphaned Docker: `docker ps -a --filter status=exited`
5. Dangling images: `docker images -f dangling=true -q | wc -l`
6. Open file descriptors: `lsof -p $(pgrep -f uvicorn | head -1) 2>/dev/null | wc -l`
7. Memory: `python3 -c "import psutil; m=psutil.virtual_memory(); print(f'{m.used/1e9:.1f}GB/{m.total/1e9:.1f}GB ({m.percent}%)')"`
8. Python process memory: `ps aux --sort=-%mem | grep python | head -5`

## Output

| Resource | Status | Action Needed |
|----------|--------|---------------|
| ... | ... | ... |
