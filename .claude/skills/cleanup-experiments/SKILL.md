---
name: cleanup-experiments
description: List all git worktree experiments with age, disk usage, and status — offer to remove stale ones
allowed-tools:
  - Bash
  - Read
---

Find and clean up stale experiment worktrees.

## Process

1. **List all worktrees with details:**
```bash
git worktree list --porcelain
```

2. **For each worktree (excluding the main one), gather:**
```bash
# For each worktree path:
BRANCH=$(git -C <path> branch --show-current 2>/dev/null)
LAST_COMMIT_DATE=$(git -C <path> log -1 --format="%ci" 2>/dev/null)
LAST_COMMIT_AGE=$(git -C <path> log -1 --format="%cr" 2>/dev/null)
LAST_COMMIT_MSG=$(git -C <path> log -1 --format="%s" 2>/dev/null)
DISK_USAGE=$(du -sh <path> 2>/dev/null | cut -f1)
HAS_UNCOMMITTED=$(git -C <path> status --porcelain 2>/dev/null | wc -l | tr -d ' ')
DOCKER_RUNNING=$(docker ps --filter "name=exp-" --format "{{.Names}}" 2>/dev/null | grep <name> | wc -l | tr -d ' ')
```

3. **Present a table:**

```
## Experiment Worktrees

| # | Experiment | Branch | Last Commit | Age | Disk | Uncommitted | Docker |
|---|-----------|--------|-------------|-----|------|-------------|--------|
| 1 | exp-chunking-256 | exp/chunking-256 | "fix retriever" | 12 days ago | 340MB | 0 files | stopped |
| 2 | exp-reranker | exp/reranker | "add cohere" | 3 days ago | 280MB | 2 files | running |
| 3 | exp-gpt4o-mini | exp/gpt4o-mini | "swap model" | 31 days ago | 410MB | 0 files | stopped |

Total disk used by experiments: 1.03GB
```

4. **Flag stale experiments** (no commits in >14 days, no running Docker, no uncommitted work):
```
Stale (safe to remove):
  - exp-chunking-256 (12 days, no uncommitted work, Docker stopped)
  - exp-gpt4o-mini (31 days, no uncommitted work, Docker stopped)

Active (keep):
  - exp-reranker (3 days ago, has uncommitted work, Docker running)
```

5. **For each stale experiment, show the removal commands:**
```bash
# Remove exp-chunking-256:
docker compose -f ../exp-chunking-256/docker/docker-compose.yml down 2>/dev/null
git worktree remove ../exp-chunking-256
git branch -d exp/chunking-256

# Remove exp-gpt4o-mini:
docker compose -f ../exp-gpt4o-mini/docker/docker-compose.yml down 2>/dev/null
git worktree remove ../exp-gpt4o-mini
git branch -d exp/gpt4o-mini
```

6. **Ask the user** which experiments to remove. NEVER auto-remove.

7. **After removal, verify:**
```bash
git worktree list  # confirm worktrees removed
git branch -a      # confirm branches deleted
```

$ARGUMENTS
