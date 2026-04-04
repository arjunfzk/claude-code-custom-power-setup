# Project Workflow & Code Flow

> ASCII diagrams showing how every piece of the system connects.
> Updated by `/update-context`. Last updated: [DATE]

---

## 1. Request Lifecycle (End-to-End)

```
                            ┌─────────────────────────────────────┐
                            │          CLIENT / TEST UI           │
                            │  (Streamlit :8501 / Gradio :7860    │
                            │   / HTML+HTMX / curl / httpx)       │
                            └──────────────┬──────────────────────┘
                                           │
                                    POST /chat/stream
                                    { "message": "..." }
                                           │
                            ┌──────────────▼──────────────────────┐
                            │         FastAPI  :8000               │
                            │                                      │
                            │  ┌──────────────────────────────┐   │
                            │  │   Middleware Pipeline          │   │
                            │  │   1. CORS                     │   │
                            │  │   2. Request ID injection     │   │
                            │  │   3. Structured logging       │   │
                            │  │   4. Rate limiting            │   │
                            │  └──────────────┬───────────────┘   │
                            │                 │                    │
                            │  ┌──────────────▼───────────────┐   │
                            │  │   Router (src/api/routes/)    │   │
                            │  │   - Validate request (Pydantic│   │
                            │  │   - Inject deps (Depends())   │   │
                            │  │   - Call service layer        │   │
                            │  └──────────────┬───────────────┘   │
                            └─────────────────┼───────────────────┘
                                              │
                            ┌─────────────────▼───────────────────┐
                            │       Service Layer                  │
                            │       (src/services/)                │
                            │                                      │
                            │   ┌─────────────────────────────┐   │
                            │   │  1. Retrieve context (RAG)   │   │
                            │   │  2. Build prompt             │   │
                            │   │  3. Count tokens             │   │
                            │   │  4. Call LLM                 │   │
                            │   │  5. Parse response           │   │
                            │   │  6. Log everything           │   │
                            │   └─────────────────────────────┘   │
                            └───┬──────────┬──────────┬───────────┘
                                │          │          │
                 ┌──────────────▼┐  ┌──────▼─────┐  ┌▼─────────────┐
                 │  RAG Pipeline  │  │  LLM Call   │  │   Database    │
                 │  (src/rag/)    │  │             │  │  (src/db/)    │
                 │                │  │  OpenAI     │  │               │
                 │  1. Embed query│  │  Anthropic  │  │  PostgreSQL   │
                 │  2. Vec search │  │  Perplexity │  │  + pgvector   │
                 │  3. Rerank     │  │             │  │               │
                 │  4. Return     │  │  timeout:30s│  │  SQLAlchemy   │
                 │     chunks     │  │  retry: 3x  │  │  async        │
                 └───────┬───────┘  └──────┬──────┘  └───────────────┘
                         │                 │
                         │                 │
              ┌──────────▼─────┐  ┌────────▼──────────┐
              │   Vector DB     │  │   Logging Pipeline │
              │                 │  │                    │
              │  pgvector /     │  │  ┌──────────────┐ │
              │  ChromaDB /     │  │  │ structlog    │ │
              │  Pinecone       │  │  │ → JSON file  │ │
              │                 │  │  │ → logs/llm/  │ │
              │  Embeddings:    │  │  └──────────────┘ │
              │  text-embed-3   │  │  ┌──────────────┐ │
              │  / sentence-tf  │  │  │ loguru       │ │
              └─────────────────┘  │  │ → console    │ │
                                   │  │ (colored)    │ │
                                   │  └──────────────┘ │
                                   │  ┌──────────────┐ │
                                   │  │ RAG logs     │ │
                                   │  │ → logs/rag/  │ │
                                   │  └──────────────┘ │
                                   └───────────────────┘
```

---

## 2. RAG Pipeline Detail

