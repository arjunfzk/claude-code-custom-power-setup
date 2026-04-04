---
paths:
  - "docker/**"
  - "Dockerfile*"
  - "docker-compose*.yml"
  - ".dockerignore"
---

# Docker Rules

Multi-stage build. Use uv. Non-root user. Health checks. Memory limits.

```dockerfile
FROM python:3.11-slim AS builder
COPY --from=ghcr.io/astral-sh/uv /uv /usr/local/bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-editable

FROM python:3.11-slim
RUN adduser --system --no-create-home appuser
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY src/ src/
COPY prompts/ prompts/
ENV PATH="/app/.venv/bin:$PATH"
USER appuser
HEALTHCHECK --interval=30s --timeout=10s CMD curl -sf http://localhost:8000/health || exit 1
EXPOSE 8000
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
```

Docker compose: `mem_limit` on every service. `restart: unless-stopped`.
Named volumes for postgres, redis, vector DB.
Celery workers: `--max-tasks-per-child=100` to prevent memory leaks.
