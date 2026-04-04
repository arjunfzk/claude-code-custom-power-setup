---
name: autoloop
description: |
  Autonomous iteration loop inspired by Karpathy's autoresearch. Set a goal, a mechanical
  metric, and a verify command — Claude runs an unbounded loop of modify → verify → keep/revert.
  Git history becomes memory. Each iteration makes ONE atomic change, measures the metric,
  keeps improvements, reverts failures. Use when asked to "optimize", "improve coverage",
  "reduce latency", "autoloop", "iterate until", "keep improving", or any measurable goal.
disable-model-invocation: true
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# /autoloop — Autonomous Iteration Loop

Set a GOAL → Claude runs the LOOP → You wake up to results.

Constraint + mechanical metric + autonomous iteration = compounding gains.

## Step 0: Setup — Gather Configuration

Ask the user for ALL of these before starting. Use AskUserQuestion if any are missing.
Do NOT start iterating until every required field is filled.

| Field | Required | Example |
|---|---|---|
| **Goal** | Yes | "Increase test coverage to 90%" |
| **Scope** | Yes | `src/**/*.py` — files you're allowed to modify |
| **Metric command** | Yes | `uv run pytest --cov=src --cov-report=term \| grep TOTAL` |
| **Direction** | Yes | `higher` or `lower` (higher coverage = better, lower latency = better) |
| **Verify command** | Yes | `uv run pytest tests/ -x -q` — must pass for a change to be kept |
| **Guard command** | No | `uv run ruff check src/` — optional regression check (e.g., lint must stay clean) |
| **Iterations** | No | Number of iterations (default: unbounded — runs until interrupted) |

### Dry Run

Before starting, validate the setup:

```bash
echo "=== DRY RUN ==="
echo "Running metric command..."
BASELINE=$( <metric command> 2>&1 )
echo "Baseline metric: $BASELINE"
echo ""
echo "Running verify command..."
<verify command> 2>&1
echo "Verify exit code: $?"
```

If verify fails at baseline, STOP — tell the user to fix existing failures first.
Extract the numeric metric value from the baseline output. This is iteration 0.

## Step 1: The Loop

For each iteration (1 to N, or unbounded):

### 1.1 Review

Read the current state:
- Check the results log (if it exists): `cat .claude/autoloop-results.tsv`
- Check recent git history: `git log --oneline -10`
- Read the files in scope to understand current state

Think about what has been tried, what worked, what didn't. Use git history as memory.

### 1.2 Ideate

Based on the goal, prior results, and current state, pick ONE specific change to try.

Rules:
- ONE atomic change per iteration — not two, not three
- Never repeat a change that was already reverted
- Prefer simple changes over complex ones
- If stuck after 3 consecutive reverts, pause and think deeply about a different approach

### 1.3 Modify

Make the change to files within scope ONLY. Do not touch files outside scope.

### 1.4 Commit

Stage ONLY the files you modified within scope. NEVER use `git add -A` — it stages
unrelated files across the entire repo, violating the scope boundary.

```bash
git add <exact files you modified in this iteration>
git commit -m "autoloop(N): <brief description of change>"
```

For example, if scope is `src/**/*.py` and you edited `src/auth/login.py`:
```bash
git add src/auth/login.py
git commit -m "autoloop(3): add edge case test for expired tokens"
```

Commit BEFORE verification so we can revert cleanly if it fails.

**CRITICAL: If `git status` shows unstaged changes outside your scope, leave them alone.
Do NOT stage them. Do NOT commit them. They are not yours to touch.**

### 1.5 Verify

Run the verify command:

```bash
<verify command>
```

If verify fails (non-zero exit), go to step 1.7 (revert).

### 1.6 Measure

Run the metric command and extract the numeric value:

```bash
<metric command>
```

Compare against the previous best metric value.

If a guard command is set, run it too:

```bash
<guard command>
```

### 1.7 Decide

| Condition | Action |
|---|---|
| Metric improved AND verify passed AND guard passed | **KEEP** — this is the new baseline |
| Metric improved AND verify passed AND guard FAILED | **REVERT** — try to rework (max 2 attempts) |
| Metric same or worse | **REVERT** — log as discarded |
| Verify crashed | **FIX** — attempt to fix (max 3 attempts), then revert if still broken |

**To revert:**
```bash
git revert HEAD --no-edit
```

Use `git revert` (creates a new commit), NOT `git reset --hard` (destroys history).

### 1.8 Log

Append to the results log:

```bash
mkdir -p .claude
echo "<iteration>\t<commit_hash>\t<metric_value>\t<delta>\t<status>\t<description>" >> .claude/autoloop-results.tsv
```

| Column | Example |
|---|---|
| iteration | 7 |
| commit_hash | a1b2c3d |
| metric_value | 78.3 |
| delta | +2.1 |
| status | keep / discard / revert / crash |
| description | Added tests for auth module edge cases |

### 1.9 Summary

Every 10 iterations, print a summary:

```
═══ AUTOLOOP PROGRESS (iteration 10/25) ═══
Goal:      Increase test coverage to 90%
Baseline:  62.4%
Current:   78.3% (+15.9)
Best:      78.3% (iteration 9)
Kept:      6/10 iterations
Reverted:  4/10 iterations
═══════════════════════════════════════════
```

### 1.10 Repeat

Go back to step 1.1 unless:
- Iteration count reached (if bounded)
- Goal achieved (metric meets or exceeds target)
- User interrupts
- 5 consecutive reverts with no progress (STOP and ask user for guidance)

## Important Rules

1. **Mechanical metrics ONLY** — no subjective assessment. The metric command output decides, not Claude's opinion.
2. **ONE atomic change per iteration** — never batch multiple changes. If a batch fails, you can't tell which part broke.
3. **Always read before write** — review results log and git history before every iteration.
4. **Git revert, never git reset** — preserve history. History is memory.
5. **Scope is sacred** — never modify files outside the declared scope.
6. **Log everything** — every iteration gets a TSV row, no exceptions.
7. **Stop on confusion** — if 5 consecutive iterations revert, stop and ask the user. Don't burn tokens on a dead end.
8. **Prefer simplicity** — the simplest change that improves the metric wins.
