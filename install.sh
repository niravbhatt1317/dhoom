#!/usr/bin/env bash
# dhoom installer — sets up your projects folder, Claude skill, and shell alias
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

success() { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}!${RESET} $*"; }
step()    { echo -e "\n${CYAN}${BOLD}→${RESET} $*"; }

echo ""
echo -e "${BOLD}💥 dhoom — installer${RESET}"
echo -e "${CYAN}────────────────────${RESET}"
echo -e "${DIM}  Sets up your projects folder, Claude skill, and shell alias.${RESET}"

# ── Step 1: Projects root ──────────────────────────────────────────────────────
step "Where do you want to store your projects?"
echo -e "   ${DIM}This is the folder dhoom will create all your projects inside.${RESET}"
printf "   Path [~/Claude-Projects]: "
read -r INPUT_ROOT
INPUT_ROOT="${INPUT_ROOT:-$HOME/Claude-Projects}"
# Expand ~ manually (read doesn't expand it)
PROJECTS_ROOT="${INPUT_ROOT/#\~/$HOME}"

if [[ ! -d "$PROJECTS_ROOT" ]]; then
  echo ""
  echo -e "   ${DIM}$PROJECTS_ROOT doesn't exist yet.${RESET}"
  printf "   Create it? [Y/n] "
  read -r CONFIRM
  if [[ "${CONFIRM:-Y}" =~ ^[Yy]$ ]]; then
    mkdir -p "$PROJECTS_ROOT"
    success "Created $PROJECTS_ROOT"

    # Offer to create starter subfolders
    echo ""
    echo -e "   ${DIM}Want to create any starter folders inside it?${RESET}"
    echo -e "   ${DIM}(e.g. Personal, Work — comma-separated, or Enter to skip)${RESET}"
    printf "   → "
    read -r STARTER_INPUT
    if [[ -n "$STARTER_INPUT" ]]; then
      IFS=',' read -ra STARTERS <<< "$STARTER_INPUT"
      for s in "${STARTERS[@]}"; do
        folder=$(echo "$s" | tr -d '[:space:]')
        [[ -z "$folder" ]] && continue
        mkdir -p "$PROJECTS_ROOT/$folder"
        success "Created folder: $folder"
      done
    fi
  else
    echo -e "   ${RED}✗${RESET} Cannot continue without a projects folder." >&2
    exit 1
  fi
else
  success "Found existing projects folder: $PROJECTS_ROOT"
fi

# ── Step 2: Save config ────────────────────────────────────────────────────────
step "Saving config"
mkdir -p "$HOME/.dhoom"
cat > "$HOME/.dhoom/config" << CFGEOF
# dhoom config — edit anytime
PROJECTS_ROOT="$PROJECTS_ROOT"
CFGEOF
success "Config saved to ~/.dhoom/config"

# ── Step 3: Install Claude skill ───────────────────────────────────────────────
step "Installing /dhoom Claude skill"
CLAUDE_CMDS="$HOME/.claude/commands"
mkdir -p "$CLAUDE_CMDS"
cp "$SCRIPT_DIR/.claude/commands/dhoom.md" "$CLAUDE_CMDS/dhoom.md"
success "Skill installed → type /dhoom in any Claude Code session"

# ── Step 4: Add shell alias ────────────────────────────────────────────────────
step "Adding shell alias"
ALIAS_LINE="alias dhoom='bash \"$SCRIPT_DIR/dhoom.sh\"'"
ZSHRC="$HOME/.zshrc"

if grep -qF "alias dhoom=" "$ZSHRC" 2>/dev/null; then
  warn "alias dhoom already exists in ~/.zshrc — skipping"
else
  echo "" >> "$ZSHRC"
  echo "# dhoom — project scaffold tool" >> "$ZSHRC"
  echo "$ALIAS_LINE" >> "$ZSHRC"
  success "Alias added to ~/.zshrc"
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}All set! Here's what you've got:${RESET}"
echo -e "   ${CYAN}Projects root:${RESET} $PROJECTS_ROOT"
echo -e "   ${CYAN}Claude skill:${RESET}  /dhoom  (in any Claude Code session)"
echo -e "   ${CYAN}Terminal alias:${RESET} dhoom   (after running: source ~/.zshrc)"
echo ""
echo -e "${DIM}  Run ${BOLD}source ~/.zshrc${RESET}${DIM} then type ${BOLD}dhoom${RESET}${DIM} to create your first project.${RESET}"
echo ""
