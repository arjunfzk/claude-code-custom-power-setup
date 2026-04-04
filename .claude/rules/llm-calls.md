---
paths:
  - "src/chains/**/*.py"
  - "src/agents/**/*.py"
  - "src/services/**/llm*.py"
  - "src/services/**/ai*.py"
---

# LLM Call Rules

Every function that calls an LLM API MUST:

1. Accept `model` and `temperature` as parameters from config
2. Set explicit `max_tokens` limit
3. Wrap in try/except: TimeoutError, RateLimitError, AuthenticationError, ContextLengthExceeded
4. Retry with exponential backoff: `tenacity.retry(wait=wait_exponential(min=1, max=60), stop=stop_after_attempt(3))`
5. Log via structlog:
```python
import structlog, time
logger = structlog.get_logger()

start = time.monotonic()
# ... LLM call ...
latency_ms = round((time.monotonic() - start) * 1000)
logger.info("llm_call", model=model, prompt_tokens=usage.prompt_tokens,
            completion_tokens=usage.completion_tokens, latency_ms=latency_ms,
            cost_usd=calculate_cost(model, usage), status="success", chain=chain_name)
```
6. Save full request/response JSON to `logs/llm/{timestamp}_{model}_{chain}_{status}.json`

LangChain: use `BaseCallbackHandler` with `on_llm_start` / `on_llm_end`.
PydanticAI: use `result.usage()` and `result.all_messages()`.
Direct OpenAI/Anthropic: wrap with logging decorator.

Prompt templates: load from `prompts/` directory. NEVER inline prompt strings in Python code.
