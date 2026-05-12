---
name: tdd
description: Test-driven development with red-green-refactor loop using vertical slices. Never write all tests first — one test, one implementation, repeat. Use when user wants TDD, test-first development, or says "red-green-refactor".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

Test-driven development with red-green-refactor. Build features one vertical slice at a time.

## Philosophy

**Good tests** are integration-style: they exercise real code paths through public interfaces. They describe WHAT the system does, not HOW. A good test reads like a specification — "user can checkout with valid cart." These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation: they mock internal collaborators, test private methods, or verify through external means. Warning sign: test breaks when you refactor, but behavior hasn't changed.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This produces bad tests:
- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things rather than user-facing behavior
- Tests become insensitive to real changes

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
```

## Workflow

### 1. Planning

Before writing any code:
- [ ] Confirm what interface changes are needed
- [ ] Confirm which behaviors to test (you can't test everything — prioritize)
- [ ] Identify opportunities for deep modules (small interface, deep implementation)
- [ ] Design interfaces for testability
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most important to test?"

### 2. Tracer Bullet

Write ONE test for ONE behavior:
```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

### 3. Incremental Loop

For each remaining behavior:
```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:
- One test at a time
- Only enough code to pass the current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor

After all tests pass:
- [ ] Extract duplication
- [ ] Deepen modules (complexity behind simple interfaces)
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

## Mocking Rules

Mock at **system boundaries** only:
- External APIs (Stripe, OpenAI, etc.)
- Databases (prefer test DB when possible)
- Time / randomness
- File system (sometimes)

**NEVER mock your own classes or internal collaborators.** If you need to mock something you control, that's a design smell — the module interface is wrong.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```

$ARGUMENTS
