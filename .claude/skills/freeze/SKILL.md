---
name: freeze
description: |
  Lock file edits to a single directory. Prevents Claude from making changes outside
  the specified path. Useful when debugging or working on a focused module to prevent
  collateral changes to unrelated code. Use when asked to "freeze edits", "restrict edits",
  "only edit this folder", "lock down edits", or "focus on this directory".
disable-model-invocation: true
allowed-tools:
  - Bash
  - Read
---

# /freeze — Directory Edit Lock

Restrict all file edits (Write/Edit) to a single directory for this session.

A PreToolUse hook on Write|Edit checks every file modification against the frozen
directory boundary. Edits outside the boundary are blocked with exit 2.

## Activation

Ask the user which directory to restrict edits to, then run:

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# Convert to absolute path with trailing slash
FREEZE_DIR=$(cd "$ARGUMENTS" 2>/dev/null && pwd || echo "$ROOT/$ARGUMENTS")
FREEZE_DIR="${FREEZE_DIR%/}/"
mkdir -p "$ROOT/.claude"
echo "$FREEZE_DIR" > "$ROOT/.claude/.freeze-state"
echo "Edit lock ACTIVE: only files inside $FREEZE_DIR can be modified."
```

## After Activation

Confirm to the user:
- Which directory is frozen (show absolute path)
- Only Write and Edit tools are restricted
- Read, Bash, Glob, Grep remain **unrestricted** — you can still search and read anything
- `/unfreeze` removes the restriction
- The restriction is automatically cleaned up when the session ends

## Important Notes

- This is an **accident-prevention guardrail**, not a security boundary
- Bash commands can still write files anywhere — only the Edit and Write tools are locked
- The `.claude/.freeze-state` file is automatically cleaned up on session end
- If you need to edit a file outside the frozen directory, run `/unfreeze` first
