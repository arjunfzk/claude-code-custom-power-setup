---
name: brainstorm-panel
description: Use when the user wants a multi-model brainstorm — runs Claude, Codex, and Gemini in a Moderator-State protocol with parallel proposals, structured critique, and synthesis. Supports 5 quality tiers from quick to max.
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
---

# Multi-Model Brainstorm Panel

Orchestrate a brainstorm across Claude (M1), Codex (M2), and Gemini (M3) using a Moderator-State protocol. Models propose independently, a moderator compacts the state, models critique the state, then Claude synthesizes.

## Non-Negotiables

- Use neutral IDs `M1`, `M2`, `M3` — never brand names in prompts, state, or reports.
- Default mapping: M1=Claude, M2=Codex CLI, M3=Gemini CLI.
- Round 1 is independent. Freeze M1 before reading any external output.
- Round 2 symmetry: every model gets the same moderator state, same task packet, only its own Round 1.
- M1 Round 2 is a **fresh isolated `claude -p` call** (not inline) — same information as M2/M3.
- Required field in every output: `what_the_moderator_state_might_be_missing`.
- Never read `.claude/`, `~/.claude/`, or `.agents/` in external CLI prompts.

## Invocation

```
/brainstorm-panel <topic> [--quality <tier>] [--rounds 2|3] [--focus "angle"] [--context "extra"] [--constraints "c1; c2"] [--out path/report.md]
```

Defaults: `--quality standard`, `--rounds 2`.

---

## Quality Tiers

| Tier | Claude | Codex | Gemini | Protocol |
|------|--------|-------|--------|----------|
| `quick` | `--model sonnet --effort low` | `-m o4-mini -c model_reasoning_effort=minimal` | `-m gemini-3-flash-preview` | 2 rounds, `--fast` |
| `standard` | `--model sonnet --effort medium` | `-m gpt-5.4 -c model_reasoning_effort=low` | `-m gemini-3-flash-preview` | 2 rounds, `--strict` |
| `high` | `--model sonnet --effort high` | `-m gpt-5.4 -c model_reasoning_effort=medium` | `-m gemini-3.1-pro-preview` | 2 rounds, `--strict` |
| `pro` | `--model opus --effort max` | `-m gpt-5.4 -c model_reasoning_effort=high` | `-m gemini-3.1-pro-preview` | 2 rounds, `--strict` |
| `max` | `--model opus --effort max` | `-m gpt-5.4 -c model_reasoning_effort=xhigh` | `-m gemini-3.1-pro-preview` | 3 rounds, `--strict` |

- `--fast`: M1 Round 2 critique runs inline (cheap, slight bias).
- `--strict`: M1 Round 2 critique runs as fresh isolated `claude -p` call (symmetric, costs one extra API call).
- `max` tier: Round 3 is a **convergence round** with distinct job (see Step 6).
- Gemini has no reasoning effort flag — compensated by model swap (flash vs pro) and tier-specific prompt wrappers:
  - `quick`: "Be concise. Fewer options. Skip exhaustive analysis."
  - `standard`/`high`: no modifier.
  - `pro`/`max`: "Explore alternatives, edge cases, tensions, and deep tradeoffs."
- If preview Gemini models fail, fall back to stable: `gemini-2.5-flash` / `gemini-2.5-pro`.

### Token Targets

| Step | quick/standard/high/pro | max |
|------|------------------------|-----|
| Round 1 per model | 800-1000 | 1200 |
| Moderator state | 600-800 | 1000 |
| Round 2 critique per model | 600-800 | 1000 |
| Round 2 input packet | 1500-2200 | 2200-3000 |

---

## Step 0: Detect CLIs

```bash
CODEX_BIN="${CODEX_BIN:-codex}"
GEMINI_BIN="${GEMINI_BIN:-gemini}"
HAVE_M2=0; HAVE_M3=0
command -v "$CODEX_BIN" >/dev/null 2>&1 && HAVE_M2=1 || true
command -v "$GEMINI_BIN" >/dev/null 2>&1 && HAVE_M3=1 || true
```

- M1+M2+M3: full protocol.
- M1+one external: two-model degraded mode.
- M1 only: single-model mode (fresh `claude -p` for critique).
- Never abort because a CLI is missing.

## Step 1: Build Task Packet

Construct `task_packet.txt`:

```text
TASK
{user's topic}

FOCUS
{focus or "none"}

CONTEXT
{extra context or "none"}

CONSTRAINTS
{constraints or "none"}

PROTOCOL
- Use neutral model IDs M1/M2/M3 only.
- Preserve dissent; do not collapse disagreements into consensus.
- Required field: what_the_moderator_state_might_be_missing.
- Evaluate only the supplied packet. Do not assume any prior discussion, hidden rationale, or extra context.
```

## Step 2: M1 Round 1 (Inline)

