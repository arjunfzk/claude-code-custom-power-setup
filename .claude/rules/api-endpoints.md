---
paths:
  - "src/api/**/*.py"
  - "tests/test_api/**/*.py"
---

# FastAPI Rules

Every endpoint: Pydantic v2 request/response models. No raw dicts.

Streaming LLM responses via SSE with backpressure:
```python
@router.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    async def generate():
        try:
            async for chunk in chain.astream(request.message):
                if await request.is_disconnected():
                    break  # CRITICAL: stop generating when client disconnects
                yield f"data: {json.dumps({'content': chunk})}\n\n"
            yield "data: [DONE]\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"
    return StreamingResponse(generate(), media_type="text/event-stream")
```

Background tasks for expensive LLM operations: use `BackgroundTasks` with job_id + polling endpoint.

Lifespan handler (CRITICAL — prevents zombie connections):
```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient(timeout=30)
    app.state.db_engine = create_async_engine(DATABASE_URL, pool_size=20)
    yield
    await app.state.http_client.aclose()
    await app.state.db_engine.dispose()
    gc.collect()
```

Health endpoint: check DB, Redis, LLM provider connectivity. Return individual check status.
OpenAPI docs: summary + description + response_model on every endpoint.
