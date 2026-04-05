---
name: inspiration
description: Use when given a GitHub repo URL to analyze for ideas, patterns, and approaches worth adopting — before planning or implementing. Produces a structured Keep / Adapt / Discard breakdown.
allowed-tools:
  - Read
  - WebFetch
  - WebSearch
  - Glob
  - Grep
  - Bash
  - mcp__sequential-thinking__sequentialthinking
---

# Inspiration Analysis

Objectively analyze a GitHub repo to extract what's worth adopting, adapting, or discarding — without copying blindly.

**Input format:** `inspiration <repo-url> [optional focus area]`

Example: `inspiration https://github.com/owner/repo focus on hooks and CLAUDE.md patterns`

## When to Use

- Before planning a phase where a similar repo exists
- When the user says "take inspiration from X repo"
- When exploring how others solve a problem you're about to tackle
- In plan mode: to inform decisions before writing a plan

---

## Process

### Step 0: Validate Input

Parse `$ARGUMENTS`:
- Extract `repo-url` — if missing or malformed, ask the user for it before proceeding
- Extract optional `focus-area` — if absent, do a broad sweep

### Step 1: Fetch Repo Metadata First

**Before reading anything locally**, get the repo health signals to decide if it's worth analyzing:
- Fetch `https://api.github.com/repos/<owner>/<repo>` for: stars, forks, open_issues, pushed_at, default_branch, language, archived status
- If private or returns 404: note it and proceed with whatever is publicly accessible
- Record: **stars**, **last pushed**, **issue count**, **primary language**, **archived: yes/no**

**Early bail check:** If the repo is archived, has <50 stars with 0 recent activity, or uses a completely incompatible tech stack — flag this to the user and ask if they still want to proceed before burning more tokens.

### Step 2: Gather Current Project Context

Read the current project to anchor `Fit` / `Project Alignment` judgments:
- Read `CLAUDE.md` / `docs/context.md` / `docs/architecture.md` if they exist
- Note: tech stack, team size signals, project goals, any stated constraints

If no project context files exist, explicitly note: *"No project context found — Project Alignment ratings are assumptions, not confirmed matches."*

### Step 3: Fetch Repo Content

Use the default branch from Step 2 to build raw URLs: `https://raw.githubusercontent.com/<owner>/<repo>/<default-branch>/<path>`

**Fetch in this order — stop early if focus area is narrow:**

**Tier 1 — Universal architecture signals (always fetch):**
- `README.md` — stated goals, philosophy, non-negotiables
- `pyproject.toml` OR `package.json` OR `pubspec.yaml` — tech stack and dependency choices
- Root directory listing via `https://api.github.com/repos/<owner>/<repo>/contents/` — discover what exists before guessing paths

**Tier 2 — Configuration & AI setup (fetch if relevant to focus or if found in Tier 1):**
- `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`
- `.claude/settings.json`
- `.claude/hooks/` (list then fetch selectively)
- `.claude/skills/` (list then fetch selectively)

**Tier 3 — Workflow & infra (fetch if relevant):**
- `.github/workflows/` (list, fetch 1–2 most relevant)
- `Makefile` or `justfile`
- `docker-compose.yml` / `Dockerfile`
- `docs/architecture.md` or `docs/context.md`

**Tier 4 — Source code samples (pick 2–3 max):**
- Choose representative files, not random ones
- Prefer: entry points, core abstractions, a test file

**Tier 5 — Issue/PR signals (check if Tier 1–4 raises questions):**
- Search open issues for "refactor", "remove", "migrate", "problem", "regret" — these reveal what maintainers wish they'd done differently
- A pattern the code uses + an open issue migrating away from it = Discard, not Keep

**Rules for fetching:**
- If a path returns 404, note it and move on — do not retry
- Do not fetch more than ~15 files total
- For monorepos: focus on the most relevant sub-package only

### Step 4: Objective Analysis

For each significant finding, evaluate on THREE dimensions:

| Dimension | Question |
|-----------|----------|
| **Fit** | Does this match our confirmed project context? (or "assumed fit" if no context) |
| **Quality** | Well-designed? Repo health supports it? (stars, activity, issues) |
| **Cost** | One-time setup vs ongoing maintenance burden? |

Use Sequential Thinking to reason through each trade-off. Push back on novelty bias — something being new or clever is not a reason to adopt it.

