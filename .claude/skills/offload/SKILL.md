---
name: offload
description: |
  Delegate a task to Codex CLI. Codex works in an isolated git worktree with full repo access,
  makes changes, and commits. You review the result. Use when you want to free up your
  context window by shipping work to another model. Use when asked to "offload", "send to
  codex", "delegate to codex", "let codex handle", or "offload this task".
disable-model-invocation: true
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# /offload — Delegate Work to Codex

Ship a task to Codex CLI. It gets an isolated worktree copy of the repo, does the work,
commits. You review the diff when it's done. Your working tree and context stay clean.

## CRITICAL: Output Visibility

ALL Codex output MUST stream visibly to the user. Never redirect stderr.
Never write to temp files. Let everything flow.

## Step 0: Verify Codex is Available

```bash
command -v codex && codex --version || echo "NOT FOUND: Install with npm i -g @openai/codex"
```

If not found, stop and tell the user to install it.

## Step 1: Prepare the Task

Parse the user's input after `/offload`. The task description is everything after the command.

Before sending to Codex, gather context Claude already has:
- Current branch: `git branch --show-current`
- Relevant files the user has been discussing in this session
- Any constraints or requirements mentioned

## Step 2: Create an Isolated Worktree

**IMPORTANT:** Use `git worktree`, NOT `git checkout -b`. A worktree creates a completely
separate working directory. Your current tree with any uncommitted WIP is untouched.

```bash
_BRANCH=$(git branch --show-current)
_OFFLOAD_BRANCH="offload/$(date +%Y%m%d-%H%M%S)"
_OFFLOAD_DIR="../offload-$(date +%Y%m%d-%H%M%S)"
git worktree add "$_OFFLOAD_DIR" -b "$_OFFLOAD_BRANCH"
_OFFLOAD_ABS=$(cd "$_OFFLOAD_DIR" && pwd)
echo "Created isolated worktree: $_OFFLOAD_ABS"
echo "Branch: $_OFFLOAD_BRANCH (will merge back to $_BRANCH)"
```

## Step 3: Run Codex with Write Access

**IMPORTANT:** Use `--full-auto` BEFORE `exec` to prevent Codex from hanging on approval prompts.
Point `-C` at the worktree directory, NOT the main repo.

```bash
codex --full-auto exec \
  "IMPORTANT: Do NOT read or modify files under .claude/, ~/.claude/, or .agents/. Those are AI skill definitions for a different system. Stay focused on repository code only.

TASK: $TASK_DESCRIPTION

INSTRUCTIONS:
- Make the changes needed to complete the task
- Write clean, well-documented code
- Run tests if they exist: look for pytest, vitest, or flutter test
- CRITICAL: You MUST commit your changes before finishing. Run: git add <files> && git commit -m 'feat: description'
- Use conventional commits (feat:, fix:, refactor:, test:)
- If you need to create new files, follow existing project patterns
- Do NOT modify .env, migrations, or lock files
- YOUR FINAL ACTION MUST BE a git commit. Do not finish without committing." \
  -C "$_OFFLOAD_ABS" \
  -s workspace-write \
  -c model_reasoning_effort="high"
```

Set `timeout: 300000` (5 minutes) on the Bash tool call.

## Step 4: Check Results — Including Uncommitted Changes

After Codex finishes, check BOTH committed and uncommitted state:

```bash
cd "$_OFFLOAD_ABS"

echo "=== CODEX COMPLETED ==="
echo ""

# Check for uncommitted changes (Codex may have edited but not committed)
_DIRTY=$(git status --porcelain)
if [ -n "$_DIRTY" ]; then
    echo "WARNING: Codex left uncommitted changes"
    git status --short
    echo ""
fi
```

**CLAUDE'S RESPONSIBILITY:** If Codex left uncommitted changes, Claude MUST handle them:
1. Review the uncommitted files — read them to verify they look correct
2. If they look good, commit them in the worktree:
   ```bash
   cd "$_OFFLOAD_ABS"
   git add -A
   git commit -m "feat: complete offloaded task — committed by Claude after Codex"
   ```
3. If they look broken, tell the user and offer to discard

This is NOT optional. Codex frequently creates files without committing. Claude must
close the loop so the user sees a clean diff in Step 5.

```bash
echo "=== Commits made ==="
git log "$_BRANCH".."$_OFFLOAD_BRANCH" --oneline
echo ""
echo "=== Files changed ==="
git diff "$_BRANCH".."$_OFFLOAD_BRANCH" --stat
echo ""
echo "=== Full diff ==="
git diff "$_BRANCH".."$_OFFLOAD_BRANCH"
```

Return to the main working directory after showing results:

```bash
cd -
```

## Step 5: Ask User What to Do

Present the results and ask via AskUserQuestion:

**Options:**

- **A) Merge** — merge the offload branch into your working branch:
  ```bash
  git merge "$_OFFLOAD_BRANCH" --no-ff -m "feat: merge offloaded work — $TASK_SUMMARY"
  git worktree remove "$_OFFLOAD_ABS"
  git branch -D "$_OFFLOAD_BRANCH"
  ```

- **B) Review and edit** — keep the worktree, let Claude inspect and modify before merging:
  ```bash
  # Claude reads files in $_OFFLOAD_ABS, suggests changes
  # After edits: merge as in option A
  ```

- **C) Discard** — throw away all of Codex's work:
  ```bash
  git worktree remove "$_OFFLOAD_ABS" --force
  git branch -D "$_OFFLOAD_BRANCH"
  echo "Offload discarded. No changes to your working tree."
  ```

**On merge conflict:** If merge fails, show the conflicts and let the user resolve them manually or ask Claude to help.

**Always return to the original branch** after any option:
```bash
git checkout "$_BRANCH"
```

## Important Rules

1. **Output must be visible** — let Codex output stream directly, no redirects
2. **Always use git worktree** — never `git checkout -b` in the same tree. Protects user's WIP.
3. **Use `--full-auto`** — prevents Codex from hanging on approval prompts. Goes BEFORE `exec`.
4. **5-minute timeout** — set `timeout: 300000` on the Bash tool call
5. **Check for uncommitted changes** — Codex may edit without committing on timeout/error
6. **Filesystem boundary** — always tell Codex to ignore .claude/ and .agents/ (advisory, not enforced)
7. **Show the full diff** — user must see exactly what Codex changed before merging
8. **Never auto-merge** — always ask the user what to do with the result
9. **Clean up worktree** — always remove the worktree after merge or discard
10. **Conventional commits** — instruct Codex to use feat:/fix:/refactor:/test: prefixes
