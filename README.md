# Claude Code Power Setup — Python / LLM Engineer Template

> **One install. Every project gets auto-formatting, auto-testing, secret scanning, 22 slash commands, 12 specialist AI agents, and live documentation — without changing a single line of your code.**

A battle-tested Claude Code configuration layer for Python LLM engineers. This is not a starter scaffold — it sits on top of any Python/FastAPI/LangChain project and makes Claude Code dramatically more capable.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     YOUR EXISTING PROJECT                           │
│  src/  tests/  prompts/  docker/  ...                               │
├─────────────────────────────────────────────────────────────────────┤
│                 CLAUDE CODE POWER SETUP (this repo)                 │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │  13 Hooks │  │ 22 Skills│  │12 Agents │  │  2 MCP Servers   │   │
│  │          │  │          │  │          │  │                  │   │
│  │ Auto-fmt │  │ /review  │  │ security │  │ context7 (docs)  │   │
│  │ Auto-test│  │ /deploy  │  │ rag-debug│  │ seq-thinking     │   │
│  │ Block    │  │ /research│  │ llm-arch │  │                  │   │
│  │ secrets  │  │ /brainstm│  │ test-writ│  │                  │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬─────────┘   │
│       │              │              │                  │             │
│  Enforced        On-demand     Auto-dispatched    Always-on        │
│  automatically   via /command  by Claude           tool access      │
├─────────────────────────────────────────────────────────────────────┤
│  CLAUDE.md  │  settings.json  │  .mcp.json  │  rules/  │  .ignore  │
│  (instructions)  (permissions)   (servers)    (context)   (skip)    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Table of Contents

