# Project: [PROJECT_NAME]

LLM application engineering project. FastAPI + LangChain/LangGraph + PydanticAI.
Deployed via Docker. Experiments via git worktrees.

## Stack

- Python 3.11+, FastAPI, Pydantic v2, SQLAlchemy 2.0 (async), Alembic
- LLM: LangChain / LangGraph / PydanticAI, OpenAI + Anthropic + Perplexity APIs
- Vector DB: [ChromaDB / Pinecone / Qdrant / pgvector]
- DB: PostgreSQL 16, Redis 7 (cache + broker)
- Package manager: `uv` (NEVER pip, NEVER poetry)
- Formatter/linter: `ruff` (NEVER black, NEVER flake8, NEVER isort)
- Logging: loguru (console) + structlog (JSON files)
- Container: Docker + docker-compose

## Commands

- `uv sync` — install deps
- `uv sync --extra dev` — install with dev deps
- `uv run uvicorn src.api.main:app --reload` — dev server
- `uv run pytest tests/ -x -q` — tests (stop first failure)
- `uv run pytest tests/ --cov=src --cov-report=term-missing` — with coverage
- `uv run ruff check src/ --fix` — lint + autofix
- `uv run ruff format src/` — format
- `uv run mypy src/` — type check
- `uv run alembic upgrade head` — run migrations
- `docker compose up --build` — full stack

## Architecture

Router → Service → Repository layers. See @docs/architecture.md for full diagram.
NEVER put DB calls in routers. NEVER put HTTP types in services.
Use `Depends()` for all dependency injection.

## Code Standards

- IMPORTANT: Every .py file MUST have a module docstring at top: purpose, author, date, key dependencies.
- IMPORTANT: Every function MUST have a Google-style docstring: description, Args, Returns, Raises, Example.
- IMPORTANT: Add inline comments explaining non-obvious logic blocks.
- ALWAYS use type hints. Every function: parameter types + return type. Avoid `Any`.
- Async by default: `async def` for endpoints, `AsyncSession` for DB.
- Pydantic v2: `field_validator` NOT `validator`. `model_dump()` NOT `.dict()`.
- SQLAlchemy 2.0: `select()` NOT `query()`. `selectinload()` for eager loading.
- Prefer small, single-purpose functions. Aim for ~40 lines in Python, ~50-60 in TypeScript/Dart. Do not split solely to satisfy a line count — refactor when a function has multiple responsibilities, deep nesting, or becomes hard to name and test.

## LLM Engineering Rules

- CRITICAL: NEVER hardcode API keys. Use pydantic-settings + .env.
- CRITICAL: Log EVERY LLM call via structlog: model, tokens, latency_ms, cost_usd, status.
- CRITICAL: Save full LLM request/response to `logs/llm/{timestamp}_{model}_{chain}_{status}.json`.
- CRITICAL: Prompt templates in `prompts/` directory as .txt or .jinja2. NEVER inline in Python.
- ALL LLM calls: timeout, retry with exponential backoff, max_tokens, cost tracking.
- Set temperature explicitly. Document why in a comment.
- Count tokens BEFORE sending to LLM. Truncate gracefully, never error.
- Use structured output (Pydantic models) for all LLM responses.

## RAG Rules

- Chunk config in Pydantic model, not hardcoded.
- Batch embeddings, never one-at-a-time.
- Log retrieved chunks + similarity scores to `logs/rag/`.

## Memory & Process Management

- IMPORTANT: Close ALL async clients in FastAPI lifespan handler (startup/shutdown).
- IMPORTANT: No fire-and-forget tasks. Use `asyncio.TaskGroup` or explicit tracking.
- IMPORTANT: `gc.collect()` after large batch operations.
- Docker: set memory limits. Use `--max-tasks-per-child` for Celery workers.

## Database Safety

- CRITICAL: NEVER DELETE or UPDATE without showing row count first and getting permission.
- CRITICAL: NEVER modify existing migration files. Create new migrations only.
- Use parameterized queries. No f-string SQL.

## Testing

- pytest + pytest-asyncio. NEVER call real LLM APIs in tests.
- Mock LLM calls with recorded responses from `tests/fixtures/llm_responses/`.
- Test every new function. 85% minimum coverage.

## Git

- Conventional commits: feat:, fix:, refactor:, test:, docs:, chore:
- NEVER force push main. NEVER commit .env, API keys, model weights, logs/.
- Experiments: `git worktree add` for parallel isolated runs.

## Docs

- Keep `docs/architecture.md` and `docs/context.md` current.
- Run `/update-context` after significant changes.

@docs/architecture.md
@docs/context.md
