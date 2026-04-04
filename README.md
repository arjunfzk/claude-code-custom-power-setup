# Claude Code Power Setup — Python / LLM Engineer Template

A battle-tested Claude Code configuration for Python LLM engineers. Includes hooks that auto-format, auto-test, and block dangerous commands; a full permission system; MCP servers for live docs and structured reasoning; 20+ slash commands; and 12 specialized subagents.

This is not a starter scaffold — it's a **Claude Code configuration layer** that sits on top of any Python/FastAPI/LangChain project.

---

## What's Included

| Component | Location | What it does |
|-----------|----------|--------------|
| Project CLAUDE.md | `CLAUDE.md` | Project instructions for Claude — stack, commands, LLM rules |
| Project settings | `.claude/settings.json` | Allow/deny rules + 7 hook event handlers |
| MCP servers | `.mcp.json` | context7 (live docs) + sequential-thinking (structured reasoning) |
| Slash commands | `.claude/skills/` | 20 custom `/commands` |
| Subagents | `.claude/agents/` | 12 specialized AI subagents |
| Context rules | `.claude/rules/` | Domain-specific rules loaded on demand |
| Ignore list | `.claudeignore` | Tells Claude to skip logs, weights, caches |
| Doc templates | `docs/` | `architecture.md` + `context.md` kept current by Claude |

---

## Prerequisites

**Required:**

