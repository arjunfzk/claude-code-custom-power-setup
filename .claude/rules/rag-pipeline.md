---
paths:
  - "src/rag/**/*.py"
---

# RAG Pipeline Rules

Chunk config in Pydantic model:
```python
class ChunkConfig(BaseModel):
    chunk_size: int = 512
    chunk_overlap: int = 50
    separator: str = "\n\n"
```

Embeddings MUST be batched:
```python
# WRONG
for doc in documents:
    embedding = await embed(doc)
# RIGHT
embeddings = await embed_batch(documents, batch_size=100)
```

Every retrieval call MUST log to `logs/rag/{timestamp}_{query_hash}.json`:
- Query text, number of chunks, top-k similarity scores, time taken

Count tokens BEFORE sending context to LLM:
```python
from tiktoken import encoding_for_model
enc = encoding_for_model(model_name)
total = sum(len(enc.encode(c.text)) for c in chunks)
if total > max_context_tokens:
    chunks = truncate_to_fit(chunks, max_context_tokens)
```

Vector search: always return similarity scores. Flag anything below 0.7.