```
    User Query: "How does attention work?"
         │
         ▼
    ┌─────────────┐
    │  Embed Query │ ◄── Same embedding model as documents
    │  (async)     │     text-embedding-3-small / sentence-transformers
    └──────┬──────┘
           │ vector [1536 dims]
           ▼
    ┌──────────────┐
    │ Vector Search │ ◄── pgvector: SELECT ... ORDER BY embedding <=> query LIMIT k
    │ (top_k=10)   │     Returns: chunks + similarity scores
    └──────┬───────┘
           │ 10 chunks with scores
           ▼
    ┌──────────────┐
    │ Score Filter  │ ◄── Drop chunks with score < 0.5 (noise)
    │              │
    └──────┬───────┘
           │ ~5-8 chunks
           ▼
    ┌──────────────┐
    │  Reranker     │ ◄── Optional: Cohere rerank-v3 / cross-encoder
    │  (optional)   │     Re-scores based on semantic relevance
    └──────┬───────┘
           │ reranked top 5
           ▼
    ┌──────────────────────┐
    │  Token Counter        │ ◄── tiktoken: count context tokens
    │  max_context = 3000   │     Truncate if over budget
    │  tokens               │     Keep highest-scored chunks
    └──────┬───────────────┘
           │ context string
           ▼
    ┌──────────────────────┐
    │  Log Retrieval        │ ──► logs/rag/{timestamp}_{hash}.json
    │  (query, chunks,      │     {query, chunks, scores, latency}
    │   scores, latency)    │
    └──────┬───────────────┘
           │
           ▼
    Context ready for LLM call
```

---

## 3. LLM Call Flow

```
    Prompt + Context ready
         │
         ▼
    ┌──────────────────────┐
    │  Load Prompt Template │ ◄── prompts/rag_chat_system.txt
    │  from prompts/ dir    │     prompts/rag_chat_user.jinja2
    │  (NEVER inline)       │     Jinja2 renders variables
    └──────┬───────────────┘
           │ rendered prompt
           ▼
    ┌──────────────────────┐
    │  Token Count Check    │ ◄── Verify total < model context limit
    │  prompt + context +   │     Reserve space for response
    │  system < limit       │
    └──────┬───────────────┘
           │
           ▼
    ┌──────────────────────┐
    │  LLM API Call         │
    │                       │
    │  Provider: OpenAI /   │     ┌───────────────────────┐
    │  Anthropic / etc      │────►│  Retry Logic          │
    │                       │     │  tenacity:            │
    │  timeout: 30s         │     │    wait_exponential   │
    │  max_tokens: 1024     │     │    (min=1, max=60)    │
    │  temperature: 0.7     │     │    stop=3 attempts    │
    │                       │     └───────────────────────┘
    └──────┬───────────────┘
           │ response + usage
           ▼
    ┌──────────────────────┐
    │  Parse Response       │ ◄── Structured output via Pydantic
    │  + Extract Usage      │     Or string parsing
    └──────┬───────────────┘
           │
           ├───────────────────────────────────────┐
           │                                       │
           ▼                                       ▼
    ┌──────────────────┐                 ┌─────────────────────┐
    │  structlog.info   │                 │  Save Full JSON      │
    │                   │                 │                      │
    │  model: gpt-4o    │                 │  logs/llm/           │
    │  tokens: 450+120  │                 │  {timestamp}_        │
    │  latency: 1240ms  │                 │  {model}_{chain}_    │
    │  cost: $0.0087    │                 │  {status}.json       │
    │  status: success   │                 │                      │
    │                   │                 │  Contains:            │
    │  → console (loguru)│                 │  - Full prompt        │
    │  → app.json (file) │                 │  - Full response      │
    │                   │                 │  - Context chunks     │
    └──────────────────┘                 │  - Token usage        │
                                          │  - Latency + cost     │
                                          │  - Model + temp       │
                                          └─────────────────────┘
```

---

## 4. Streaming Response Flow

```
    Client sends POST /chat/stream
         │
         ▼
    ┌───────────────────────────────────────┐
    │  FastAPI StreamingResponse             │
    │                                       │
    │  async def generate():                │
    │      for chunk in chain.astream():    │
    │          │                             │
    │          ├── Check: client connected? ─┤──► YES: continue
    │          │   request.is_disconnected() │        yield SSE chunk
    │          │                             │
    │          └──► NO (disconnected): ──────┤──► BREAK (stop generating)
    │                save tokens!            │        don't waste API calls
    │                                       │
    │      yield "data: [DONE]\n\n"         │
    └───────────────────┬───────────────────┘
                        │
                        │ Server-Sent Events
                        ▼
    ┌───────────────────────────────────────┐
    │  Client receives SSE stream:           │
    │                                       │
    │  data: {"content": "Attention"}        │
    │  data: {"content": " mechanisms"}      │
    │  data: {"content": " allow"}           │
    │  data: {"content": " models"}          │
    │  data: {"content": " to focus"}        │
    │  ...                                   │
    │  data: [DONE]                          │
    └───────────────────────────────────────┘
```

