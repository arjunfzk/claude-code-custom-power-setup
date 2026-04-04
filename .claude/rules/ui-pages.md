---
paths:
  - "ui/**/*.py"
  - "ui/**/*.html"
---

# UI Rules (Single-Page Test Interfaces)

These UIs test and demo API endpoints. Keep minimal. No build steps.

ALWAYS include:
- Debug panel showing full raw LLM response JSON
- Token count + latency display
- "Copy as cURL" button for each request
- Single file per UI — no bundlers, no node_modules

Three templates available:
- `ui/streamlit_*.py` — Streamlit (fastest for chat UIs)
- `ui/gradio_*.py` — Gradio (best for ML demos with inputs/outputs)
- `ui/*.html` — HTML+HTMX+Tailwind (zero deps, served by FastAPI)

Streamlit: `uv run streamlit run ui/app.py`
Gradio: `uv run python ui/gradio_app.py`
HTML: served automatically at `/ui/` by FastAPI static files mount
