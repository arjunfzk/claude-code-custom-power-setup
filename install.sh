#!/usr/bin/env bash
# install.sh — Global Claude Code Power Setup installer
#
# Copies skills, agents, and rules to ~/.claude/ so they are available in
# every project. Merges hooks from .claude/settings.json into the global
# ~/.claude/settings.json without overwriting any settings you already have.
#
# Usage:
#   ./install.sh           — install everything
#   ./install.sh --dry-run — show what would happen, change nothing

set -euo pipefail

# Validate arguments — unknown flags silently proceeding is dangerous
case "${1:-}" in
  ""|"--dry-run") ;;
  "--help"|"-h")
    echo "Usage: ./install.sh [--dry-run]"
    echo "  --dry-run  Show what would happen without making any changes"
    exit 0
    ;;
  *)
    echo "Error: unknown argument '${1}'. Use --dry-run or --help." >&2
    exit 1
    ;;
esac

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Verify python3 is available before starting — it's needed for hook merge
if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required but not found." >&2
  echo "Install it with: brew install python@3.11" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
GLOBAL_DIR="$HOME/.claude"
BACKUP_DIR="$GLOBAL_DIR/backups/pre-power-setup-$(date +%Y%m%d-%H%M%S)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}!${NC} $*"; }
step()  { echo -e "\n${YELLOW}▶${NC} $*"; }
dry()   { echo -e "  ${YELLOW}[dry-run]${NC} would: $*"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude Code Power Setup — Global Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$DRY_RUN && warn "DRY RUN — no changes will be made"
echo ""

# ── 1. Create ~/.claude structure ──────────────────────────────────────────
step "Creating ~/.claude directory structure"
for dir in "$GLOBAL_DIR" "$GLOBAL_DIR/skills" "$GLOBAL_DIR/agents" "$GLOBAL_DIR/rules"; do
  if [[ ! -d "$dir" ]]; then
    if $DRY_RUN; then
      dry "mkdir -p $dir"
    else
      mkdir -p "$dir"
      info "Created $dir"
    fi
  else
    info "$dir already exists"
  fi
done

# ── 2. Backup existing config ──────────────────────────────────────────────
EXISTING_SETTINGS="$GLOBAL_DIR/settings.json"
if [[ -f "$EXISTING_SETTINGS" ]]; then
  step "Backing up existing ~/.claude/settings.json"
  if $DRY_RUN; then
    dry "cp $EXISTING_SETTINGS $BACKUP_DIR/settings.json"
  else
    mkdir -p "$BACKUP_DIR"
    cp "$EXISTING_SETTINGS" "$BACKUP_DIR/settings.json"
    info "Backup saved to $BACKUP_DIR/settings.json"
  fi
fi

# ── 3. Copy skills ─────────────────────────────────────────────────────────
step "Installing skills → ~/.claude/skills/"
SKILLS_SRC="$REPO_DIR/.claude/skills"
SKILLS_DST="$GLOBAL_DIR/skills"
INSTALLED=0
SKIPPED=0
# Guard against empty glob match
shopt -s nullglob
skill_dirs=("$SKILLS_SRC"/*/)
shopt -u nullglob
if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  warn "  No skills found in $SKILLS_SRC"
else
  for skill_dir in "${skill_dirs[@]}"; do
    skill_name=$(basename "$skill_dir")
    dst="$SKILLS_DST/$skill_name"
    if [[ -d "$dst" ]]; then
      warn "  $skill_name already exists — skipping (delete $dst to reinstall)"
      (( SKIPPED++ )) || true
    else
      if $DRY_RUN; then
        dry "cp -r $skill_dir $dst"
        (( INSTALLED++ )) || true
      else
        cp -r "$skill_dir" "$dst"
        info "  Installed /$skill_name"
        (( INSTALLED++ )) || true
      fi
    fi
  done
fi
echo "  Skills: $INSTALLED installed, $SKIPPED skipped"

# ── 4. Copy agents ─────────────────────────────────────────────────────────
step "Installing agents → ~/.claude/agents/"
AGENTS_SRC="$REPO_DIR/.claude/agents"
AGENTS_DST="$GLOBAL_DIR/agents"
INSTALLED=0; SKIPPED=0
shopt -s nullglob
agent_files=("$AGENTS_SRC"/*.md)
shopt -u nullglob
if [[ ${#agent_files[@]} -eq 0 ]]; then
  warn "  No agents found in $AGENTS_SRC"
else
  for agent_file in "${agent_files[@]}"; do
    agent_name=$(basename "$agent_file")
    dst="$AGENTS_DST/$agent_name"
    if [[ -f "$dst" ]]; then
      warn "  $agent_name already exists — skipping"
      (( SKIPPED++ )) || true
    else
      if $DRY_RUN; then
        dry "cp $agent_file $dst"
        (( INSTALLED++ )) || true
      else
        cp "$agent_file" "$dst"
        info "  Installed $agent_name"
        (( INSTALLED++ )) || true
      fi
    fi
  done
fi
echo "  Agents: $INSTALLED installed, $SKIPPED skipped"

# ── 5. Copy rules ──────────────────────────────────────────────────────────
step "Installing context rules → ~/.claude/rules/"
RULES_SRC="$REPO_DIR/.claude/rules"
RULES_DST="$GLOBAL_DIR/rules"
INSTALLED=0; SKIPPED=0
shopt -s nullglob
rule_files=("$RULES_SRC"/*.md)
shopt -u nullglob
if [[ ${#rule_files[@]} -eq 0 ]]; then
  warn "  No rules found in $RULES_SRC"
else
  for rule_file in "${rule_files[@]}"; do
    rule_name=$(basename "$rule_file")
    dst="$RULES_DST/$rule_name"
    if [[ -f "$dst" ]]; then
      warn "  $rule_name already exists — skipping"
      (( SKIPPED++ )) || true
    else
      if $DRY_RUN; then
        dry "cp $rule_file $dst"
        (( INSTALLED++ )) || true
      else
        cp "$rule_file" "$dst"
        info "  Installed $rule_name"
        (( INSTALLED++ )) || true
      fi
    fi
  done
fi
echo "  Rules: $INSTALLED installed, $SKIPPED skipped"

# ── 6. Merge hooks into ~/.claude/settings.json ────────────────────────────
step "Merging hooks into ~/.claude/settings.json"

MERGE_SCRIPT=$(cat <<'PYEOF'
import json, sys, os

src_file = sys.argv[1]   # template settings.json
dst_file = sys.argv[2]   # ~/.claude/settings.json
dry_run  = sys.argv[3] == "true"

# Load and validate source
try:
    with open(src_file) as f:
        src = json.load(f)
except (OSError, json.JSONDecodeError) as e:
    print(f"  ERROR: Cannot read source settings: {e}", file=sys.stderr)
    sys.exit(1)

if not isinstance(src, dict):
    print(f"  ERROR: Source settings.json is not a JSON object", file=sys.stderr)
    sys.exit(1)

# Load destination (may not exist yet)
dst = {}
if os.path.isfile(dst_file):
    try:
        with open(dst_file) as f:
            dst = json.load(f)
        if not isinstance(dst, dict):
            print(f"  WARNING: {dst_file} root is not a JSON object — resetting to empty")
            dst = {}
    except json.JSONDecodeError:
        print(f"  WARNING: {dst_file} is invalid JSON — starting fresh")
        dst = {}

# Validate/coerce hooks structures
src_hooks = src.get("hooks", {})
if not isinstance(src_hooks, dict):
    print("  WARNING: Source hooks is not an object — skipping hook merge")
    src_hooks = {}

dst_hooks_raw = dst.get("hooks", {})
if not isinstance(dst_hooks_raw, dict):
    print("  WARNING: Destination hooks is not an object — resetting to empty")
    dst_hooks_raw = {}
dst["hooks"] = dst_hooks_raw
dst_hooks = dst_hooks_raw

added = 0
for event, src_blocks in src_hooks.items():
    if not isinstance(src_blocks, list):
        continue
    if event not in dst_hooks:
        # New event — add all blocks, skipping any non-dict entries
        valid_blocks = [b for b in src_blocks if isinstance(b, dict)]
        dst_hooks[event] = valid_blocks
        for block in valid_blocks:
            hook_list = block.get("hooks", [])
            if isinstance(hook_list, list):
                added += len([h for h in hook_list if isinstance(h, dict)])
    else:
        dst_blocks = dst_hooks[event]
        if not isinstance(dst_blocks, list):
            # Corrupt destination event — warn and reset rather than silently skip
            print(f"  WARNING: hooks[{event}] in destination is not a list — resetting")
            dst_blocks = []
            dst_hooks[event] = dst_blocks
        # Dedup identity is (matcher, command) — same command under different
        # matchers are intentionally distinct and must both be preserved.
        # Coerce to str to guard against unhashable non-string values.
        def hook_id(block, h):
            matcher = str(block.get("matcher", "")) if isinstance(block, dict) else ""
            command = str(h.get("command", "")) if isinstance(h, dict) else ""
            return (matcher, command)

        existing = {
            hook_id(block, h)
            for block in dst_blocks
            if isinstance(block, dict)
            for h in (block.get("hooks", []) if isinstance(block.get("hooks"), list) else [])
            if isinstance(h, dict)
        }
        for src_block in src_blocks:
            if not isinstance(src_block, dict):
                continue
            src_hook_list = src_block.get("hooks", [])
            if not isinstance(src_hook_list, list):
                continue
            src_entries = [h for h in src_hook_list if isinstance(h, dict)]
            new_entries = [
                h for h in src_entries
                if hook_id(src_block, h) not in existing
            ]
            if new_entries:
                new_block = dict(src_block)
                new_block["hooks"] = new_entries
                dst_blocks.append(new_block)
                # Update identity set so later blocks in same event don't re-add
                for h in new_entries:
                    existing.add(hook_id(src_block, h))
                added += len(new_entries)

print(f"  {added} new hook entries merged")
if not dry_run:
    if added > 0:
        with open(dst_file, "w") as f:
            json.dump(dst, f, indent=2)
        print(f"  Saved to {dst_file}")
    else:
        print("  No changes needed — settings.json unchanged")
else:
    if added > 0:
        print("  [dry-run] would write merged settings")
    else:
        print("  No changes needed — settings.json would be unchanged")
PYEOF
)

SETTINGS_SRC="$REPO_DIR/.claude/settings.json"
if $DRY_RUN; then
  python3 -c "$MERGE_SCRIPT" "$SETTINGS_SRC" "$GLOBAL_DIR/settings.json" "true"
else
  python3 -c "$MERGE_SCRIPT" "$SETTINGS_SRC" "$GLOBAL_DIR/settings.json" "false"
fi

# ── 7. Set up global CLAUDE.md ────────────────────────────────────────────
step "Checking ~/.claude/CLAUDE.md"
GLOBAL_CLAUDE="$GLOBAL_DIR/CLAUDE.md"
if [[ -f "$GLOBAL_CLAUDE" ]]; then
  info "~/.claude/CLAUDE.md already exists — leaving it unchanged"
  warn "  To add global rules: edit $GLOBAL_CLAUDE"
else
  warn "No ~/.claude/CLAUDE.md found"
  if $DRY_RUN; then
    dry "create ~/.claude/CLAUDE.md with starter global rules"
  else
    cat > "$GLOBAL_CLAUDE" <<'CLAUDE_EOF'
# Global Claude Rules

> Applied to every project. Keep under 200 lines.
> Project CLAUDE.md adds project-specific rules on top of these.

## Core Rules

- Use `uv` (never pip, never poetry)
- Log EVERY LLM call: model, tokens, latency_ms, cost_usd, status
- Prompt templates in `prompts/` — never inline in Python
- NEVER hardcode API keys — use pydantic-settings + .env
- NEVER force push main. NEVER commit .env, secrets, model weights
- Close ALL async clients in FastAPI lifespan handler
- NEVER DELETE/UPDATE DB rows without showing count and confirming

## Commits

Conventional commits: feat:, fix:, refactor:, test:, docs:, chore:

## Docs

Every project should have `docs/architecture.md` and `docs/context.md`.
Run `/update-context` after significant changes.
CLAUDE_EOF
    info "Created ~/.claude/CLAUDE.md with starter global rules"
    warn "  Edit $GLOBAL_CLAUDE to add your personal preferences"
  fi
fi

# ── 8. Summary ────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$DRY_RUN && echo "  Dry run complete — no files changed" || echo "  Installation complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if ! $DRY_RUN; then
  echo "  Next steps:"
  echo ""
  echo "  1. Install the Superpowers plugin (run inside any Claude Code session):"
  echo "       /install-github superpowers-ai/superpowers"
  echo ""
  echo "  2. Optional — install AI peer review CLI:"
  echo "       npm i -g @openai/codex     # for /second-opinion"
  echo "       npm i -g @google/gemini-cli # fallback"
  echo ""
  echo "  3. Restart Claude Code — new skills and hooks take effect on next session."
  echo ""
  echo "  4. Edit ~/.claude/CLAUDE.md to add your personal global rules."
  echo ""
  echo "  5. For MCP servers (context7 + sequential-thinking), copy .mcp.json"
  echo "     into each project directory:"
  echo "       cp $REPO_DIR/.mcp.json /path/to/your-project/"
  echo ""
fi
