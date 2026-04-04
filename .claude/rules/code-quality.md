---
paths:
  - "src/**/*.py"
  - "tests/**/*.py"
  - "scripts/**/*.py"
---

# Code Quality Rules

## Docstrings (MANDATORY)

Every .py file starts with:
```python
"""
Module purpose: Brief description of what this module does.

Author: [name]
Created: [date]
Dependencies: List key external dependencies this module uses.
"""
```

Every function has Google-style docstring:
```python
def process_query(query: str, top_k: int = 5) -> list[RetrievedChunk]:
    """Retrieve and rank relevant chunks for the given query.

    Embeds the query, searches the vector DB, applies reranking,
    and returns the top-k most relevant chunks with scores.

    Args:
        query: The user's natural language query.
        top_k: Number of chunks to return. Defaults to 5.

    Returns:
        List of RetrievedChunk objects sorted by relevance score descending.

    Raises:
        EmbeddingError: If the embedding API call fails.
        VectorDBError: If the vector database is unreachable.

    Example:
        >>> chunks = await process_query("How does attention work?", top_k=3)
        >>> assert len(chunks) <= 3
        >>> assert all(c.score >= 0 for c in chunks)
    """
```

## Inline Comments

Add comments for:
- Non-obvious business logic ("# Rerank because initial vector search optimizes for recall, not precision")
- Magic numbers ("# 512 tokens = optimal chunk size for our embedding model (tested in exp-chunking)")
- Workarounds ("# Using sync client here because httpx async has a connection leak in this context")
- Performance choices ("# Batch size 100 balances throughput vs memory — tested in exp-batch-size")

Do NOT comment obvious code ("# increment counter" before `counter += 1`).

## Resource Management

Every file that opens connections MUST use context managers or lifespan cleanup.
No bare `open()` without `with`. No `httpx.AsyncClient()` without `aclose()`.