---

## 5. Background Job Flow

```
    Client: POST /batch/analyze  { "documents": [...] }
         │
         ▼
    ┌────────────────────┐
    │  API returns 202    │ ──► { "job_id": "abc-123", "status": "queued" }
    │  (Accepted)         │     Client polls GET /jobs/abc-123
    └────────┬───────────┘
             │ BackgroundTasks.add_task() or Celery.delay()
             ▼
    ┌────────────────────────────────────────┐
    │  Task Queue (Redis)                     │
    │                                         │
    │  ┌─────────┐  ┌─────────┐  ┌────────┐ │
    │  │ Job abc  │  │ Job def  │  │ Job ghi│ │
    │  │ queued   │  │ running  │  │ queued │ │
    │  └────┬────┘  └─────────┘  └────────┘ │
    └───────┼─────────────────────────────────┘
            │
            ▼
    ┌────────────────────────────────────────┐
    │  Celery Worker                          │
    │  (--max-tasks-per-child=100)            │
    │                                         │
    │  For each document:                     │
    │    1. Chunk → Embed → Store in VDB      │
    │    2. Run analysis chain                 │
    │    3. Log LLM call to logs/llm/         │
    │    4. Update job status in DB            │
    │                                         │
    │  On complete:                            │
    │    job.status = "complete"               │
    │    job.result = { analysis: ... }        │
    └────────────────────────────────────────┘
            │
            ▼
    Client polls: GET /jobs/abc-123
    Response: { "status": "complete", "result": { ... } }
```

---

## 6. Experiment Worktree Flow

```
    ~/projects/
    │
    ├── my-rag-chatbot/              ◄── MAIN PROJECT
    │   ├── src/                          Branch: main
    │   ├── .venv/                        Port: 8000 (API), 5432 (PG), 6379 (Redis)
    │   ├── .env                          Docker: running
    │   ├── logs/llm/                     Claude session: Terminal 1
    │   └── docker-compose.yml
    │
    ├── exp-chunking-256/            ◄── EXPERIMENT 1 (git worktree)
    │   ├── src/                          Branch: exp/chunking-256
    │   ├── .venv/  (OWN venv)            Port: 8001 (API), 5433 (PG), 6380 (Redis)
    │   ├── .env    (OWN env)             Docker: running (own containers)
    │   ├── logs/   (OWN logs)            Claude session: Terminal 2
    │   └── configs/experiments/
    │       └── chunking-256.yaml
    │
    └── exp-reranker-cohere/         ◄── EXPERIMENT 2 (git worktree)
        ├── src/                          Branch: exp/reranker-cohere
        ├── .venv/  (OWN venv)            Port: 8002 (API), 5434 (PG), 6381 (Redis)
        ├── .env    (OWN env)             Docker: running (own containers)
        ├── logs/   (OWN logs)            Claude session: Terminal 3
        └── configs/experiments/
            └── reranker-cohere.yaml

    Each worktree:
    ✓ Own git branch (changes don't affect main)
    ✓ Own .venv (uv sync creates independent env)
    ✓ Own .env (own API keys, own ports)
    ✓ Own logs/ (separate LLM/RAG logs for comparison)
    ✓ Own Docker containers (no port conflicts — auto-checked)
    ✓ Own Claude Code session (separate context window)

    Port assignment: /new-experiment auto-finds free ports
    ┌──────────────────────────────────────────────────┐
    │  python3 -c "                                     │
    │    import socket                                  │
    │    def is_port_free(port):                        │
    │      with socket.socket() as s:                   │
    │        try: s.bind(('127.0.0.1', port)); return T │
    │        except: return False                       │
    │    api = next(p for p in range(8001,8100)          │
    │             if is_port_free(p))                    │
    │  "                                                │
    └──────────────────────────────────────────────────┘
```

---

## 7. Logging Pipeline

