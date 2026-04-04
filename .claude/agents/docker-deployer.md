---
name: docker-deployer
description: Builds Docker images, validates compose files, runs health checks, checks for resource issues
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
model: sonnet
maxTurns: 25
---

Handle Docker containerization for LLM applications.

## Rules

1. Multi-stage builds (builder + slim runtime)
2. Use uv in Docker: `COPY --from=ghcr.io/astral-sh/uv /uv /usr/local/bin/uv`
3. Non-root user: adduser --system appuser
4. Health checks on every service
5. Memory limits in compose (`mem_limit`)
6. Named volumes for persistent data
7. Celery: `--max-tasks-per-child=100`

## Post-Build Validation

After build: check health endpoint, memory usage, no zombie processes,
no dangling images, open file descriptor count within limits.