Claude generates its Round 1 proposal as JSON conforming to `schemas/round1.schema.json`. **Freeze this output before any external call.**

### Round 1 Prompt Template (all models)

```text
You are {MODEL_ID} in Round 1 of a multi-model brainstorming protocol.

Rules:
- Work independently. Do not simulate or predict peer outputs.
- Return JSON only — no markdown, no prose before/after.
- Use neutral IDs M1/M2/M3 only.
- Target {TOKEN_TARGET} tokens.
- Required field: what_the_moderator_state_might_be_missing.

Your job:
- Restate the problem in your own words.
- Propose your best approach.
- State assumptions, tradeoffs, risks, and open questions.
- Surface what a future moderator summary could easily miss.

Task packet:
{TASK_PACKET}
```

## Step 3: M2 + M3 Round 1 (Parallel)

Fire both in parallel. Use the quality tier's model + effort flags.

### M2 / Codex

```bash
codex exec \
  --output-schema schemas/round1.schema.json \
  -s read-only --ephemeral \
  {QUALITY_FLAGS_M2} \
  "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
  {ROUND1_PROMPT_M2}" \
  -o "$RUN_DIR/round1_m2.json"
```

### M3 / Gemini

```bash
gemini -p "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
  {ROUND1_PROMPT_M3}" \
  {QUALITY_FLAGS_M3} \
  -o text > "$RUN_DIR/round1_m3.raw"
```

**Note:** Gemini `-o json` returns a wrapper object `{response, stats, error}`, not the raw schema object. Use `-o text` and extract JSON from text output:
```bash
jq -Rs 'match("\\{[\\s\\S]*\\}") | .string' "$RUN_DIR/round1_m3.raw" | jq -r '.' | jq -e . > "$RUN_DIR/round1_m3.json"
```

### Parse Repair

If JSON parse fails:
1. Retry once with: "Your previous response was invalid JSON. Return only a single valid JSON object. No markdown."
2. If still invalid, mark model unavailable for later rounds. Note in Protocol Notes.

## Step 4: Moderator Compaction (Inline)

Claude reads all successful Round 1 outputs and produces `moderator_state.json` conforming to `schemas/moderator_state.schema.json`.

### Moderator Rules

- This step is **mechanical, not adjudicative**.
- Preserve model-attributed disagreement.
- Every agreement must list supporting models.
- Every conflict must preserve per-model positions.
- Non-trivial minority views must survive.
- Never convert "two models said X" into "X is true."
- Include `user_goal` and `hard_constraints` so the packet is self-sufficient for Round 2.
- If a model was unavailable, omit it — never fabricate data.
- Keep to token target for the quality tier.

## Step 5: Round 2 Critique (All Parallel)

**All three models get fresh, isolated calls with the same packet.**

### Round 2 Prompt Template (all models)

```text
You are {MODEL_ID} in Round 2 of a multi-model brainstorming protocol.

You are given:
1. The original task packet.
2. A moderator state distilled from all Round 1 outputs.
3. Your own Round 1 output.

Rules:
- Evaluate only the supplied packet. Do not assume any prior discussion, hidden rationale, or extra context.
- Do not assume the moderator state is correct or complete.
- Attack false consensus. Surface summary poisoning or flattening.
- Call out parser skew if the moderator state distorted your view.
- Protect non-trivial minority views from erasure.
- Return JSON only.
- Use neutral IDs M1/M2/M3 only.
- Target {TOKEN_TARGET} tokens.
- Required field: what_the_moderator_state_might_be_missing.

Your job:
- Critique the moderator state.
- State what should survive unchanged.
- State what should be corrected, added, or removed.
- Identify risks and unanswered questions.
- Prefer concrete state edits over vague commentary.

TASK_PACKET
{TASK_PACKET}

MODERATOR_STATE
{MODERATOR_STATE_JSON}

YOUR_ROUND1
{MODEL_OWN_ROUND1_JSON}
```

### M1 / Claude (fresh isolated call)

```bash
claude -p "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
  {ROUND2_PROMPT_M1}" \
  --no-session-persistence \
  {QUALITY_FLAGS_M1} \
  --output-format text \
  > "$RUN_DIR/round2_m1.raw"
```

**Note:** `--output-format json` returns conversation wrapper metadata, not the raw schema object. Use `--output-format text` and extract JSON from the text output:
```bash
jq -Rs 'match("\\{[\\s\\S]*\\}") | .string' "$RUN_DIR/round2_m1.raw" | jq -r '.' | jq -e . > "$RUN_DIR/round2_m1.json"
```

### M2 / Codex

```bash
codex exec \
  --output-schema schemas/round2.schema.json \
  -s read-only --ephemeral \
  {QUALITY_FLAGS_M2} \
  "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
  {ROUND2_PROMPT_M2}" \
  -o "$RUN_DIR/round2_m2.json"
```

### M3 / Gemini

