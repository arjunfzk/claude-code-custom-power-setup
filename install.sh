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

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
GLOBAL_DIR="$HOME/.claude"
BACKUP_DIR="$GLOBAL_DIR/backups/pre-power-setup-$(date +%Y%m%d-%H%M%S)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}!${NC} $*"; }
step()  { echo -e "\n${YELLOW}▶${NC} $*"; }
dry()   { echo -e "  ${YELLOW}[dry-run]${NC} $*"; }

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
    $DRY_RUN && dry "mkdir -p $dir" || mkdir -p "$dir"
    info "Created $dir"
  else
    info "$dir already exists"
  fi
done

# ── 2. Backup existing config ──────────────────────────────────────────────
EXISTING_SETTINGS="$GLOBAL_DIR/settings.json"
if [[ -f "$EXISTING_SETTINGS" ]]; then
  step "Backing up existing ~/.claude/settings.json"
  $DRY_RUN && dry "cp $EXISTING_SETTINGS $BACKUP_DIR/settings.json" || {
    mkdir -p "$BACKUP_DIR"
    cp "$EXISTING_SETTINGS" "$BACKUP_DIR/settings.json"
  }
  info "Backup saved to $BACKUP_DIR/settings.json"
fi

# ── 3. Copy skills ─────────────────────────────────────────────────────────
step "Installing skills → ~/.claude/skills/"
SKILLS_SRC="$REPO_DIR/.claude/skills"
SKILLS_DST="$GLOBAL_DIR/skills"
INSTALLED=0
SKIPPED=0
for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_dir")
  dst="$SKILLS_DST/$skill_name"
  if [[ -d "$dst" ]]; then
    warn "  $skill_name already exists — skipping (delete $dst to reinstall)"
    (( SKIPPED++ )) || true
  else
    $DRY_RUN && dry "cp -r $skill_dir $dst" || cp -r "$skill_dir" "$dst"
    info "  Installed /$skill_name"
    (( INSTALLED++ )) || true
  fi
done
echo "  Skills: $INSTALLED installed, $SKIPPED skipped"

# ── 4. Copy agents ─────────────────────────────────────────────────────────
step "Installing agents → ~/.claude/agents/"
AGENTS_SRC="$REPO_DIR/.claude/agents"
AGENTS_DST="$GLOBAL_DIR/agents"
INSTALLED=0; SKIPPED=0
for agent_file in "$AGENTS_SRC"/*.md; do
  agent_name=$(basename "$agent_file")
  dst="$AGENTS_DST/$agent_name"
  if [[ -f "$dst" ]]; then
    warn "  $agent_name already exists — skipping"
    (( SKIPPED++ )) || true
  else
    $DRY_RUN && dry "cp $agent_file $dst" || cp "$agent_file" "$dst"
    info "  Installed $agent_name"
    (( INSTALLED++ )) || true
  fi
done
echo "  Agents: $INSTALLED installed, $SKIPPED skipped"

# ── 5. Copy rules ──────────────────────────────────────────────────────────
step "Installing context rules → ~/.claude/rules/"
RULES_SRC="$REPO_DIR/.claude/rules"
RULES_DST="$GLOBAL_DIR/rules"
INSTALLED=0; SKIPPED=0
for rule_file in "$RULES_SRC"/*.md; do
  rule_name=$(basename "$rule_file")
  dst="$RULES_DST/$rule_name"
  if [[ -f "$dst" ]]; then
    warn "  $rule_name already exists — skipping"
    (( SKIPPED++ )) || true
  else
    $DRY_RUN && dry "cp $rule_file $dst" || cp "$rule_file" "$dst"
    info "  Installed $rule_name"
    (( INSTALLED++ )) || true
  fi
done
echo "  Rules: $INSTALLED installed, $SKIPPED skipped"

# ── 6. Merge hooks into ~/.claude/settings.json ────────────────────────────
step "Merging hooks into ~/.claude/settings.json"

MERGE_SCRIPT=$(cat <<'PYEOF'
import json, sys, os

src_file  = sys.argv[1]   # template settings.json
dst_file  = sys.argv[2]   # ~/.claude/settings.json
dry_run   = sys.argv[3] == "true"

with open(src_file) as f:
    src = json.load(f)

dst = {}
if os.path.isfile(dst_file):
    with open(dst_file) as f:
        try:
            dst = json.load(f)
        except json.JSONDecodeError:
            print(f"  WARNING: {dst_file} is invalid JSON — creating fresh copy")
            dst = {}

src_hooks = src.get("hooks", {})
dst_hooks  = dst.setdefault("hooks", {})

added = 0
for event, handlers in src_hooks.items():
    if event not in dst_hooks:
        dst_hooks[event] = handlers
        added += len(handlers)
    else:
        # Append only handlers that don't already exist (match by command string)
        existing_cmds = {h.get("command","") for block in dst_hooks[event] for h in block.get("hooks",[])}
        for block in handlers:
            for h in block.get("hooks", []):
                if h.get("command","") not in existing_cmds:
                    dst_hooks[event].append(block)
                    added += 1
                    break

print(f"  {added} new hook handlers merged")
if not dry_run:
    with open(dst_file, "w") as f:
        json.dump(dst, f, indent=2)
    print(f"  Saved to {dst_file}")
else:
    print("  [dry-run] Would write merged settings")
PYEOF
)

SETTINGS_SRC="$REPO_DIR/.claude/settings.json"
$DRY_RUN \
  && python3 -c "$MERGE_SCRIPT" "$SETTINGS_SRC" "$EXISTING_SETTINGS" "true" \
  || python3 -c "$MERGE_SCRIPT" "$SETTINGS_SRC" "$GLOBAL_DIR/settings.json" "false"

# ── 7. Set up global CLAUDE.md hint ───────────────────────────────────────
step "Checking ~/.claude/CLAUDE.md"
GLOBAL_CLAUDE="$GLOBAL_DIR/CLAUDE.md"
if [[ -f "$GLOBAL_CLAUDE" ]]; then
  info "~/.claude/CLAUDE.md already exists — leaving it unchanged"
  warn "  To add global rules: edit $GLOBAL_CLAUDE"
else
  warn "No ~/.claude/CLAUDE.md found"
  if ! $DRY_RUN; then
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
  else
    dry "Would create ~/.claude/CLAUDE.md with starter global rules"
  fi
fi

# ── 8. Summary ────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next steps:"
echo ""
echo "  1. Install community plugins (run inside any Claude Code session):"
echo "       /install-github superpowers-ai/superpowers"
echo "       /install-github superpowers-ai/gsd"
echo ""
echo "  2. Optional — install AI peer review CLI:"
echo "       npm i -g @openai/codex     # for /second-opinion"
echo "       npm i -g @google/gemini-cli # fallback"
echo ""
echo "  3. Restart Claude Code — new skills and hooks take effect on next session."
echo ""
echo "  4. Edit ~/.claude/CLAUDE.md to add your personal global rules."
echo ""