- [Why This Exists](#why-this-exists)
- [Quick Start](#quick-start)
- [What's Included](#whats-included)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Daily Workflow](#daily-workflow)
- [Skills (Slash Commands)](#skills-slash-commands)
- [Subagents](#subagents)
- [Hook System](#hook-system)
- [MCP Servers](#mcp-servers)
- [Context Rules](#context-rules)
- [Superpowers Plugin](#superpowers-plugin)
- [What Goes Where — Decision Guide](#what-goes-where--decision-guide)
- [Global CLAUDE.md](#global-claudemd)
- [Brainstorm Panel Usage](#brainstorm-panel-usage)
- [File Structure](#file-structure)
- [What NOT to Do](#what-not-to-do)
- [Customization](#customization)
- [Contributing](#contributing)
- [License](#license)

---

## Why This Exists

Claude Code out of the box is powerful but undisciplined. It forgets to format, skips tests, occasionally writes secrets into commits, and approaches complex problems by jumping straight to code. You can tell it not to — but instructions in CLAUDE.md are suggestions, and suggestions get forgotten under pressure.

This setup fixes that by working at three levels:

```
Level 1: ENFORCEMENT (Hooks)
  Claude writes a file → ruff auto-formats it
  Claude commits code  → secrets scanner blocks if it finds keys
  Claude is on main    → write is blocked, told to create a branch
  You can't forget. Claude can't forget. It's automatic.

Level 2: CAPABILITY (Skills + Agents)
  /review         → LLM-specific code review (not generic)
  /debug-llm      → parses your actual LLM call logs
  /full-review    → 9 specialist agents review in parallel
  /brainstorm     → researches before coding, not after
  These give Claude abilities it doesn't have by default.

Level 3: KNOWLEDGE (MCP + Rules + CLAUDE.md)
  context7        → live library docs (not stale training data)
  rules/          → domain knowledge loaded only when relevant
  CLAUDE.md       → your stack, your commands, your standards
  Claude knows your project, not just Python in general.
```

The result: Claude Code that formats every file, tests every change, blocks every secret, reviews like a specialist, and researches before it builds.

---

## Quick Start

```bash
# Clone and install globally (works in every project)
git clone https://github.com/arjunfzk/claude-code-custom-power-setup.git
cd claude-code-custom-power-setup
./install.sh

# Restart Claude Code, then install the Superpowers plugin
/install-github superpowers-ai/superpowers

# Copy MCP config into your project (one-time per project)
cp .mcp.json /path/to/your-project/
```

Done. Open any project with Claude Code — hooks are active, skills are available, agents are ready.

---

## What's Included

| Component | Location | What it does |
|-----------|----------|--------------|
| Project CLAUDE.md | `CLAUDE.md` | Project instructions for Claude — stack, commands, LLM rules |
| Project settings | `.claude/settings.json` | Allow/deny rules + 7 hook event handlers |
| MCP servers | `.mcp.json` | context7 (live docs) + sequential-thinking (structured reasoning) |
| Slash commands | `.claude/skills/` | 22 custom `/commands` |
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
git clone https://github.com/arjunfzk/claude-code-custom-power-setup.git
cd claude-code-custom-power-setup
./install.sh
```

What `install.sh` does:
- Copies all skills → `~/.claude/skills/` (available as `/command` in any project)
- Copies all agents → `~/.claude/agents/` (available as subagents in any project)
- Copies all context rules → `~/.claude/rules/`
- Merges hooks into `~/.claude/settings.json` (non-destructive — backs up your existing file first)
- Creates `~/.claude/CLAUDE.md` with a starter global rules template if you don't have one yet

Dry-run first to see what would change:

```bash
./install.sh --dry-run
```

After installing, **restart Claude Code**. Then run this once inside any Claude Code session to install the Superpowers plugin:

```
/install-github superpowers-ai/superpowers
```

See [Superpowers Plugin](#superpowers-plugin) below for what this adds.

### Option B — Per-project copy

If you only want this config in one specific project:

```bash
git clone https://github.com/arjunfzk/claude-code-custom-power-setup.git

cp -r claude-code-custom-power-setup/.claude      your-project/
cp    claude-code-custom-power-setup/.mcp.json    your-project/
cp    claude-code-custom-power-setup/.claudeignore your-project/
cp    claude-code-custom-power-setup/CLAUDE.md    your-project/
```

Or click **"Use this template"** at the top of this page to start a new repo from it.

### After Option A: customize your global CLAUDE.md

The installer creates `~/.claude/CLAUDE.md` with starter rules if you don't have one yet. Edit it to match your personal preferences:

```bash
open ~/.claude/CLAUDE.md   # macOS
# or: code ~/.claude/CLAUDE.md
```

### After Option B: customize the project CLAUDE.md

Open `CLAUDE.md` in your project and replace the placeholders:

- `[PROJECT_NAME]` → your project name
- `[ChromaDB / Pinecone / Qdrant / pgvector]` → your vector DB choice
- Update the `## Commands` section with your actual dev commands

Keep CLAUDE.md under 200 lines. It's loaded on every message — shorter = better adherence.

### MCP servers (per-project, both options)

The MCP config lives in `.mcp.json` — it's **project-level only** and must be copied into each project separately. The global install does not do this automatically.

```bash
# For each project you want MCP in:
cp /path/to/claude-code-custom-power-setup/.mcp.json your-project/
```

Then start a Claude Code session in that project. You should see both servers connect:

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

## Daily Workflow

This is what using the setup actually looks like day-to-day:

```
┌─────────────────────────────────────────────────────────────┐
│                    MORNING                                   │
│                                                             │
│  $ claude                                                   │
│  ⚠ docs/context.md is 5 days old — run /update-context     │
│                                                             │
│  > /update-context           # refresh project docs         │
├─────────────────────────────────────────────────────────────┤
│                    WHILE CODING                              │
│                                                             │
│  > "add retry logic to the embedding service"               │
│    ├─ Claude writes src/services/embeddings.py              │
│    ├─ [hook] ruff auto-formats ✓                            │
│    ├─ [hook] tests/test_embeddings.py runs ✓                │
│    └─ Claude sees test results, continues                   │
│                                                             │
│  > /search-first             # before writing new code      │
│  > /brainstorm               # before architectural choices │
├─────────────────────────────────────────────────────────────┤
│                    BEFORE COMMITTING                         │
│                                                             │
│  > /review                   # LLM-specific code review     │
│  > git commit                                               │
│    ├─ [hook] scans for hardcoded secrets ✓                  │
│    ├─ [hook] tests migration reversibility ✓                │
│    └─ commit succeeds                                       │
├─────────────────────────────────────────────────────────────┤
│                    WHEN STUCK                                │
│                                                             │
│  > /debug-llm                # parse LLM call logs          │
│  > /deep-research            # multi-round web research     │
│  > /cost-aware-pipeline      # audit for token waste        │
├─────────────────────────────────────────────────────────────┤
│                    EXPERIMENTS                                │
│                                                             │
│  > /new-experiment           # isolated git worktree        │
│  > /compare-experiments      # side-by-side results         │
│  > /cleanup-experiments      # remove stale worktrees       │
└─────────────────────────────────────────────────────────────┘
```

---

## Skills (Slash Commands)

### What skills are

A skill is a markdown file that gives Claude a reusable, named procedure. When you type `/review`, Claude loads `.claude/skills/review/SKILL.md` and follows the instructions exactly — tools to call, steps to take, output format, gates to check.

**The problem they solve:** Without skills, you'd repeat the same long prompt every time ("check for missing LLM logging, check for unclosed async clients, check for..."). With skills, you type two words and get a consistent, reproducible result.

**Where they live:**

```
~/.claude/skills/          ← global (available in every project after ./install.sh)
your-project/.claude/skills/   ← project-local (only in this repo)
```

**How Claude invokes them:** When you type `/review`, Claude searches the skills directories for a folder named `review`, loads `SKILL.md`, and executes it as if you'd pasted the full contents into the chat. Some skills auto-invoke — they specify in their frontmatter that Claude should invoke them proactively under certain conditions (e.g. the `brainstorm` skill tells Claude to invoke it before any creative work).

**How to add your own:**

```bash
mkdir -p .claude/skills/my-command
cat > .claude/skills/my-command/SKILL.md << 'EOF'
---
name: my-command
description: What this command does (shown in /help)
---

# Steps
1. Do this
2. Then this
3. Output a table
EOF
```

It's now available as `/my-command` in any Claude Code session in that project.

### The 22 included skills

```
Skills by Category
==================

DEVELOPMENT WORKFLOW          CODE REVIEW & QUALITY
├── /new-project              ├── /review
├── /brainstorm               ├── /full-review
├── /brainstorm-panel         ├── /second-opinion
├── /search-first             └── /deploy-check
└── /update-context

LLM ENGINEERING               EXPERIMENTS
├── /debug-llm                ├── /new-experiment
├── /cost-aware-pipeline      ├── /compare-experiments
└── /design-agent             ├── /cleanup-experiments
                              ├── /freeze
RESEARCH & PLANNING           └── /unfreeze
├── /deep-research
├── /inspiration
├── /self-learn
├── /autoloop
└── /offload
```

#### Development Workflow

| Command | Problem it solves |
|---------|------------------|
| `/new-project` | Starting a new LLM app from scratch takes hours — directory layout, Docker, logging config, pyproject.toml, test structure. This scaffolds the entire thing with one command. |
| `/brainstorm` | Claude tends to jump to the first solution. This forces multi-round research with web lookups and prior-art checks before committing to an approach. |
| `/brainstorm-panel` | A single model has blind spots. This runs Claude, Codex, and Gemini in parallel using a Moderator-State protocol — independent proposals, structured critique, and synthesis. 5 quality tiers (`quick` to `max`) control model selection and reasoning effort across all three CLIs. See [brainstorm-panel usage](#brainstorm-panel-usage) below. |
| `/search-first` | Claude often writes new code for something that already exists in the codebase. This searches first, surfacing reusable patterns before writing anything. |
| `/update-context` | `docs/context.md` and `docs/architecture.md` go stale after significant changes. This reads the current codebase and rewrites both docs in one shot. |

#### Code Review & Quality

| Command | Problem it solves |
|---------|------------------|
| `/review` | Generic code review misses LLM-specific issues (missing token counting, no cost tracking, inline prompts, unclosed async clients). This review is tuned specifically for LLM engineering. |
| `/full-review` | A single reviewer has blind spots. This spawns 9 parallel specialist subagents (tests, security, performance, quality, dependencies, simplicity, docs, logging, architecture) and aggregates their findings. |
| `/second-opinion` | Claude reviewing its own code has confirmation bias. This sends your diff to Codex CLI (a completely different model) for an independent review. When two models flag the same issue, confidence is high. |
| `/deploy-check` | Pre-deploy checklists get skipped under pressure. This automates the entire checklist: tests, lint, Docker build, health check endpoint, zombie process scan, memory usage. |

#### LLM Engineering

| Command | Problem it solves |
|---------|------------------|
| `/debug-llm` | LLM bugs are subtle — high latency, silent cost spikes, quality regressions. This parses `logs/llm/*.json` (every call is logged) and surfaces failures, slow calls, expensive calls, and quality patterns. |
| `/cost-aware-pipeline` | LLM pipelines get expensive fast. This audits your chain architecture for unnecessary calls, wrong model choices, missing caching, and token waste. |
| `/design-agent` | Building an agent without an explicit state graph leads to spaghetti orchestration. This designs the full architecture first: state graph, pattern choice, guardrails, Mermaid diagram. |

#### Experiments

| Command | Problem it solves |
|---------|------------------|
| `/new-experiment` | Testing a risky change in your main working tree means if it breaks, your whole env breaks. This creates a fully isolated git worktree with its own `uv` environment and log directories. |
| `/compare-experiments` | After running multiple experiments you have results scattered across branches. This pulls metrics and outputs side-by-side into a comparison table. |
| `/cleanup-experiments` | Stale worktrees accumulate disk usage silently. This lists all experiment branches with age and size, and offers to remove the ones you're done with. |
| `/freeze [path]` | When you only want Claude to touch one subdirectory (e.g. `src/services/`) this blocks any Write/Edit outside that path for the session. |
| `/unfreeze` | Removes the freeze set by `/freeze`. |

#### Research & Planning

| Command | Problem it solves |
|---------|------------------|
| `/deep-research` | Web searches return shallow results. This runs a thinking loop — searches, evaluates what's missing, searches again — until the research is comprehensive. |
| `/inspiration` | Before building something, you want to know how others solved it — without cargo-culting everything they did. Give it a GitHub repo URL and it produces a structured Keep / Adapt / Discard analysis: fetches repo metadata first (bails early on duds), checks Issues/PRs for what maintainers regret, and anchors recommendations to your actual project context. Works in plan mode too. |
| `/self-learn` | Debugging breakthroughs and workarounds discovered in a session get lost. This extracts them into persistent memory so they're available in future sessions. |
| `/autoloop [interval] [command]` | Polling a deploy or watching test results requires you to keep typing. This runs any command on a recurring interval (e.g. `/autoloop 5m /deploy-check`). |
| `/offload` | Long background tasks (scraping, batch processing, analysis) block the conversation. This delegates to a subagent and lets you continue working while it runs. |

---

## Subagents

### What subagents are

A subagent is a separate Claude instance with a specific identity, focused context, and set of tools. When Claude dispatches a subagent, it spawns a fresh model call with only the information relevant to that specialization — no noise from the main conversation.

**The problem they solve:** Claude in a general conversation tries to be good at everything, which means it's mediocre at specialized tasks. A security reviewer who only reviews security catches things a generalist misses. A RAG debugger who has seen hundreds of retrieval failures has better pattern recognition than a general assistant asked to "debug my RAG pipeline."

**Skills vs Subagents:**

| Skills (`/command`) | Subagents (`agent-name`) |
|---------------------|--------------------------|
| You invoke explicitly | Claude invokes automatically or on request |
| Stay in the current conversation context | Run in isolated context — separate model call |
| For procedures you want to follow step-by-step | For specialized work that benefits from focused expertise |
| `/review` — you trigger it when you want a review | `code-reviewer` — Claude dispatches it when doing a `/full-review` |

**How to invoke them explicitly:**
> "Use the security-reviewer to audit my authentication middleware"
> "Have the rag-debugger analyze why my similarity scores are all near 0.5"

**Where they live:**

```
~/.claude/agents/              ← global (available in every project after ./install.sh)
your-project/.claude/agents/   ← project-local (only in this repo)
```

**How to add your own:**

Create a markdown file in `.claude/agents/`:

```bash
cat > .claude/agents/my-specialist.md << 'EOF'
---
name: my-specialist
description: When to invoke this agent (Claude reads this to decide)
tools: Read, Bash, Grep
---

You are an expert in X. When called, always...
EOF
```

The `description` field is critical — Claude uses it to decide when to automatically dispatch this agent.

### The 12 included agents

```
Agent Specializations
=====================

ARCHITECTURE                    CODE QUALITY
├── llm-architect               ├── code-reviewer
│   model selection, serving,   │   LLM-specific: logging,
│   caching, multi-model        │   resources, security, types
│   routing                     │
└── architect                   ├── security-reviewer
    LangGraph state graphs,     │   prompt injection, auth,
    agent patterns,             │   secrets, API key exposure
    guardrails                  │
                                └── performance-reviewer
OPERATIONS                          N+1, async blocking,
├── docker-deployer                 memory leaks, hot paths
│   images, compose, health
│   checks, resources           ANALYSIS
│                               ├── llm-reviewer
├── log-cleaner                 │   cost, latency, quality
│   zombies, old logs,          │   from logs/llm/*.json
│   memory, disk                │
│                               ├── rag-debugger
└── prompt-optimizer            │   chunks, scores, embeddings
    token efficiency,           │   from logs/rag/
    clarity, effectiveness      │
                                ├── test-writer
                                │   pytest + mocked LLM fixtures
                                │
                                └── agent-evaluator
                                    trajectory, guardrails,
                                    loop termination
```

| Agent | What it is | Problem it solves |
|-------|-----------|------------------|
| `llm-architect` | Expert in model selection, serving infrastructure, caching, multi-model routing | Choosing the wrong model tier or serving approach is expensive to fix later. This agent evaluates your requirements and recommends the right architecture before you build. |
| `architect` | LangGraph expert — state graphs, agent patterns, guardrails, Mermaid diagrams | LangGraph has specific patterns for human-in-the-loop, interrupts, and checkpointing. This agent knows them and designs the graph correctly from the start. |
| `code-reviewer` | Python LLM code reviewer — logging, resource cleanup, security, types, docstrings | Catches LLM-specific issues: missing `logs/llm/` writes, unclosed async clients, temperature not set, no token counting, `Any` types, missing docstrings. |
| `security-reviewer` | Focused on prompt injection, auth bypass, secrets in code, API key exposure | Security issues in LLM apps are different from traditional apps — prompt injection, context leakage, jailbreaks. A generalist reviewer often misses them. |
| `performance-reviewer` | N+1 queries, blocking ops in async, memory leaks, expensive hot paths | async code that accidentally blocks the event loop is hard to spot in review. This agent knows the patterns: `time.sleep` in async, non-async DB calls, missing `await`. |
| `llm-reviewer` | Reads `logs/llm/*.json` and audits for quality, cost, latency, hallucination patterns | You can't improve what you don't measure. This agent reads the actual call logs and tells you which prompts are expensive, which have high retry rates, which responses look like hallucinations. |
| `rag-debugger` | RAG retrieval specialist — chunk relevance, similarity scores, embedding issues | Bad RAG retrieval (wrong chunk size, wrong embedding model, poor similarity threshold) is hard to diagnose from symptoms alone. This agent reads the `logs/rag/` output and traces the root cause. |
| `test-writer` | Writes pytest tests that mock all LLM API calls using recorded fixtures | LLM tests that call real APIs are slow, expensive, and flaky. This agent writes tests that replay recorded responses from `tests/fixtures/llm_responses/`. |
| `docker-deployer` | Docker image builder, compose validator, health checker, resource auditor | Docker issues that appear fine locally fail in production due to missing dependencies, wrong users, no health checks, or memory limits. This agent validates before you ship. |
| `prompt-optimizer` | Analyzes prompt templates for token efficiency, clarity, and LLM effectiveness | Prompts accumulate cruft. This agent reads your `prompts/` directory and finds: redundant instructions, ambiguous phrasing, token waste, missing output format specs. |
| `agent-evaluator` | Tests agentic AI behavior — trajectory analysis, guardrail verification, loop termination | Agents that work in testing can fail in production with subtle issues: infinite loops, guardrail bypass, incorrect tool call sequences. This agent stress-tests the behavior. |
| `log-cleaner` | Kills zombie processes, cleans old logs, reports memory/disk usage, finds resource leaks | Long-running LLM sessions accumulate zombie processes (orphaned uvicorn, celery workers) and large log files. This agent cleans house without touching your code. |

---

## Hook System

### What hooks are

Hooks are shell commands that Claude Code runs automatically at specific points in its lifecycle. They are defined in `settings.json` and execute without you doing anything — Claude writes a file, the hook fires, done.

**The problem they solve:** Claude is a language model. It will try its best to follow your CLAUDE.md rules, but under pressure it can forget to run `ruff`, miss that you're on `main`, or write a migration file directly. Hooks enforce rules at the tool level — before or after the action — so compliance isn't optional and doesn't depend on Claude remembering.

### How hooks work

```
                    HOOK LIFECYCLE
                    ==============

  PreToolUse                              PostToolUse
  (runs BEFORE tool)                      (runs AFTER tool)
       │                                       │
       ▼                                       ▼
  ┌─────────┐    exit 0    ┌──────────┐   ┌─────────┐
  │  Check   │────────────▶│  Tool    │──▶│  React  │
  │  & Gate  │             │ Executes │   │  & Fix  │
  └─────────┘              └──────────┘   └─────────┘
       │                                       │
       │ exit 2                                │
       ▼                                       ▼
  ┌─────────┐                            ┌─────────┐
  │ BLOCKED │                            │ Format, │
  │ + error │                            │ test,   │
  │ message │                            │ notify  │
  └─────────┘                            └─────────┘
```

- **PreToolUse** — runs before Claude uses a tool. Exit code 2 **blocks** the action entirely.
- **PostToolUse** — runs after Claude uses a tool. Used for side effects like formatting or running tests.
- **Other events:** `SessionStart`, `SessionEnd`, `Stop`, `PreCompact`, `PostCompact`

**Hook anatomy in `settings.json`:**

```json
"PostToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [
      {
        "type": "command",
        "command": "..."
      }
    ]
  }
]
```

The hook receives the tool call's input as JSON on `stdin`. For a `Write` call, that's the file path and content. For a `Bash` call, that's the command string. Your script reads this JSON, decides what to do, and exits 0 (allow), 2 (block), or any other code (allow with warning).

**Where hooks live:** In `settings.json` under the `hooks` key. Global hooks go in `~/.claude/settings.json` and apply everywhere. Project hooks go in `.claude/settings.json` and apply only in that repo. The installer merges the project hooks into your global file non-destructively.

### The 13 hooks included

```
Hook Coverage Map
=================

SESSION LIFECYCLE          FILE WRITES (PostToolUse)     FILE WRITES (PreToolUse)
├── SessionStart           ├── Auto-format Python        ├── Block writes on main
│   stale docs warning     ├── Auto-test on src/ save    ├── Block dangerous SQL
├── SessionEnd             └── Auto-sync pyproject.toml  └── Block migration edits
│   kill dev servers
├── Stop                   BASH COMMANDS (PreToolUse)    COMPACTION
│   macOS notification     ├── Block pip install         ├── PreCompact: save state
└──────────────────────    └── Block secrets on commit   └── PostCompact: restore
                               + test migration
                                 reversibility
```

#### Auto-format on every Python save (PostToolUse → Write/Edit)

**What it does:** Runs `ruff check --fix` and `ruff format` after Claude writes any `.py` file.

**Problem it solves:** Claude sometimes produces code that's syntactically valid but not formatted — inconsistent quotes, unused imports, wrong line spacing. Without this hook you'd need to remember to format manually, and a code review would have style noise mixed with real issues. With this hook, every file Claude touches is always formatted.

#### Auto-test on `src/` save (PostToolUse → Write/Edit)

**What it does:** When Claude writes a file in `src/`, it finds the matching test file in `tests/` and runs it (30-second timeout).

**Problem it solves:** Bugs introduced by Claude are often caught by existing tests — but only if you remember to run them. This hook runs the relevant tests immediately after each edit. If the test fails, Claude sees the output in the same turn and can fix the code before moving on.

#### Auto-sync on `pyproject.toml` save (PostToolUse → Write/Edit)

**What it does:** Runs `uv sync` after Claude modifies `pyproject.toml`.

**Problem it solves:** Claude might add a dependency to `pyproject.toml` but then try to import it before it's installed. This ensures the environment is always in sync with the manifest — imports work immediately after the file is saved.

#### Block writes on `main` branch (PreToolUse → Write/Edit)

**What it does:** Checks the current branch before any file write. If the branch is `main`, it blocks the write and tells Claude to create a feature branch.

**Problem it solves:** It's easy to be in the middle of a session and accidentally be on `main`. One file write and your main branch has unreviewed changes. This hook makes it physically impossible — the tool call is rejected before the file is touched.

#### Block `pip install` (PreToolUse → Bash)

**What it does:** Intercepts any `bash` command that starts with `pip install` and blocks it.

**Problem it solves:** `pip install` bypasses `uv`'s lock file, installs into the wrong environment, and breaks reproducibility. Claude knows to use `uv add` but sometimes falls back to `pip` from training patterns. This hook catches it every time.

#### Block dangerous SQL (PreToolUse → Write/Edit)

**What it does:** Scans file content before writing for `DELETE FROM`, `UPDATE ... SET`, `TRUNCATE`, `DROP TABLE`, `DROP DATABASE`, `.delete()`, `.truncate()`. Blocks and requires confirmation.

**Problem it solves:** A single destructive SQL statement in the wrong context can wipe a database. This hook fires before the file is even written — you have to explicitly approve before Claude can save code containing destructive operations.

#### Block direct migration file edits (PreToolUse → Write/Edit)

**What it does:** Blocks any write to a path containing `/migrations/` or `/alembic/versions/`.

**Problem it solves:** Editing existing migration files is one of the most dangerous things you can do with a database — it silently diverges your migration history from what's deployed. New migrations must be generated by Alembic. This hook makes direct editing impossible.

#### Block hardcoded secrets on commit (PreToolUse → Bash)

**What it does:** When `git commit` runs, scans all staged Python files for patterns matching API keys, passwords, Bearer tokens (`sk-...`, `api_key = "..."`, `OPENAI_API_KEY = "..."`).

**Problem it solves:** Secrets committed to git are a security incident. Even if you delete them in the next commit, they're in history. This hook catches them before `git commit` completes — the commit is blocked until the secret is replaced with an env var reference.

#### Migration reversibility test on commit (PreToolUse → Bash)

**What it does:** When `git commit` runs with a migration file staged, it runs: `alembic upgrade head` → `alembic downgrade -1` → `alembic upgrade head`.

**Problem it solves:** Irreversible migrations are a production disaster. If you ever need to roll back a deploy, a migration that can't downgrade leaves your database in an inconsistent state. This hook verifies the full up/down/up cycle before the migration is committed.

#### Stale docs warning at session start (SessionStart)

**What it does:** When a Claude Code session opens, checks the modification time of `docs/context.md` and `docs/architecture.md`. If either is older than 3 days, shows a warning.

**Problem it solves:** Claude relies on `docs/context.md` for current project state. If you forgot to run `/update-context` after significant changes, Claude will be working from stale information. This surfaces the problem at the start of each session before any code is written.

#### Context preservation across compaction (PreCompact / PostCompact)

**What it does:** Before context compaction, saves current branch name, last 5 commits, modified files, and a snippet of `docs/context.md` to `.claude/pre-compact-state.json`. After compaction, reads that file and injects the context back into Claude's conversation.

**Problem it solves:** When Claude Code compacts the conversation to free context space, Claude loses everything it knew about the current state — what branch you're on, what you were just working on, what changed. This hook saves that critical state before compaction and restores it immediately after, so the session continues smoothly.

#### Notification when Claude finishes (Stop)

**What it does:** When Claude finishes generating a response, fires a macOS notification with the "Glass" sound. Falls back to `notify-send` on Linux.

**Problem it solves:** Long tasks (full reviews, experiment runs, research) can take minutes. Instead of polling the terminal, you can switch to another window and get notified when Claude is done.

#### Kill dev servers on session end (SessionEnd)

**What it does:** When the Claude Code session closes, sends `SIGTERM` to any `uvicorn`, `celery`, `streamlit`, or `gradio` processes that were started in the current project directory.

**Problem it solves:** Dev servers started during a Claude session often keep running after the session ends, consuming ports and memory. This hook cleans them up automatically — no orphan processes, no "port already in use" error next time.

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

## Superpowers Plugin

[Superpowers](https://github.com/superpowers-ai/superpowers) is a community plugin that adds **workflow discipline skills** — structured approaches for brainstorming, debugging, test-driven development, code review, and plan execution. Where the custom skills in this template give Claude *what to do* (review code, research a topic, deploy), Superpowers gives Claude *how to approach work* (brainstorm before building, write tests before code, verify before claiming done).

### What it adds

| Skill | What it enforces |
|-------|-----------------|
| `brainstorming` | Explores intent, requirements, and design *before* jumping to code. Auto-invoked before any creative work. |
| `systematic-debugging` | Scientific method for bugs: observe, hypothesize, test, conclude. Prevents shotgun debugging. |
| `test-driven-development` | Write failing test first, then implementation, then refactor. Prevents "I'll add tests later." |
| `writing-plans` | Structured implementation plans before touching code. For multi-step tasks. |
| `executing-plans` | Execute plans with review checkpoints. Prevents drift from the plan. |
| `verification-before-completion` | Run verification commands and confirm output *before* claiming work is done. Evidence before assertions. |
| `requesting-code-review` | Structured review process when completing features. |
| `subagent-driven-development` | Parallelize independent implementation tasks using subagents. |
| `using-git-worktrees` | Isolated feature branches with safety verification. |

### How it interacts with the custom skills

Superpowers and the custom skills in this template serve different layers:

```
User says: "Build a caching layer for my RAG pipeline"

  ┌─────────────────────────────────────────────────────────────┐
  │  SUPERPOWERS (how to work)                                  │
  │                                                             │
  │  brainstorming ──▶ explores intent, requirements            │
  │       │                                                     │
  │  writing-plans ──▶ step-by-step implementation plan         │
  │       │                                                     │
  │  verification  ──▶ confirms tests pass before done          │
  └───────┼─────────────────────────────────────────────────────┘
          │
  ┌───────▼─────────────────────────────────────────────────────┐
  │  CUSTOM SKILLS (what to do)                                 │
  │                                                             │
  │  /design-agent  ──▶ architecture (state graph)              │
  │  /search-first  ──▶ find existing patterns                  │
  │  /review        ──▶ LLM-specific code review                │
  └───────┼─────────────────────────────────────────────────────┘
          │
  ┌───────▼─────────────────────────────────────────────────────┐
  │  HOOKS (enforcement)                                        │
  │                                                             │
  │  auto-format ✓  auto-test ✓  block secrets ✓               │
  └─────────────────────────────────────────────────────────────┘
```

Superpowers skills auto-invoke based on context — you don't need to call them explicitly. The custom `/skills` are explicit commands you invoke when you need them.

### Installing Superpowers

Run once inside any Claude Code session:

```
/install-github superpowers-ai/superpowers
```

---

## What Goes Where — Decision Guide

Claude Code has several extension points. Use this guide to decide where new behavior belongs:

```
"I want Claude to..."
  │
  ├─ "...always do X on every file write/commit/session"
  │   → Hook (settings.json)
  │   Examples: auto-format, block secrets, run tests
  │
  ├─ "...follow a multi-step procedure when I ask"
  │   → Skill (.claude/skills/name/SKILL.md)
  │   Examples: /review, /deploy-check, /new-experiment
  │
  ├─ "...use a specialist identity for focused work"
  │   → Agent (.claude/agents/name.md)
  │   Examples: security-reviewer, rag-debugger, test-writer
  │
  ├─ "...know domain rules when working in a certain area"
  │   → Rule (.claude/rules/topic.md)
  │   Examples: LLM call patterns, RAG pipeline conventions
  │
  ├─ "...look up live external data (docs, APIs, databases)"
  │   → MCP Server (.mcp.json)
  │   Examples: context7 for library docs, sequential-thinking
  │
  ├─ "...follow project-wide instructions every message"
  │   → CLAUDE.md
  │   Examples: stack choices, coding standards, forbidden patterns
  │
  └─ "...never be allowed to do X, regardless of instructions"
      → Permission deny rule (settings.json permissions.deny)
      Examples: block rm -rf, block .env reads, block force push
```

### Quick comparison

| Mechanism | Trigger | Scope | Token cost | Use when... |
|-----------|---------|-------|------------|-------------|
| **Hook** | Automatic (tool use, session events) | Every matching action | Zero (runs outside context) | Enforcement that can't depend on Claude remembering |
| **Skill** | Explicit (`/command`) | On-demand | Loaded when invoked | Reusable multi-step procedures |
| **Agent** | Claude dispatches or you request | Isolated context | Separate model call | Specialist work benefiting from focused expertise |
| **Rule** | Auto-loaded by relevance | When Claude detects context match | Loaded conditionally | Domain knowledge for specific areas of the codebase |
| **MCP Server** | Claude calls as a tool | Per-project | Tool call only | Live external data Claude can't get from local files |
| **CLAUDE.md** | Always loaded | Every message | Always in context | Project-wide instructions that apply everywhere |
| **Permission deny** | Blocks before execution | Every matching tool call | Zero | Hard safety limits that nothing should override |

### Common mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Putting formatting rules in CLAUDE.md | Claude might forget; costs tokens every message | Use a PostToolUse hook — enforced, zero context cost |
| Making an agent for a procedure | Agents are specialists, not checklists | Use a skill for step-by-step procedures |
| Putting rarely-used rules in CLAUDE.md | Wastes context on every message | Move to `.claude/rules/` for conditional loading |
| Using a skill for something that must always happen | Users forget to invoke skills | Use a hook for mandatory behavior |
| Hardcoding library docs in rules | Docs go stale | Use an MCP server for live documentation |
| Using a hook for complex multi-step workflows | Hooks are one-shot checks, not conversations | Use a skill that Claude can follow interactively |

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
User message                  ← strongest (always wins)
  ↓
Project CLAUDE.md             ← specific beats general
  ↓
Global CLAUDE.md              ← your universal preferences
  ↓
Claude's defaults             ← weakest
```

If your global file says "use uv" but a project file says "use poetry", Claude uses poetry for that project.

---

## Brainstorm Panel Usage

`/brainstorm-panel` orchestrates a multi-model brainstorm between Claude, Codex, and Gemini.

```
/brainstorm-panel <topic> [--quality <tier>] [--rounds 2|3] [--focus "angle"] [--context "extra"] [--constraints "c1; c2"] [--out path/report.md] [--keep-artifacts]
```

**Parameters:**

| Flag | Default | What it does |
|------|---------|-------------|
| `<topic>` | *(required)* | The brainstorm question |
| `--quality` | `standard` | Model/effort tier — see table below |
| `--rounds` | `2` | Number of deliberation rounds (`2` or `3`) |
| `--focus` | none | Narrow the brainstorm angle |
| `--context` | none | Extra context for all models |
| `--constraints` | none | Hard constraints (semicolon-separated) |
| `--out` | inline | Save report to a file path |
| `--keep-artifacts` | off | Print the temp directory path to inspect intermediate JSON |

**Quality tiers:**

| Tier | Claude | Codex | Gemini | Protocol |
|------|--------|-------|--------|----------|
| `quick` | Sonnet / low | o4-mini / minimal | Gemini 3 Flash | 2 rounds |
| `standard` | Sonnet / medium | GPT-5.4 / low | Gemini 3 Flash | 2 rounds |
| `high` | Sonnet / high | GPT-5.4 / medium | Gemini 3.1 Pro | 2 rounds |
| `pro` | Opus / max | GPT-5.4 / high | Gemini 3.1 Pro | 2 rounds |
| `max` | Opus / max | GPT-5.4 / xhigh | Gemini 3.1 Pro | 3 rounds |

**Examples:**

```bash
# Simple brainstorm
/brainstorm-panel best architecture for a RAG pipeline with 10M documents

# With focus and constraints
/brainstorm-panel API design for multi-tenant SaaS --focus "auth and isolation" --constraints "must use FastAPI; no microservices"

# High quality, save output
/brainstorm-panel career pivot strategy --quality pro --out docs/career-brainstorm.md

# Maximum quality, 3 rounds, keep intermediate files
/brainstorm-panel migrate from PostgreSQL to CockroachDB --quality max --keep-artifacts --context "current DB is 500GB, 50k QPS"
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
│   ├── skills/                  # 22 slash commands
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

## Contributing

Contributions welcome. If you have a hook, skill, or agent that's useful for Python/LLM engineering:

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/my-skill`)
3. Follow the existing patterns in `.claude/skills/` or `.claude/agents/`
4. Test it in a real Claude Code session
5. Open a PR with a description of what problem it solves

---

## License

MIT

---

## Related

- [Official Claude Code docs](https://docs.anthropic.com/en/docs/claude-code)
- [Superpowers plugin](https://github.com/superpowers-ai/superpowers) — workflow discipline: brainstorming, TDD, debugging, code review, plan execution
- [context7 MCP](https://github.com/upstash/context7) — live library documentation
- [sequential-thinking MCP](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking) — structured reasoning
