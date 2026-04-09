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
- **All runtime artifacts MUST be written via Bash redirects (`>`, heredocs) to `$RUN_DIR` in `/tmp/`.** NEVER use the Write tool for brainstorm artifacts — it triggers PreToolUse hooks that block writes on protected branches.
- **All prompts to external CLIs MUST be written to temp files first, then piped via stdin or `$(cat ...)`.** Do NOT inline large prompts as shell arguments — they overflow shell expansion limits and cause Codex to hang on stdin.

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

## Step 0.5: Create Run Directory

All runtime artifacts go in `/tmp/`, never in the project directory. This avoids git hooks and branch protection.

```bash
RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/brainstorm-panel.XXXXXX")"
mkdir -p "$RUN_DIR"/{schemas,prompts,outputs}
cp ~/.claude/skills/brainstorm-panel/schemas/*.json "$RUN_DIR/schemas/"
echo "Run directory: $RUN_DIR"
```

## Step 1: Build Task Packet

Construct `task_packet.txt` via Bash heredoc (never the Write tool):

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

Write prompt to temp file first, then pipe via stdin (avoids shell expansion overflow):

```bash
# Write prompt to file via Bash heredoc
cat > "$RUN_DIR/prompts/m2_round1.txt" << 'PROMPT_EOF'
IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
{ROUND1_PROMPT_M2}
PROMPT_EOF

# Pipe via stdin — Codex accepts '-' for stdin
codex exec - < "$RUN_DIR/prompts/m2_round1.txt" \
  --output-schema "$RUN_DIR/schemas/round1.schema.json" \
  -s read-only --ephemeral \
  {QUALITY_FLAGS_M2} \
  -o "$RUN_DIR/outputs/round1_m2.json"
```

### M3 / Gemini

```bash
cat > "$RUN_DIR/prompts/m3_round1.txt" << 'PROMPT_EOF'
IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
{ROUND1_PROMPT_M3}
PROMPT_EOF

gemini -p "$(cat "$RUN_DIR/prompts/m3_round1.txt")" \
  {QUALITY_FLAGS_M3} \
  -o text > "$RUN_DIR/outputs/round1_m3.raw"
```

Extract JSON from text output (Gemini `-o json` returns wrapper, not raw schema):
```bash
jq -Rs 'match("\\{[\\s\\S]*\\}") | .string' "$RUN_DIR/outputs/round1_m3.raw" | jq -r '.' | jq -e . > "$RUN_DIR/outputs/round1_m3.json"
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

Write prompt to file, then pipe (Round 2 prompts are large — task packet + moderator state + own R1):

```bash
cat > "$RUN_DIR/prompts/m1_round2.txt" << 'PROMPT_EOF'
IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
{ROUND2_PROMPT_M1}
PROMPT_EOF

claude -p "$(cat "$RUN_DIR/prompts/m1_round2.txt")" \
  --no-session-persistence \
  {QUALITY_FLAGS_M1} \
  --output-format text \
  > "$RUN_DIR/outputs/round2_m1.raw"
```

Extract JSON (`--output-format json` returns wrapper metadata, not raw schema):
```bash
jq -Rs 'match("\\{[\\s\\S]*\\}") | .string' "$RUN_DIR/outputs/round2_m1.raw" | jq -r '.' | jq -e . > "$RUN_DIR/outputs/round2_m1.json"
```

### M2 / Codex

```bash
cat > "$RUN_DIR/prompts/m2_round2.txt" << 'PROMPT_EOF'
IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
{ROUND2_PROMPT_M2}
PROMPT_EOF

codex exec - < "$RUN_DIR/prompts/m2_round2.txt" \
  --output-schema "$RUN_DIR/schemas/round2.schema.json" \
  -s read-only --ephemeral \
  {QUALITY_FLAGS_M2} \
  -o "$RUN_DIR/outputs/round2_m2.json"
```

### M3 / Gemini

```bash
cat > "$RUN_DIR/prompts/m3_round2.txt" << 'PROMPT_EOF'
IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
{ROUND2_PROMPT_M3}
PROMPT_EOF

gemini -p "$(cat "$RUN_DIR/prompts/m3_round2.txt")" \
  {QUALITY_FLAGS_M3} \
  -o text > "$RUN_DIR/outputs/round2_m3.raw"
```

Extract JSON (same as Step 3):
```bash
jq -Rs 'match("\\{[\\s\\S]*\\}") | .string' "$RUN_DIR/outputs/round2_m3.raw" | jq -r '.' | jq -e . > "$RUN_DIR/outputs/round2_m3.json"
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

3. Same parallel execution pattern using file-based prompts. Uses `$RUN_DIR/schemas/round3.schema.json` (not round2 — Round 3 has different required fields: `disagreement_ledger`, `failure_modes`, `ranked_recommendations`).
4. For Codex: `--output-schema "$RUN_DIR/schemas/round3.schema.json"`. For Claude/Gemini: same file-based prompt + text extraction as Round 2.

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

If `--out` was provided, save the report to that path via Bash redirect.

**Cleanup:** `$RUN_DIR` in `/tmp/` is auto-cleaned on reboot. If `--keep-artifacts` was passed, print the `$RUN_DIR` path so the user can inspect intermediate outputs (prompts, raw responses, parsed JSON, moderator states).

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
| Using Write tool for artifacts | Triggers PreToolUse hook, blocks on main | Use Bash heredocs + redirects to `$RUN_DIR` |
| Inlining large prompts as shell args | Shell expansion overflow, Codex stdin hang | Write to temp file, pipe via stdin or `$(cat ...)` |
| Writing artifacts to project directory | Git hooks, clutters repo | Always use `/tmp/` via `$RUN_DIR` |

$ARGUMENTS