```
    ┌─────────────────────────────────────────────┐
    │              APPLICATION CODE                 │
    │                                               │
    │  from src.logging.setup import get_logger     │
    │  logger = get_logger(__name__)                │
    │                                               │
    │  logger.info("processing", user_id=123)       │
    │  logger.info("llm_call", model="gpt-4o",      │
    │              tokens=570, latency_ms=1240)      │
    └──────────┬──────────────┬────────────────────┘
               │              │
       ┌───────▼──────┐  ┌───▼──────────────┐
       │   loguru       │  │   structlog       │
       │   (console)    │  │   (JSON files)    │
       │                │  │                    │
       │  Colored output│  │  Structured JSON   │
       │  Human-readable│  │  Machine-parseable │
       │  Dev-friendly  │  │  Production-ready  │
       └───────┬───────┘  └───┬────────────────┘
               │              │
               ▼              ▼
    ┌──────────────┐  ┌─────────────────┐
    │  Terminal     │  │  logs/app.json   │  ◄── General app logs
    │  (stdout)     │  │                  │
    │              │  │  logs/llm/       │  ◄── Full LLM request/response
    │  2026-03-28  │  │  {ts}_{model}_   │      (for manual review +
    │  14:23:15    │  │  {chain}_{status} │       /debug-llm analysis)
    │  [info]      │  │  .json           │
    │  llm_call    │  │                  │
    │  model=gpt4o │  │  logs/rag/       │  ◄── RAG retrieval logs
    │  latency=1.2s│  │  {ts}_{hash}     │      (for rag-debugger agent)
    │              │  │  .json           │
    └──────────────┘  └─────────────────┘
```

---

## 8. Docker Deployment Architecture

```
    ┌──── Docker Compose ────────────────────────────────┐
    │                                                     │
    │  ┌───────────────────────────────────────────┐     │
    │  │  API Container                             │     │
    │  │  Image: python:3.11-slim (multi-stage)     │     │
    │  │  User: appuser (non-root)                  │     │
    │  │  Port: ${API_PORT:-8000}                   │     │
    │  │  Memory: 2GB limit                         │     │
    │  │  Health: curl /health every 30s            │     │
    │  │  CMD: uvicorn ... --workers 2              │     │
    │  └────────────┬──────────────────────────────┘     │
    │               │                                     │
    │  ┌────────────▼──────────────────────────────┐     │
    │  │  Worker Container                          │     │
    │  │  Same image, different CMD                 │     │
    │  │  CMD: celery worker                        │     │
    │  │  --max-tasks-per-child=100 (memory leak    │     │
    │  │   prevention: worker restarts after 100    │     │
    │  │   tasks, freeing accumulated memory)       │     │
    │  │  Memory: 4GB limit                         │     │
    │  └────────────┬──────────────────────────────┘     │
    │               │                                     │
    │  ┌────────────▼───────┐  ┌───────────────────┐     │
    │  │  PostgreSQL + pgvec│  │  Redis              │     │
    │  │  Port: ${PG_PORT}  │  │  Port: ${REDIS_PORT}│     │
    │  │  Volume: pgdata    │  │  Volume: redisdata  │     │
    │  │  Health: pg_isready│  │  Health: redis ping │     │
    │  │  Memory: 1GB       │  │  Memory: 512MB      │     │
    │  └────────────────────┘  └───────────────────┘     │
    │                                                     │
    └─────────────────────────────────────────────────────┘

    Resource Safety:
    ┌─────────────────────────────────────────────┐
    │  ✓ mem_limit on every container              │
    │  ✓ Health checks on every service            │
    │  ✓ restart: unless-stopped                   │
    │  ✓ Non-root user in app containers           │
    │  ✓ Named volumes (data survives restarts)    │
    │  ✓ max-tasks-per-child (celery memory leak   │
    │    prevention)                                │
    │  ✓ depends_on with health condition           │
    │    (API waits for DB+Redis to be healthy)    │
    └─────────────────────────────────────────────┘
```

---

## 9. Claude Code Hook Flow