**Mandatory objectivity check:** If you have found fewer than 2 things to discard, you are not being critical enough. Keep analyzing.

### Step 5: Produce the Inspiration Report

```markdown
# Inspiration Analysis: [repo-name]

**Repo:** [URL]
**Analyzed:** [date]
**Focus:** [broad | specific area]
**Repo health:** ⭐ [stars] | Last push: [date] | Open issues: [N] | Archived: [yes/no]
**Project context:** [found/not found — affects Fit confidence]

---

## Key Observations

[2–4 sentence narrative: what kind of repo is this, what problem does it solve, what's its overall quality signal]

---

## ✅ Keep — Adopt Directly

Low adoption cost, high fit, clearly better than what we have.

| Pattern | Where Found | Why It Works | Project Alignment | How to Adopt |
|---------|------------|-------------|-------------------|-------------|
| [pattern] | [file] | [honest reason] | High/Medium/Low/N-A | [1-line action] |

---

## 🔧 Adapt — Good Idea, Wrong Fit As-Is

Interesting core insight but needs modification for our context.

| Pattern | Where Found | What's Good | What Needs Changing | Why Not Adopt Directly |
|---------|------------|-------------|---------------------|------------------------|
| [pattern] | [file] | [core insight] | [modification needed] | [constraint or mismatch] |

---

## ❌ Discard — Not Worth It

(Required: at least 2 entries. "Discard" means wrong fit, wrong scale, or unmaintainable — NOT necessarily bad code.
Exception: if you genuinely cannot find 2, write a "Perfect Specimen Justification" explaining why this repo has no discardable patterns for our context.)

| Pattern | Why Discard | Reason Type |
|---------|-------------|-------------|
| [pattern] | [honest reason] | wrong-fit / over-engineering / poor-maintenance / wrong-scale / incompatible-stack |

---

## 💡 Novel Ideas

Anything that reframes how you think about the problem, even if not adopted directly.

- **[idea]:** [why it's interesting and what it changes about your mental model]

---

## Summary

**Top 3 actionable takeaways:**
1. [highest-value thing — specific enough to act on]
2. [second most valuable]
3. [third]

**Recommended next step:** [one concrete action]
```

### Step 6: Plan Mode Behavior

**Trigger:** If this skill was invoked while a plan is being written or actively discussed in the current conversation.

**Action:** After the report, append:

```markdown
---

## Inspiration Applied to Plan

For each Keep item, map it to an existing plan step where it should inform implementation.

| Keep Pattern | Plan Step | How It Applies |
|-------------|-----------|---------------|
| [pattern] | [Step N: existing step name] | [specific guidance] |

**Scope note:** Prefer mapping to existing steps. If a finding reveals a significant gap or risk in the current plan (security issue, missing dependency, wrong architecture assumption), you MAY propose a new step — but label it clearly:

> ⚠️ **Inspiration-Driven Scope Expansion:** [step name] — [why this can't be absorbed into an existing step]

The user decides whether to accept scope expansions.
```

**Fallback:** If no plan exists yet, output: *"No active plan found — run /inspiration again after your plan is drafted to get the mapping."*

---

## Rules

- **Context before judgment.** Read the current project context (Step 2) or label Project Alignment as "assumed."
- **Fetch before guessing.** Use the GitHub API to list contents — never guess file paths cold.
- **Health signals matter.** A repo with 50 stars, 2-year-old commits, and 200 open issues is not a reliable model.
- **Don't cargo-cult.** For every "Keep," state WHY it works, not just what it does.
- **Discard section is mandatory.** At least 2 entries. Push harder if you can't find them.
- **Cap your reading.** Max ~15 files. Strategic sampling beats exhaustive reading.
- **Plan mode: prefer existing steps.** Map to existing steps first. New steps only for significant risks, labeled as scope expansions — the user decides.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Making Fit judgments without reading current project | Always do Step 2 first |
| Guessing file paths and getting 404s | Use GitHub API contents endpoint to discover paths |
| Everything lands in "Keep" | Force 2+ Discards — if everything is Keep, you're not analyzing |
| Over-indexing on AI config files for non-AI repos | Check Tier 1 first; Tier 2 only if relevant |
| Tables with truncated reasoning | Add the "Key Observations" narrative section for nuance |
| Plan mode appending new steps | Map only to existing steps — no scope creep |

$ARGUMENTS
