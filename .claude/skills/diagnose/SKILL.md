---
name: diagnose
description: Structured debugging loop — build a feedback loop, reproduce, hypothesize, instrument, fix, cleanup. Feedback-loop-first approach. Use when user encounters a bug, test failure, or unexpected behavior.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

Six-phase structured debugging. The central claim: having a fast deterministic pass/fail feedback loop is THE skill — everything else is mechanical.

## Phase 1: Build a Feedback Loop

Try these in order (cheapest/fastest first). Stop at the first one that works:

1. **Failing test** — write a test that reproduces the bug. Best case: takes seconds to run, deterministic.
2. **curl / httpie script** — for API bugs, a one-liner that demonstrates the failure.
3. **REPL snippet** — for logic bugs, a few lines in `python -c` or `ipython` that show the wrong output.
4. **Minimal script** — `repro.py` that imports the broken module and exercises it directly.
5. **Log-and-grep** — add a tagged log line (`[DEBUG-xxxx]`), trigger the bug, grep for the tag.
6. **Throwaway harness** — a small FastAPI/Flask app that mounts just the broken component.
7. **Docker isolate** — reproduce in a clean container to rule out environment.
8. **Property / fuzz loop** — when the bug is intermittent, generate random inputs until it triggers.
9. **Bisection harness** — `git bisect run <test>` to find the commit that introduced it.
10. **HITL bash script** — last resort. A script that sets up state and asks the user to verify manually.

The feedback loop IS the product. Once you have any loop, iterate on it (faster, sharper signal, more deterministic).

## Phase 2: Reproduce

Verify the repro matches what the user described — not a nearby different failure. Run the feedback loop, confirm the output matches the reported symptom.

## Phase 3: Hypothesize

Generate **3-5 ranked falsifiable hypotheses** before testing any. Show them to the user (cheap checkpoint).

For each hypothesis:
- What specifically would be true if this is the cause
- What observation would falsify it
- Confidence level (high/medium/low)

Test in order of: (highest confidence) AND (cheapest to test).

## Phase 4: Instrument

Instrument against specific predictions, one variable at a time.

- Use tagged debug logs: `[DEBUG-a4f2]` prefix so cleanup is a single grep.
- Each round: predict what you'll see → observe → compare → update hypotheses.
- Don't shotgun-instrument everything. Test one thing, learn, move on.

## Phase 5: Fix

Once the root cause is identified:

1. **Write the regression test FIRST** (before the fix) — it should fail, confirming it catches the bug.
2. **Apply the minimal fix.**
3. **Run the regression test** — it should pass.
4. **Run the full feedback loop** — confirm the original symptom is gone.

If no "correct seam" exists for the regression test, that fact IS the architectural finding. Flag it for `/improve-architecture`.

## Phase 6: Cleanup and Post-mortem

- Remove all `[DEBUG-xxxx]` tagged lines (grep makes this easy).
- Remove any throwaway harnesses or repro scripts (unless they're useful as tests).
- Answer: **"What would have prevented this bug?"**
  - Missing test coverage? → Add it.
  - Architectural gap? → Flag for `/improve-architecture`.
  - Missing validation? → Add it at the boundary.
  - Stale documentation? → Update it.

$ARGUMENTS