```bash
gemini -p "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
  {ROUND2_PROMPT_M3}" \
  {QUALITY_FLAGS_M3} \
  -o text > "$RUN_DIR/round2_m3.raw"
```

Extract JSON from text (same as Step 3):
```bash
jq -Rs 'match("\\{[\\s\\S]*\\}") | .string' "$RUN_DIR/round2_m3.raw" | jq -r '.' | jq -e . > "$RUN_DIR/round2_m3.json"
```

All three run in parallel. Same parse + repair rules as Step 3.

## Step 6: Round 3 — Convergence (max tier only)

If `--quality max` (or `--rounds 3`):

1. Claude compacts Round 2 critiques into `moderator_state_r2.json` using the same schema.
2. All three models get a Round 3 prompt with a **distinct job**:

```text
You are {MODEL_ID} in Round 3 (final convergence) of a multi-model brainstorming protocol.

Your job is different from Round 2:
- Produce a DISAGREEMENT LEDGER: list every unresolved conflict with each model's final position.
- Produce a FAILURE-MODE SCAN: what could go wrong with the emerging consensus?
- Produce a FINAL RANKED SYNTHESIS: your top 3 recommendations in priority order with confidence.
- Do NOT soften disagreements. If you still disagree, say so clearly.
```

3. Same parallel execution pattern. Uses `schemas/round3.schema.json` (not `round2.schema.json` — Round 3 has different required fields: `disagreement_ledger`, `failure_modes`, `ranked_recommendations`).
4. For Codex: `--output-schema schemas/round3.schema.json`. For Claude/Gemini: same text extraction as Round 2.

## Step 7: Final Synthesis (Inline)

Claude reads all artifacts and writes the final report. This step is **adjudicative** — Claude recommends a direction.

```markdown
# Multi-Model Brainstorm Report

## Recommended Direction
[1-2 paragraphs]

## Best Composite Plan
- Key move 1
- Key move 2
- Key move 3

## Why This Over Alternatives
- Strongest supporting arguments
- Critical tradeoffs accepted
- Major rejected alternative and why

## Dissent Registry
- Mx: [unresolved objection]
- My: [concern that still matters]

## Risks and Open Questions
- Top risk
- Second risk
- Most important unanswered question

## Protocol Notes
- Available models: M1, M2, M3 (or subset)
- Quality tier: [tier]
- Rounds completed: [N]
- Degraded mode: none | two-model | single-model
- Parse repairs used: [yes/no, which model]
- M1=Claude, M2=Codex, M3=Gemini
```

If `--out` was provided, save the report to that path.

---

## Degraded Modes

### Two-Model Mode

- Run with M1 and whichever external CLI is available.
- Moderator state still required.
- Do not use majority language — two models can only agree or disagree.
- Final synthesis must note lower diversity.

### Single-Model Mode

- M1 proposes (inline).
- Moderator state from M1 only.
- M1 critiques via **fresh `claude -p` call** (not inline — prevents self-justification).
- Synthesis must state: "Single-model self-critique. No cross-model disagreement was available."

### Parse Failure

- Retry once with repair prompt.
- If still invalid, drop model from later rounds.
- Never fabricate a placeholder.
- Note failure in Protocol Notes.

---

## Rules and Guards

- Freeze M1 Round 1 before any shell call.
- Same prompt contract for all models in the same round. Schema enforcement is Codex-only (`--output-schema`); Claude and Gemini use prompt-based JSON with validation + retry.
- Do not pass peers' full Round 1 outputs into Round 2.
- Moderator compaction must preserve source attribution.
- Treat compact state as lossy and challengeable, never authoritative.
- Always preserve minority views if they introduce a distinct mechanism, risk, or decision axis.
- Never interpret parser failure as intellectual failure.
- Keep moderator state within token targets so Round 2 input stays in range.
- If user asks for vendor names, reveal the M1/M2/M3 mapping only in Protocol Notes.

---

## Common Mistakes

| Mistake | Why it breaks | Fix |
|---------|--------------|-----|
| M1 sees external outputs before finishing R1 | Destroys independence | Freeze `round1_m1.json` first |
| M1 critiques inline with full context | Asymmetry — M1 has advantage | Use fresh `claude -p` call |
| Passing peers' full R1 into R2 | Herd behavior | Only own R1 + shared state |
| Compressing disagreement into consensus | Summary poisoning | Preserve `conflicts` + `minority_views` |
| Treating "2 of 3 said it" as truth | False consensus | Support counts as evidence, not verdict |
| Dropping parse-failed model silently | Hides protocol defects | Retry once, record drop in notes |
| Using vendor names in prompts/synthesis | Brand anchoring | M1/M2/M3 everywhere |
| Moderator state too long | Bloats R2 input, weakens critique | Keep within token targets |
| Omitting `what_the_moderator_state_might_be_missing` | Removes anti-flattening guard | Required in every schema |

$ARGUMENTS