```
    Claude writes src/chains/rag_chat.py
         │
         ▼
    ┌─── PostToolUse ──────────────────────────┐
    │  matcher: Write|Edit                      │
    │                                           │
    │  Hook 1: ruff format + lint               │
    │  ┌─────────────────────────────────┐     │
    │  │ Is it a .py file?               │     │
    │  │ YES → ruff check --fix          │     │
    │  │     → ruff format               │     │
    │  │ NO  → skip                      │     │
    │  └────────────────┬────────────────┘     │
    │                   │                       │
    │  Hook 2: auto-test                        │
    │  ┌─────────────────────────────────┐     │
    │  │ Is it .py in src/ (not test)?   │     │
    │  │ YES → find matching test file   │     │
    │  │     → pytest -x -q (30s timeout)│     │
    │  │     → show last 10 lines        │     │
    │  │ NO  → skip                      │     │
    │  └─────────────────────────────────┘     │
    └──────────────────────────────────────────┘

    Claude tries: Bash("pip install requests")
         │
         ▼
    ┌─── PreToolUse ───────────────────────────┐
    │  matcher: Bash                            │
    │                                           │
    │  Hook 1: pip blocker                      │
    │  ┌─────────────────────────────────┐     │
    │  │ Command starts with pip?        │     │
    │  │ YES → "BLOCKED: Use uv add"     │     │
    │  │     → exit 2 (BLOCKS execution) │     │
    │  └─────────────────────────────────┘     │
    │                                           │
    │  Hook 2: dangerous command blocker        │
    │  ┌─────────────────────────────────┐     │
    │  │ Contains rm -rf / force push /  │     │
    │  │ DROP TABLE / etc?               │     │
    │  │ YES → "BLOCKED: Dangerous"      │     │
    │  │     → exit 2                    │     │
    │  └─────────────────────────────────┘     │
    │                                           │
    │  Hook 3: DB safety                        │
    │  ┌─────────────────────────────────┐     │
    │  │ Contains DELETE FROM / UPDATE?  │     │
    │  │ YES → check for WHERE clause    │     │
    │  │     → "DB SAFETY: table X,      │     │
    │  │        confirm with user"       │     │
    │  │     → exit 2                    │     │
    │  └─────────────────────────────────┘     │
    └──────────────────────────────────────────┘

    Claude tries: Write("src/db/migrations/001.py")
         │
         ▼
    ┌─── PreToolUse ───────────────────────────┐
    │  matcher: Write|Edit                      │
    │                                           │
    │  Hook: migration protector                │
    │  ┌─────────────────────────────────┐     │
    │  │ Path contains /migrations/?     │     │
    │  │ YES → "BLOCKED: Create new      │     │
    │  │        migration instead"       │     │
    │  │     → exit 2                    │     │
    │  └─────────────────────────────────┘     │
    └──────────────────────────────────────────┘

    Claude tries: Write("scripts/cleanup.py") containing DELETE FROM
         │
         ▼
    ┌─── PreToolUse ───────────────────────────┐
    │  matcher: Write|Edit                      │
    │                                           │
    │  Hook: DB content scanner                 │
    │  ┌─────────────────────────────────┐     │
    │  │ File is .py/.sql/.sh/.js/.ts?  │     │
    │  │ NO  → skip                      │     │
    │  │ YES → scan content for:         │     │
    │  │   DELETE FROM, UPDATE...SET,    │     │
    │  │   TRUNCATE, DROP TABLE,         │     │
    │  │   .delete(), .truncate(),       │     │
    │  │   execute(delete/update/drop)   │     │
    │  │                                 │     │
    │  │ Pattern found?                  │     │
    │  │ YES → "DB SAFETY: contains      │     │
    │  │        DELETE FROM. Confirm      │     │
    │  │        with user."              │     │
    │  │     → exit 2                    │     │
    │  └─────────────────────────────────┘     │
    └──────────────────────────────────────────┘

    Claude tries: Edit("src/api/middleware.py") while /freeze active
         │
         ▼
    ┌─── PreToolUse ───────────────────────────┐
    │  matcher: Write|Edit                      │
    │                                           │
    │  Hook: freeze boundary checker            │
    │  ┌─────────────────────────────────┐     │
    │  │ .claude/.freeze-state exists?   │     │
    │  │ NO  → skip (freeze inactive)    │     │
    │  │ YES → read frozen directory     │     │
    │  │                                 │     │
    │  │ File inside frozen dir?         │     │
    │  │ YES → allow (exit 0)            │     │
    │  │ NO  → "BLOCKED: Edit outside    │     │
    │  │        frozen directory"         │     │
    │  │     → exit 2                    │     │
    │  └─────────────────────────────────┘     │
    │                                           │
    │  Activation: /freeze src/auth/            │
    │  Deactivation: /unfreeze or session end   │
    └──────────────────────────────────────────┘
```

---

## 10. Memory & Resource Lifecycle

