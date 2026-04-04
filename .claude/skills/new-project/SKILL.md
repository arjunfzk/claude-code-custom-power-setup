---
name: new-project
description: Scaffold a new LLM application project with full structure, docs, Docker, logging, and test setup
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---

Scaffold a complete LLM application project from the template.

## What Gets Created

### Core Structure
```
src/
  api/main.py           — FastAPI app with lifespan handler
  api/routes/health.py  — Health endpoint checking all dependencies
  api/deps.py           — Dependency injection (DB session, HTTP client, etc.)
  chains/               — LangChain/LangGraph chains (empty, ready for first chain)
  agents/               — PydanticAI agent definitions (empty)
  rag/                  — RAG pipeline (chunking, embedding, search — stubs)
  models/schemas.py     — Base Pydantic models (ErrorResponse, PaginatedResponse)
  services/llm_logger.py — Structured LLM call logging to logs/llm/
  db/base.py            — SQLAlchemy async engine setup
  config/settings.py    — Pydantic Settings with .env loading
  logging/setup.py      — loguru (console) + structlog (JSON file) dual logging
tests/
  conftest.py           — Shared fixtures (mock LLM, test DB, test client)
  test_api/test_health.py — Health endpoint test
  fixtures/llm_responses/ — Directory for recorded LLM responses
prompts/                — Prompt template directory (empty, with README)
docs/architecture.md    — Generated with Mermaid diagrams
docs/context.md         — Initial project context
ui/                     — Test UI templates (Streamlit, Gradio, HTML)
docker/Dockerfile       — Multi-stage build with uv
docker/docker-compose.yml — Full stack with health checks + memory limits
scripts/seed.py         — Database seed script stub
configs/                — Environment configs
logs/llm/ logs/rag/     — Log directories (gitignored)
.env.example            — Template for environment variables
.gitignore              — Python + LLM project ignores
pyproject.toml          — uv project with dev dependencies
```

### Generated Docs
- `docs/architecture.md` with Mermaid system diagram, data flow, API routes
- `docs/context.md` with initial project state

### Initialize
```bash
uv init (if no pyproject.toml)
uv add fastapi uvicorn pydantic pydantic-settings sqlalchemy alembic httpx
uv add langchain langchain-openai langchain-anthropic
uv add structlog loguru
uv add --dev pytest pytest-asyncio pytest-cov ruff mypy httpx
git init && git add -A && git commit -m "feat: scaffold LLM project"
```

$ARGUMENTS
