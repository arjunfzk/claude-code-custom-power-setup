---
paths:
  - "src/chains/**/*.py"
  - "src/agents/**/*.py"
  - "src/graphs/**/*.py"
---

# Agentic AI Architecture Rules

When building AI agents (LangGraph state graphs, PydanticAI agents, LangChain chains):

## Core Patterns — Pick the Right One

**ROUTER**: Input → classifier decides which specialist handles it
```python
# LangGraph: conditional edges from a classifier node
def route(state: State) -> str:
    """Classify intent and route to specialist."""
    # Returns the name of the next node
    if state.intent == "search": return "search_agent"
    if state.intent == "code": return "code_agent"
    return "general_agent"

graph.add_conditional_edges("classifier", route)
```
Use when: multiple distinct task types with different handling.

**ORCHESTRATOR-WORKER**: Planner breaks task into subtasks → workers execute → results merged
```python
# LangGraph: planner node → fan-out to workers → merge node
def planner(state: State) -> State:
    """Break task into subtasks."""
    state.subtasks = plan_subtasks(state.query)
    return state

def worker(state: State) -> State:
    """Execute a single subtask."""
    state.results.append(execute(state.current_subtask))
    return state
```
Use when: complex tasks that decompose into independent subtasks.

**THINKING LOOP (ReAct)**: Think → Act → Observe → loop until done
```python
# The agent decides when it has enough information
def should_continue(state: State) -> str:
    """Agent decides: search more or finalize answer."""
    if state.confidence >= 0.8 or state.search_count >= 5:
        return "synthesize"  # enough info, produce answer
    return "search"  # need more info, search again

graph.add_conditional_edges("evaluate", should_continue)
```
Use when: information gathering tasks where completeness varies.

**GUARDRAILS**: Input validation → agent work → output validation
```python
# ALWAYS add guardrails around untrusted input/output
async def input_guardrail(state: State) -> State:
    """Validate and sanitize input before agent processes it."""
    state.query = sanitize_prompt_injection(state.query)
    state.query = enforce_length_limit(state.query, max_tokens=2000)
    return state

async def output_guardrail(state: State) -> State:
    """Validate output before returning to user."""
    state.response = check_grounding(state.response, state.context)  # hallucination check
    state.response = redact_pii(state.response)
    return state
```
Use on: EVERY agent that takes user input. Non-negotiable.

**EVALUATOR-OPTIMIZER**: Generate → evaluate → improve → loop
```python
# Agent generates, evaluator scores, loop until quality threshold
def evaluate(state: State) -> str:
    score = evaluate_quality(state.draft)
    state.eval_score = score
    if score >= 0.8 or state.revision_count >= 3:
        return "finalize"
    return "revise"  # try again with feedback
```
Use when: quality matters more than speed (code gen, writing, analysis).

## State Management Rules

- ALWAYS use Pydantic models for LangGraph state (not dicts)
- State fields: `messages`, `context`, `tool_results`, `metadata`, `error`
- Include `iteration_count` to prevent infinite loops (max 10 iterations)
- Include `confidence` score when agent needs to decide if it's done
- Log state transitions: `logger.info("state_transition", from_node=X, to_node=Y)`

## Error Handling in Agents

- Every tool call: try/except with retry + fallback
- Agent-level: max iterations as hard stop (never infinite loop)
- Graceful degradation: if search fails, use cached/existing context
- ALWAYS log errors with full context: which node, which tool, what input, what error
- Human escalation: if confidence < 0.5 after max retries, ask the user

## Agent Evaluation (How to Know If Your Agent Is Good)

- **Trajectory evaluation**: did the agent take the right steps in the right order?
- **Grounding score**: is the output based on retrieved context or hallucinated?
- **Tool selection accuracy**: did it use the right tool for each step?
- **Latency budget**: total wall-clock time (set a budget per agent)
- **Cost tracking**: tokens used across all LLM calls in the agent run
- Log ALL of these to `logs/agent_runs/` for analysis

## Anti-Patterns

- NEVER let an agent loop without a max iteration count
- NEVER skip input guardrails ("it's just internal" → prompt injection via RAG chunks)
- NEVER fire-and-forget agent tasks → use TaskGroup with error handling
- NEVER hardcode model in agent → pass as config for easy A/B testing
- NEVER ignore tool errors → agent must handle and adapt, not crash