```
    FastAPI Application Start
         │
         ▼
    ┌─── Lifespan: startup ────────────────────┐
    │                                           │
    │  app.state.http_client = AsyncClient()    │
    │  app.state.db_engine = create_async_eng() │
    │  app.state.redis = Redis()                │
    │  app.state.vector_db = VectorStore()      │
    │                                           │
    │  All resources tracked on app.state       │
    └──────────────────────────────────────────┘
         │
         ▼
    ┌─── Application Running ──────────────────┐
    │                                           │
    │  Requests come in → handlers use          │
    │  app.state.* resources via Depends()      │
    │                                           │
    │  ┌─────────────────────────────────┐     │
    │  │  Periodic health checks:        │     │
    │  │  - DB connection alive?         │     │
    │  │  - Redis pingable?              │     │
    │  │  - LLM API reachable?           │     │
    │  └─────────────────────────────────┘     │
    │                                           │
    │  ┌─────────────────────────────────┐     │
    │  │  After batch operations:        │     │
    │  │  gc.collect()                   │     │
    │  │  (free accumulated memory from  │     │
    │  │   large embedding batches,      │     │
    │  │   parsed documents, etc.)       │     │
    │  └─────────────────────────────────┘     │
    └──────────────────────────────────────────┘
         │
         ▼
    ┌─── Lifespan: shutdown ───────────────────┐
    │                                           │
    │  await app.state.http_client.aclose()  ◄──── CRITICAL
    │  await app.state.db_engine.dispose()   ◄──── No leaked connections
    │  await app.state.redis.close()         ◄──── No zombie processes
    │  app.state.vector_db.close()           ◄──── No file descriptor leaks
    │  gc.collect()                           ◄──── Final cleanup
    │                                           │
    └──────────────────────────────────────────┘

    Claude Code Session End
         │
         ▼
    ┌─── SessionEnd Hook ──────────────────────┐
    │                                           │
    │  Kill orphaned dev processes:             │
    │  - pgrep uvicorn → SIGTERM               │
    │  - pgrep celery → SIGTERM                │
    │  - pgrep streamlit → SIGTERM             │
    │  - pgrep gradio → SIGTERM                │
    │                                           │
    │  No zombie processes left on your machine │
    └──────────────────────────────────────────┘
```

---

## Quick Reference: File → Responsibility Map

```
    src/
    ├── api/
    │   ├── main.py          → FastAPI app, lifespan, middleware
    │   ├── routes/          → Endpoint handlers (thin: validate → call service → respond)
    │   └── deps.py          → Depends() providers (DB session, HTTP client, auth)
    │
    ├── chains/              → LangChain/LangGraph chains
    │   └── rag_chat.py      → RAG chat chain (retrieve → build context → LLM → respond)
    │
    ├── agents/              → PydanticAI agent definitions
    │   └── analyzer.py      → Document analysis agent
    │
    ├── rag/                 → Retrieval pipeline
    │   ├── chunker.py       → Document → chunks (configurable size/overlap)
    │   ├── embedder.py      → Chunks → embeddings (batched, async)
    │   ├── retriever.py     → Query → relevant chunks (vector search + rerank)
    │   └── indexer.py       → Documents → vector DB (bulk indexing)
    │
    ├── models/              → Pydantic schemas
    │   ├── schemas.py       → API request/response models
    │   ├── db_models.py     → SQLAlchemy ORM models
    │   └── llm_schemas.py   → Structured output models for LLM responses
    │
    ├── services/            → Business logic (NO framework deps)
    │   ├── chat_service.py  → Chat orchestration
    │   ├── llm_logger.py    → LLM call logging (structlog + JSON files)
    │   └── cost_tracker.py  → Token cost tracking per model
    │
    ├── db/                  → Database
    │   ├── base.py          → Engine, session factory
    │   ├── repositories/    → CRUD operations per model
    │   └── migrations/      → Alembic migrations (PROTECTED by hook)
    │
    ├── workers/             → Background tasks
    │   └── app.py           → Celery app + tasks
    │
    ├── config/              → Configuration
    │   └── settings.py      → Pydantic Settings (.env loading)
    │
    └── logging/             → Logging setup
        └── setup.py         → loguru (console) + structlog (JSON) dual setup

    prompts/                 → Prompt templates (NEVER inline in Python)
    tests/                   → Mirrors src/. Mocked LLM calls only.
    ui/                      → Single-page test interfaces
    docker/                  → Dockerfile + docker-compose.yml
    logs/                    → Runtime logs (gitignored)
    configs/experiments/     → Experiment configs for git worktrees
    docs/                    → architecture.md + context.md + workflow.md
```
