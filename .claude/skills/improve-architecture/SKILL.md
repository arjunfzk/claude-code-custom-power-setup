---
name: improve-architecture
description: Find deepening opportunities in a codebase — places where shallow modules can be consolidated into deep ones. Informed by domain language and documented decisions. Use when user wants to improve architecture, find refactoring opportunities, or make code more testable.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones.

## Vocabulary (use these terms exactly)

- **Module** — anything with an interface and an implementation (function, class, package, slice). _Avoid_: unit, component, service.
- **Interface** — everything a caller must know: types, invariants, error modes, ordering, config. _Avoid_: API, signature (too narrow).
- **Depth** — leverage at the interface. **Deep** = lots of behavior behind a small interface. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives; a place behavior can be altered without editing in place. _Avoid_: boundary.
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage** — what callers get from depth.
- **Locality** — what maintainers get from depth: change, bugs, knowledge concentrated in one place.

**Key principles:**
- **Deletion test**: imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam.
- **One adapter = hypothetical seam. Two adapters = real seam.** Don't introduce a port unless at least two adapters are justified (typically production + test).

## Process

### 1. Explore

Read the project's domain glossary (`CONTEXT.md` or `docs/context.md`) and any ADRs first.

Then explore the codebase organically. Note where you experience friction:
- Understanding one concept requires bouncing between many small modules
- Modules are **shallow** — interface nearly as complex as the implementation
- Pure functions extracted just for testability, but real bugs hide in how they're called
- Tightly-coupled modules leaking across their seams
- Untested or hard-to-test code

Apply the **deletion test** to anything you suspect is shallow.

### 2. Present candidates

Present a numbered list. For each candidate:
- **Files** — which modules are involved
- **Problem** — why the current architecture causes friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of locality and leverage, and how tests would improve

Use CONTEXT.md vocabulary for the domain. If a candidate contradicts an existing ADR, flag it explicitly.

Do NOT propose interfaces yet. Ask: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, drop into a grilling conversation. Walk the design tree — constraints, dependencies, shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline:
- **New term not in CONTEXT.md?** Add it right there.
- **User rejects candidate with a load-bearing reason?** Offer an ADR so future reviews don't re-suggest it.
- **Want alternative interfaces?** Spawn 3+ sub-agents in parallel, each with a different design constraint (minimize interface / maximize flexibility / optimize for common caller / ports-and-adapters). Present and compare results. Give your recommendation.

## Dependency categories for deepening

1. **In-process** — pure computation, no I/O. Always deepenable. No adapter needed.
2. **Local-substitutable** — has local test stand-ins (PGLite for Postgres). Test with stand-in.
3. **Remote but owned** — your own services across network. Define a port, inject adapters.
4. **True external** — third-party (Stripe, Twilio). Inject port, mock in tests.

## Testing after deepening

- Old unit tests on shallow modules become waste — delete them.
- Write new tests at the deepened module's interface.
- Tests assert on observable outcomes, not internal state.
- Tests should survive internal refactors.

$ARGUMENTS