| Tool | Version | Install |
|------|---------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Latest | `npm install -g @anthropic-ai/claude-code` |
| Node.js | 20+ | `brew install node` or [nodejs.org](https://nodejs.org) |
| Python | 3.11+ | `brew install python@3.11` |
| [uv](https://docs.astral.sh/uv/) | Latest | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |

**Optional (needed for specific commands):**

| Tool | Install | Required by |
|------|---------|-------------|
| [Codex CLI](https://github.com/openai/codex) | `npm i -g @openai/codex` | `/second-opinion`, `/offload` |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | `npm i -g @google/gemini-cli` | `/second-opinion` (fallback) |
| Docker | [docs.docker.com](https://docs.docker.com/get-docker/) | `/deploy-check`, `docker compose *` |

---

## Setup

### Option A — Global install (recommended)

Installs skills, agents, hooks, and rules into `~/.claude/` so they work in **every project**, not just this one.

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-power-setup.git
cd claude-code-power-setup
./install.sh
```

What `install.sh` does:
- Copies all 20 skills → `~/.claude/skills/` (available as `/command` in any project)
- Copies all 12 agents → `~/.claude/agents/` (available as subagents in any project)
- Copies all 9 context rules → `~/.claude/rules/`
- Merges hooks into `~/.claude/settings.json` (non-destructive — backs up your existing file first)
- Creates `~/.claude/CLAUDE.md` with a starter global rules template if you don't have one yet

Dry-run first to see what would change:

```bash
./install.sh --dry-run
```

After installing, **restart Claude Code**. Then run these once inside any Claude Code session to install community plugins:

```
/install-github superpowers-ai/superpowers
/install-github superpowers-ai/gsd
```

### Option B — Per-project copy

If you only want this config in one specific project:

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-power-setup.git

cp -r claude-code-power-setup/.claude      your-project/
cp    claude-code-power-setup/.mcp.json    your-project/
cp    claude-code-power-setup/.claudeignore your-project/
cp    claude-code-power-setup/CLAUDE.md    your-project/
```

Or click **"Use this template"** at the top of this page to start a new repo from it.

### After either option: customize CLAUDE.md

Open `CLAUDE.md` (or `~/.claude/CLAUDE.md` for global) and replace the placeholders:

- `[PROJECT_NAME]` → your project name
- `[ChromaDB / Pinecone / Qdrant / pgvector]` → your vector DB choice
- Update the `## Commands` section with your actual dev commands

Keep CLAUDE.md under 200 lines. It's loaded on every message — shorter = better adherence.

### Verify MCP servers

Start a Claude Code session. You should see both MCP servers connect:

```
✓ context7
✓ sequential-thinking
```

If they show "failed", the package names are the common culprit. Verify `.mcp.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

> **Note:** If you have project-level entries in `~/.claude.json` (under `projects[path].mcpServers`), those override `.mcp.json`. Check both locations if servers fail to connect.

---

## Slash Commands

Run any of these inside a Claude Code session.

### Development Workflow

| Command | What it does |
|---------|-------------|
| `/new-project` | Scaffold a new LLM application with full structure, Docker, logging, tests |
| `/brainstorm` | Multi-round brainstorming with web research and prior-art lookup |
| `/search-first` | Search codebase for existing patterns before writing new code |
| `/update-context` | Update `docs/context.md` and `docs/architecture.md` with current state |

### Code Review & Quality

| Command | What it does |
|---------|-------------|
| `/review` | LLM-engineering-focused code review: logging, resources, security, types |
| `/full-review` | 9-agent parallel review: tests, security, performance, quality, dependencies |
| `/second-opinion` | Sends your diff to Codex CLI for an independent cross-model review |
| `/deploy-check` | Pre-deployment checklist: tests, lint, Docker build, health check, zombies |

### LLM Engineering

| Command | What it does |
|---------|-------------|
| `/debug-llm` | Analyze `logs/llm/` for failures, slow calls, cost spikes, quality issues |
| `/cost-aware-pipeline` | Audit or design an LLM pipeline for cost efficiency |
| `/design-agent` | Design an AI agent architecture with state graph and guardrails |

### Experiments

| Command | What it does |
|---------|-------------|
| `/new-experiment` | Create isolated experiment: git worktree + own `uv` env + own logs |
| `/compare-experiments` | Side-by-side comparison of experiment results and metrics |
| `/cleanup-experiments` | List all worktree experiments with age/disk usage, offer to remove stale ones |
| `/freeze [path]` | Lock Claude to only edit files under a specific directory |
| `/unfreeze` | Remove the freeze restriction |

### Research & Planning

| Command | What it does |
|---------|-------------|
| `/deep-research` | Multi-round research with thinking loop — searches until comprehensive |
| `/self-learn` | Extract reusable knowledge from current session into memory |
| `/autoloop [interval] [command]` | Run a command on a recurring interval (e.g. `/autoloop 5m /review`) |
| `/offload` | Delegate a task to a background subagent while you continue working |

---

## Subagents

These specialized AI agents are invoked automatically by Claude when needed, or you can reference them explicitly.

| Agent | Specialty |
|-------|-----------|
| `llm-architect` | Model selection, serving infrastructure, caching, multi-model routing |
| `architect` | LangGraph state graphs, agent patterns, guardrails, Mermaid diagrams |
| `code-reviewer` | Python LLM code: logging, resources, security, types, docstrings |
| `security-reviewer` | Prompt injection, auth bypass, secrets in code, API key exposure |
| `performance-reviewer` | N+1 queries, blocking ops in async, memory leaks, expensive hot paths |
| `llm-reviewer` | Review LLM call logs for hallucination, cost, latency, prompt quality |
| `rag-debugger` | RAG retrieval quality: chunk relevance, scores, embedding issues |
| `test-writer` | Write pytest tests: mocks all API calls, uses recorded fixtures |
| `docker-deployer` | Build Docker images, validate compose files, run health checks |
| `prompt-optimizer` | Analyze prompt templates for token efficiency, clarity, effectiveness |
| `agent-evaluator` | Test and evaluate agentic AI behavior: trajectory, guardrails, loops |
| `log-cleaner` | Kill zombie processes, clean old logs, find resource leaks |

---

## MCP Servers

Both servers are auto-started when you open a Claude Code session in this project.

### context7

Live documentation for any library. Claude uses this to look up current API syntax instead of relying on potentially stale training data.

**When Claude uses it automatically:** Any time it needs to call a library function and the API might have changed (LangChain, FastAPI, Pydantic v2, SQLAlchemy 2.0, etc.)

**You can trigger it explicitly:**
> "How do I use `selectinload` in SQLAlchemy 2.0?" → Claude fetches the live docs

### sequential-thinking

Structured multi-step reasoning. Breaks complex problems into sequential steps with explicit intermediate conclusions.

**When Claude uses it automatically:** Complex architecture decisions, multi-step debugging, planning tasks with dependencies.

**You can trigger it explicitly:**
> "Use sequential thinking to evaluate our current architecture and find bottlenecks"

---

## Hook System

Hooks run automatically — you don't need to think about them.

### What runs automatically

| Trigger | Hook | Effect |
|---------|------|--------|
| Every Python file save | PostToolUse | `ruff check --fix` + `ruff format` |
| Python file save in `src/` | PostToolUse | Runs matching test in `tests/` (timeout: 30s) |
| `pyproject.toml` save | PostToolUse | `uv sync` |
| Any Write/Edit on `main` branch | PreToolUse | **Blocks** — forces feature branch |
| Any `pip install` command | PreToolUse | **Blocks** — redirects to `uv add` |
| DELETE/UPDATE SQL without WHERE | PreToolUse | **Blocks** — requires user confirmation |
| Writing to `migrations/` | PreToolUse | **Blocks** — must use `alembic revision` |
| File content contains hardcoded secrets | PreToolUse | **Blocks** — detects API keys, passwords |
| `git commit` with migrations staged | PreToolUse | Runs upgrade → downgrade → upgrade test |
| Session start | SessionStart | Warns if `docs/context.md` > 3 days old |
| Context compaction | PreCompact/PostCompact | Saves/restores branch + recent commits + context |
| Claude finishes responding | Stop | macOS notification with sound |
| Session end | SessionEnd | Kills dev servers (uvicorn, celery, streamlit) |

---

## Context Rules

Rules in `.claude/rules/` are loaded automatically when relevant context is detected (e.g. if you're working on API endpoints, `api-endpoints.md` is loaded).

| Rule file | Applies when |
|-----------|-------------|
| `llm-calls.md` | Working with LLM API calls |
| `rag-pipeline.md` | Building RAG systems |
| `api-endpoints.md` | Writing FastAPI routes |
| `agentic-patterns.md` | Building agents or workflows |
| `docker-deploy.md` | Working with Docker/compose |
| `experiments.md` | Running isolated experiments |
| `code-quality.md` | General code review context |
| `agent-testing.md` | Writing tests for agents |
| `ui-pages.md` | Building Streamlit/Gradio UIs |

---

## Daily Workflow

```
Morning:
  claude               # Start session — hooks warn if docs are stale
  /update-context      # Refresh docs/context.md if needed

While coding:
  (write code)         # ruff auto-formats, tests auto-run on save
  /search-first        # Before writing anything, check if it exists

Before committing:
  /review              # LLM-engineering code review
  git commit           # Hooks scan for secrets, test migrations

When stuck:
  /debug-llm           # If LLM calls are failing/slow/expensive
  /deep-research       # For complex architectural questions

Experiments:
  /new-experiment      # Isolated worktree for risky changes
  /compare-experiments # Compare results when done
  /cleanup-experiments # Clean up stale worktrees
```

---

## File Structure

```
your-project/
├── CLAUDE.md                    # Project instructions for Claude
├── .mcp.json                    # MCP server config (context7, sequential-thinking)
├── .claudeignore                # Files Claude should skip (logs, weights, caches)
├── .claude/
│   ├── settings.json            # Allow/deny rules + hooks
│   ├── agents/                  # 12 specialized subagents
│   ├── skills/                  # 20 slash commands
│   └── rules/                   # Domain-specific context rules
├── src/                         # FastAPI application code
├── tests/                       # pytest tests (mock all LLM calls)
├── prompts/                     # Prompt templates (.txt/.jinja2 — never inline)
├── logs/
│   ├── llm/                     # Every LLM call logged as JSON
│   └── rag/                     # RAG chunk + score logs
├── docs/
│   ├── architecture.md          # Updated by /update-context
│   └── context.md               # Current state, active work, decisions
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
└── experiments/                 # git worktrees for isolated experiments
```

---

## Global CLAUDE.md

This is separate from the project `CLAUDE.md`. It lives at `~/.claude/CLAUDE.md` and applies to **every project you open** — all terminals, all repos, all sessions.

### The two-level system

```
~/.claude/CLAUDE.md          ← your universal preferences (applies everywhere)
your-project/CLAUDE.md       ← project-specific rules (overrides global where they conflict)
```

When Claude opens a session, it reads both. If there's a conflict, the project file wins.

### What belongs in global CLAUDE.md

Put things that are true about **you**, not about a specific project:

- Your preferred language/framework versions and tooling choices
- Universal safety rules (never hardcode secrets, never force-push main)
- Code style preferences (function length, comment style, type annotations)
- Commit conventions
- Tools you never want used (e.g. `pip`, `poetry`, deprecated frameworks)

Do **not** put project-specific commands, stack choices, or anything that only applies to one repo.

### Creating your global CLAUDE.md

```bash
# Create the file
touch ~/.claude/CLAUDE.md

# Open it
open ~/.claude/CLAUDE.md   # macOS
# or: code ~/.claude/CLAUDE.md
```

### Starter template

Copy this and edit to match your stack:

```markdown
# Global Rules

These rules apply to ALL projects. Project CLAUDE.md overrides where conflicts exist.

## Universal Rules

- Every file must have a top-level docstring/comment explaining its purpose.
- Add doc comments on non-obvious functions. Skip trivial getters/setters.
- Inline comments: explain WHY, not WHAT.
- Use the type system fully. No `Any` (Python), no `any` (TS) without justification.
- Prefer small, single-purpose functions (~40 lines Python, ~60 lines TS).
- CRITICAL: NEVER hardcode API keys, secrets, tokens. Use environment variables.
- CRITICAL: NEVER force push to main. NEVER commit .env, API keys, secrets, logs/.
- Conventional commits: feat:, fix:, refactor:, test:, docs:, chore:
- Every project should have docs/architecture.md and docs/context.md. Keep them current.

## Python (Primary Stack)

- Python 3.11+. Use `uv` (NEVER pip, NEVER poetry).
- Format/lint: `ruff` (NEVER black, NEVER flake8, NEVER isort).
- Async by default for API endpoints and LLM calls.
- CRITICAL: Log EVERY LLM call: model, tokens, latency_ms, cost_usd, status.
- CRITICAL: Save full LLM request/response to logs/llm/ as JSON.
- CRITICAL: Prompt templates in prompts/ directory. NEVER inline in Python code.
- ALL LLM calls: timeout, retry with exponential backoff, max_tokens, cost tracking.
- Testing: pytest + pytest-asyncio. NEVER call real LLM APIs in tests.
- CRITICAL: NEVER DELETE or UPDATE database rows without showing count first.
- CRITICAL: NEVER modify existing migration files. Create new migrations only.
- Close ALL async clients in FastAPI lifespan handler. No fire-and-forget tasks.

## Git

- Experiments via git worktrees: git worktree add ../exp-name -b exp/name
- Run /update-context after significant changes.
```

### Keeping it under 200 lines

Global CLAUDE.md is loaded on every message in every project. Shorter = better adherence and lower token cost. If you have many rules, split them:

```bash
# Put overflow rules in separate files
~/.claude/CLAUDE.md           # under 200 lines, imports the rest
~/.claude/rules/python.md     # Python-specific rules
~/.claude/rules/security.md   # Security rules
```

Reference them in your global CLAUDE.md with `@import` syntax:

```markdown
@~/.claude/rules/python.md
@~/.claude/rules/security.md
```

### Priority hierarchy

```
User message
  ↓
Project CLAUDE.md     (strongest — specific beats general)
  ↓
Global CLAUDE.md      (your universal preferences)
  ↓
Claude's defaults     (weakest)
```

If your global file says "use uv" but a project file says "use poetry", Claude uses poetry for that project.

---

## What NOT to Do

| Don't | Why | Do instead |
|-------|-----|------------|
| Use `.claudeignore` for secret protection | Claude can still read files despite entries | Use `permissions.deny` in `settings.json` |
| Use `claude config` | Deprecated | Edit `settings.json` directly |
| Add new configs to `.claude/commands/` | Merged into skills system; lacks features | Use `.claude/skills/<name>/SKILL.md` |
| Write 500-line CLAUDE.md | Reduces adherence, wastes context | Keep under 200 lines, use `@import` for overflow |
| Use `bypassPermissions` broadly | Skips all safety prompts | Use `acceptEdits` or targeted `allow` rules |
| `pip install` anything | Breaks reproducibility | `uv add <package>` |
| Hardcode API keys | Security risk | `pydantic-settings` + `.env` |
| Inline prompt strings in Python | Hard to iterate, version, test | `prompts/` directory as `.txt` or `.jinja2` |

---

## Customization

**Add a new slash command:** Create `.claude/skills/my-command/SKILL.md` with your instructions. It becomes `/my-command`.

**Add a new subagent:** Create `.claude/agents/my-agent.md` describing the agent's specialty and tools. Claude will use it when relevant.

**Add a permission rule:** Edit `.claude/settings.json`. Glob patterns in `deny` block tool calls; patterns in `allow` pre-approve them without user prompts.

**Add a context rule:** Create `.claude/rules/my-topic.md`. Include a brief description at the top so Claude knows when to load it.

---

## Related

- [Official Claude Code docs](https://docs.anthropic.com/en/docs/claude-code)
- [GSD (Get Shit Done) plugin](https://github.com/superpowers-ai/gsd) — project planning + execution workflows
- [Superpowers plugin](https://github.com/superpowers-ai/superpowers) — systematic debugging, TDD, code review workflows
- [context7 MCP](https://github.com/upstash/context7) — live library documentation
- [sequential-thinking MCP](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking) — structured reasoning
