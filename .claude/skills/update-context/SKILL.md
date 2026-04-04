---
name: update-context
description: Update docs/context.md and docs/architecture.md with current project state — run after significant changes
context: fork
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

Update the project documentation to reflect the current state.

## Process

1. **Scan current state**:
   - `find src/ -name "*.py" -type f | head -50` — list all source files
   - `grep -r "class.*BaseModel" src/ --include="*.py" -l` — find Pydantic models
   - `grep -r "@router\." src/ --include="*.py"` — find API endpoints
   - `grep -r "def.*chain\|def.*agent\|class.*Chain\|class.*Agent" src/ --include="*.py"` — find LLM chains/agents
   - `git log --oneline -20` — recent changes
   - `git diff --stat HEAD~5` — files changed recently

2. **Update docs/context.md**:
   - Current branch and recent work
   - Active experiments (git worktrees)
   - Known issues or blockers
   - What was just completed
   - What's next

3. **Update docs/architecture.md**:
   - Verify component list matches actual src/ structure
   - Update Mermaid diagrams if new components/routes added
   - Update API routes table
   - Update LLM chain/agent inventory

4. **Verify @imports in CLAUDE.md** still reference valid files

5. Commit: `git add docs/context.md docs/architecture.md && git commit -m "docs: update context and architecture"`

$ARGUMENTS
