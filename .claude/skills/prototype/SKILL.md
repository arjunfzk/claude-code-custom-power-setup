---
name: prototype
description: Build a throwaway prototype to answer a design question. Routes between two branches — terminal app for logic/state questions, or multiple radically different UI variants for visual questions. Use when user wants to prototype, sanity-check a data model, mock up a UI, or says "prototype this".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify which question is being answered:

- **"Does this logic / state model feel right?"** → Build a tiny interactive terminal app (see Logic section below)
- **"What should this look like?"** → Generate several radically different UI variations (see UI section below)

If ambiguous, default to whichever matches the surrounding code (backend → logic, page/component → UI).

## Rules (both branches)

1. **Throwaway from day one.** Name it so a reader can see it's a prototype, not production.
2. **One command to run.** Use the project's existing task runner.
3. **No persistence by default.** State lives in memory.
4. **Skip polish.** No tests, no error handling beyond what makes it runnable, no abstractions.
5. **Surface the state.** After every action, print or render the full relevant state.
6. **Delete or absorb when done.** Capture the answer (commit message, ADR, or NOTES.md), then clean up.

---

## Logic Prototype

For state/business-logic questions. Build a TUI where state is fully re-rendered each tick.

### Process

1. **State the question** — write what state model and what question you're prototyping at the top of the file.
2. **Isolate logic in a portable module** — put the actual logic behind a small, pure interface that could be lifted into production later. The TUI around it is throwaway; the logic module shouldn't be.
   - Pure reducer: `(state, action) => state`
   - State machine: explicit states and transitions
   - Pure functions over a plain data type
3. **Build the TUI** — clear screen and re-render each tick. Show:
   - Current state (bold field names, dim context)
   - Keyboard shortcuts at bottom: `[a] add user  [d] delete user  [q] quit`
4. **Make it runnable** in one command.
5. **Hand it over** — the interesting moments are "wait, that shouldn't be possible."

### Anti-patterns
- Don't add tests. Don't wire to a real database. Don't generalize.
- Don't blur logic and TUI together — keep the TUI as a thin shell over the pure module.

---

## UI Prototype

For visual/layout questions. Generate 3+ structurally different UI variations on a single route.

### Process

1. **State the question and pick N** — default 3 variants, cap at 5.
2. **Generate radically different variants** — different layout, different information hierarchy, not just different colors. Use the project's component library/styling system.
3. **Wire together** with a `?variant=` URL param switcher:
   - Floating bottom bar with left/right arrows to cycle variants
   - Arrow keys also cycle (don't intercept when input is focused)
   - Hidden in production builds (`NODE_ENV !== 'production'`)
4. **Prefer embedding in existing pages** over creating new routes — real app context exposes design problems that a vacuum route hides.
5. **Hand it over** — typical feedback is "I want the header from B with the sidebar from C."

### Anti-patterns
- Variants that differ only in color/copy — that's a tweak, not a prototype.
- Sharing too much layout code between variants — defeats the point.
- Promoting prototype directly to production — rewrite properly when folding in.

$ARGUMENTS
