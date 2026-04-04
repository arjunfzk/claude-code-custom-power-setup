# Stage 1: Dependencies
FROM python:3.11-slim AS builder
COPY --from=ghcr.io/astral-sh/uv /uv /usr/local/bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-editable

# Stage 2: Runtime
FROM python:3.11-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
RUN adduser --system --no-create-home appuser
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY src/ src/
COPY prompts/ prompts/
ENV PATH="/app/.venv/bin:$PATH"
USER appuser
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:8000/health || exit 1
EXPOSE 8000
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
