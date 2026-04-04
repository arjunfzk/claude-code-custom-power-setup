---
name: self-learn
description: Extract reusable knowledge from the current session — debugging breakthroughs, workarounds, patterns discovered — and save as rules or memory for future sessions
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

Extract reusable knowledge from what just happened in this session and persist it for future sessions.

Inspired by Claudeception — the idea that Claude should get smarter per-project over time, not start from zero every session.

## When to Run This

Run `/self-learn` after:
- Debugging a tricky issue (the fix is worth remembering)
- Discovering a non-obvious workaround
- Figuring out a project-specific pattern through trial and error
- Learning something about an API/library that isn't in the docs
- Finding a configuration that works after several attempts

## Process

### Step 1: Identify What Was Learned

Review the current conversation for moments of discovery:
- "Oh, the issue was actually X" (debugging breakthrough)
- "This API requires Y, which isn't documented" (undocumented behavior)
- "The pattern that works is Z" (discovered pattern)
- "Don't do A because B happens" (learned anti-pattern)

Ask the user: "What was the key insight from this session?" (if not obvious from context)

### Step 2: Classify the Knowledge

| Type | Where It Goes | Example |
|------|--------------|---------|
| Project convention | `.claude/rules/` (new file or edit existing) | "This project uses custom middleware pattern X" |
| API/library gotcha | Agent memory (`memory: project`) | "PydanticAI's TestModel doesn't support streaming" |
| Debugging pattern | `docs/gotchas.md` (create if doesn't exist) | "When pgvector returns empty, check index status first" |
| Reusable snippet | `.claude/skills/` (new skill) | "Process for setting up new LangGraph agent" |
| Architecture decision | `docs/architecture.md` (update) | "We use fan-out for search because single-source was unreliable" |

### Step 3: Write It Down

**For rules (most common):**
```markdown
# .claude/rules/[topic].md (new or append to existing)
---
paths:
  - "relevant/path/**"
---

# [Discovery]
[What we learned, expressed as a rule]
[Why — the context that makes this non-obvious]
[Example — concrete code showing the pattern]
```

**For gotchas doc:**
```markdown
# docs/gotchas.md (append)

## [Date]: [Short title]
**Problem:** [What went wrong]
**Root cause:** [Why it went wrong — the non-obvious part]
**Fix:** [What solved it]
**Prevention:** [How to avoid this in the future]
```

**For agent memory:**
Update the relevant agent's memory file at `~/.claude/projects/<project>/memory/`

### Step 4: Verify

- If a rule was added: check it doesn't conflict with existing rules
- If a gotcha was documented: check it's not already documented
- If memory was updated: check the 200-line MEMORY.md limit

### Step 5: Commit

```bash
git add -A && git commit -m "docs: self-learn — [short description of what was learned]"
```

## Rules

- ONLY save genuinely non-obvious knowledge. Don't save "use pytest for testing."
- Always include the WHY — the context that makes this useful
- Keep rules/gotchas short. If it's more than 10 lines, it should be a skill.
- Include a concrete example whenever possible
- Tag with date so we know when it was discovered (APIs change)

$ARGUMENTS
