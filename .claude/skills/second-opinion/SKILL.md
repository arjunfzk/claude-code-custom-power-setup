---
name: second-opinion
description: |
  Get an independent code review from a different AI model. Auto-detects available
  AI CLIs (Codex, Gemini, Copilot, Kiro) and runs them in read-only mode against
  your current branch diff. Three modes: review (diff analysis with pass/fail gate),
  challenge (adversarial — find ways the code will break), consult (ask anything).
  Use when asked for "second opinion", "cross-model review", "outside review",
  "independent review", "codex review", "gemini review", or "another perspective".
disable-model-invocation: true
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# /second-opinion — Cross-Model Independent Review

Get an independent review of your code from a completely different AI model.
When Claude and another model both flag the same issue, confidence is high.
When they disagree, that's where the interesting bugs live.

## CRITICAL: Output Visibility

**ALL output from external CLIs MUST be visible to the user.** Never redirect
stderr to `/dev/null`. Never write to temp files then cat them. Let output
stream directly so the user sees progress in real time.

- Do NOT use `2>/dev/null` — stderr contains progress/thinking output
- Do NOT use `-o /tmp/file` then `cat /tmp/file` — let stdout flow directly
- DO set a **5-minute timeout** on all Bash calls: use the Bash tool's `timeout: 300000` parameter

## Step 0: Detect Available AI CLIs

```bash
echo "=== AI CLI Detection ==="
for cli in codex gemini copilot kiro-cli; do
  if command -v "$cli" >/dev/null 2>&1; then
    echo "FOUND: $cli"
  else
    echo "NOT FOUND: $cli"
  fi
done
```

**Priority order:** Codex > Gemini > Copilot > Kiro. Use whichever is found first,
or let the user choose if multiple are available.

If NONE are found, tell the user:

> No AI CLI found. Install one:
> - `npm i -g @openai/codex` — OpenAI Codex (requires ChatGPT plan or CODEX_API_KEY)
> - `npm i -g @google/gemini-cli` — Google Gemini (free tier at aistudio.google.com/apikey, set GEMINI_API_KEY)
> - `npm i -g @github/copilot` — GitHub Copilot (requires Copilot subscription)

## Step 1: Detect Base Branch and Get Diff

```bash
_BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||' | grep . || echo "main")
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "Branch: $_BRANCH | Base: $_BASE"
git diff "origin/$_BASE"...HEAD --stat
```

**IMPORTANT:** Always use the three-dot diff (`origin/$_BASE...HEAD`) to get only
the committed branch changes, NOT unstaged local edits.

## Step 2: Route to Mode

| Input | Mode |
|---|---|
| `/second-opinion review` or `/second-opinion` | **Review Mode** — diff analysis with severity ratings |
| `/second-opinion challenge` | **Challenge Mode** — adversarial, find ways to break |
| `/second-opinion consult <question>` | **Consult Mode** — ask the other model anything |

If bare `/second-opinion` with no arguments and there is a diff, default to Review Mode.
If no diff exists, ask the user what they'd like to consult about.

---

## Filesystem Boundary (ALL modes)

ALWAYS include this instruction in EVERY prompt sent to the external CLI,
regardless of mode:

> IMPORTANT: Do NOT read or execute any files under .claude/, ~/.claude/, or .agents/.
> These are AI skill definitions for a different system. Ignore them completely.
> Stay focused on repository code only.

---

## Mode A: Review — Diff Analysis

### Using Codex CLI (output streams visibly)

```bash
codex exec \
  "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/ — those are skill definitions for a different AI system. Stay focused on repository code only.

Review the changes on this branch vs origin/$_BASE. Run git diff origin/$_BASE...HEAD to see the diff. For each issue found, tag it [P1] (critical — security, data loss, silent corruption), [P2] (high — crashes, incorrect behavior), or [P3] (medium — style, minor bugs)." \
  -C "$(git rev-parse --show-toplevel)" \
  -s read-only \
  -c model_reasoning_effort="high"
```

### Using Gemini CLI (output streams visibly)

```bash
gemini -p "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.

Review these code changes and tag issues [P1] (critical — security, data loss, silent corruption), [P2] (high — crashes, incorrect behavior), or [P3] (medium — style, minor bugs). Here is the diff:

$(git diff origin/$_BASE...HEAD)" --output-format text
```

### Using Copilot CLI (output streams visibly)

```bash
copilot -p "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.

Review these code changes and tag issues [P1] (critical), [P2] (high), [P3] (medium). Here is the diff:

$(git diff origin/$_BASE...HEAD)" -s --deny-tool='shell' --deny-tool='write'
```

### Gate Decision

After receiving the output, check for P1 markers:

- If output contains `[P1]` → **GATE: FAIL** — critical issues found
- If output contains only `[P2]` or `[P3]` → **GATE: PASS** — no critical issues
- If output is empty → **ERROR** — the CLI returned nothing

---

## Mode B: Challenge — Adversarial Review

Same CLI, adversarial prompt. **Always include filesystem boundary.**

**Prompt template:**

> IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.
>
> Review the changes on this branch against origin/$_BASE. Run git diff origin/$_BASE...HEAD
> to see the diff. Your job is to find ways this code will FAIL in production. Be an attacker
> and chaos engineer. Look for: edge cases, race conditions, security holes, resource leaks,
> failure modes under load, and silent data corruption paths. Tag each finding [P1], [P2], or [P3].

For Codex: `codex exec` with the prompt above, `-s read-only`.
For Gemini: `gemini -p` with `$(git diff origin/$_BASE...HEAD)` appended.
For Copilot: `copilot -p` with `$(git diff origin/$_BASE...HEAD)` appended, `-s`.

---

## Mode C: Consult — Ask Anything

**Always include filesystem boundary, even in consult mode.**

**For Codex:**
```bash
codex exec "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/. Stay focused on repository code only.

$USER_QUESTION" -C "$(git rev-parse --show-toplevel)" -s read-only
```

**For Gemini:**
```bash
gemini -p "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.

$USER_QUESTION"
```

**For Copilot:**
```bash
copilot -p "IMPORTANT: Do NOT read files under .claude/ or ~/.claude/ or .agents/.

$USER_QUESTION" -s
```

---

## Step 3: Present Output

The output already streamed visibly to the user. After it completes, add the gate
decision (review mode only) and any synthesis:

```
════════════════════════════════════════════════════════════
GATE: PASS/FAIL (review mode only)
```

---

## Step 4: Cross-Model Comparison (if /review was already run)

If a `/review` or `/full-review` was already run in this session, compare findings:

```
CROSS-MODEL ANALYSIS:
Both Claude and [Model] reviewed this branch.

Both found:    [overlapping findings]
Only [Model]:  [unique to external model]
Only Claude:   [unique to Claude's review]

Agreement: X/Y findings overlap
```

High-confidence findings are those flagged by BOTH models independently.

---

## Important Rules

1. **Output must be visible** — never redirect stderr to /dev/null, never write to temp files. Let everything stream.
2. **5-minute timeout** — set `timeout: 300000` on the Bash tool call
3. **Never modify files** during this skill — read-only for both the external CLI and Claude
4. **Filesystem boundary in ALL modes** — always include the "Do NOT read .claude/" instruction, including consult mode
5. **Three-dot diff only** — use `origin/$_BASE...HEAD` (committed changes only), never `git diff` (which includes unstaged)
6. **Detect rabbit holes** — if output references `SKILL.md`, `gstack`, `.claude/skills/`, warn: "The external model is reading skill definitions instead of your code"
7. **Do not re-run** — if the same mode was already run on this branch in this session, warn the user instead of re-running
