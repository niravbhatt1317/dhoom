#!/usr/bin/env bash
# dhoom — scaffold a new React + TS + Vite + Tailwind project
set -euo pipefail

# ── Config (set by install.sh, override anytime) ───────────────────────────────
DHOOM_CONFIG="$HOME/.dhoom/config"
if [[ -f "$DHOOM_CONFIG" ]]; then
  # shellcheck source=/dev/null
  source "$DHOOM_CONFIG"
fi
PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Claude-Projects}"

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

info()    { echo -e "${CYAN}→${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}!${RESET} $*"; }
die()     { echo -e "${RED}✗${RESET} $*" >&2; exit 1; }

# ── Sanitise project name ──────────────────────────────────────────────────────
sanitize_name() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g' \
    | sed 's/--*/-/g' \
    | sed 's/^-//;s/-$//'
}

# ── Fun install machinery ──────────────────────────────────────────────────────
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

MSGS=(
  "Downloading the entire internet..."
  "node_modules: *laughs in 300MB*"
  "Convincing npm to behave..."
  "React is judging your future code..."
  "Bribing the compiler with coffee..."
  "TypeScript side-eyeing your types already"
  "99 little bugs in the code, 99 little bugs..."
  "npm: 22% JavaScript, 78% philosophy"
  "Counting Tailwind classes... still counting..."
  "Your node_modules will outlive the sun"
  "Installing excellence. Please hold."
  "A tree is planted to offset every npm install"
)

LATE_MSGS=(
  "Any second now, we promise..."
  "Still going... but nearly there!"
  "npm is taking its sweet time."
  "Almost done. Probably."
  "Just a liiittle bit longer..."
  "It's not frozen. We checked."
  "npm is buffering. Like YouTube in 2008."
  "Good things take time. Great things take npm."
  "Patience is a virtue. npm is testing yours."
)

JOKES=(
  "Why do Java devs wear glasses?|Because they don't C#."
  "A SQL query walks into a bar...|...asks two tables: Can I join you?"
  "Why do programmers prefer dark mode?|Light attracts bugs."
  "I had a joke about recursion...|...but first, I had a joke about recursion."
)

PHASE_LABELS=("Scaffold" "npm install" "Tailwind")
PHASE_STATUS=(0 0 0)  # 0=pending 1=running 2=done

_phase_bar() {
  local j bar=""
  for j in 0 1 2; do
    local lbl="${PHASE_LABELS[$j]}"
    case "${PHASE_STATUS[$j]}" in
      2) bar+="  ${GREEN}[✓]${RESET} ${lbl}" ;;
      1) bar+="  ${CYAN}[●]${RESET} ${lbl}" ;;
      *) bar+="  ${DIM}[ ] ${lbl}${RESET}" ;;
    esac
  done
  echo -ne "${bar}   "
}

run_fun() {
  local phase_idx="$1" label="$2" joke_idx="$3" estimate="$4"
  shift 4

  # Flash a joke before the install begins
  local raw="${JOKES[$joke_idx]}"
  local setup="${raw%%|*}" punchline="${raw##*|}"
  echo ""
  echo -e "  ${DIM}${setup}${RESET}"
  echo -e "  ${YELLOW}${BOLD}${punchline}${RESET}"
  sleep 2

  # Reserve a blank line, overwrite it with the phase bar
  PHASE_STATUS[$phase_idx]=1
  echo ""
  printf "\033[1A\r"
  _phase_bar
  printf "\n"

  # Run the command in background; pipe y to answer any npm prompts
  echo y | "$@" &>/dev/null &
  local pid=$! start=$SECONDS
  local i=0 mi=0 tick=0 lmi=0 ltick=0

  while kill -0 "$pid" 2>/dev/null; do
    local frame="${SPINNER_FRAMES[$(( i % 10 ))]}"
    local elapsed=$(( SECONDS - start ))
    local msg timer

    if (( elapsed < estimate )); then
      msg="${MSGS[$mi]}"
      local remaining=$(( estimate - elapsed ))
      timer="${DIM}~${remaining}s left${RESET}"
      tick=$(( tick + 1 ))
      if (( tick >= 20 )); then
        tick=0
        mi=$(( (mi + 1) % ${#MSGS[@]} ))
      fi
    else
      msg="${LATE_MSGS[$lmi]}"
      timer="${YELLOW}${elapsed}s · running long${RESET}"
      ltick=$(( ltick + 1 ))
      if (( ltick >= 25 )); then
        ltick=0
        lmi=$(( (lmi + 1) % ${#LATE_MSGS[@]} ))
      fi
    fi

    printf "\r  ${CYAN}%s${RESET}  ${BOLD}%-18s${RESET}  ${DIM}·${RESET}  ${YELLOW}%s${RESET}  %b    " \
      "$frame" "$label" "$msg" "$timer"
    i=$(( i + 1 ))
    sleep 0.1
  done

  local code=0
  wait "$pid" || code=$?
  local elapsed=$(( SECONDS - start ))
  printf "\r%-80s\r" ""  # clear spinner line

  PHASE_STATUS[$phase_idx]=2
  printf "\033[1A\r"     # up to phase bar
  _phase_bar             # rewrite with ✓
  printf "\n"

  if (( code == 0 )); then
    success "$label  [${elapsed}s]"
  else
    die "$label failed after ${elapsed}s"
  fi
}

# ── Step 1: Project name ───────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}💥 dhoom — what are we cooking today?${RESET}"
echo -e "${CYAN}──────────────────────────────────────${RESET}"
echo -e "${DIM}  New project. Clean slate. Let's build something.${RESET}"

while true; do
  echo ""
  echo -e "${BOLD}  What are we calling this thing?${RESET}"
  echo -e "${DIM}  (spaces & special chars → auto-fixed)${RESET}"
  printf "\n  → "
  read -r RAW_NAME
  [[ -z "$RAW_NAME" ]] && warn "Give it a name — anything works." && continue

  PROJECT_NAME=$(sanitize_name "$RAW_NAME")

  if [[ -z "$PROJECT_NAME" ]]; then
    warn "That name produces an empty slug. Try something else."
    continue
  fi

  if [[ "$RAW_NAME" != "$PROJECT_NAME" ]]; then
    echo -e "  ${DIM}slug:${RESET} ${BOLD}$PROJECT_NAME${RESET}"
  fi

  printf "  Lock it in? [Y/n] "
  read -r CONFIRM
  [[ "${CONFIRM:-Y}" =~ ^[Yy]$ ]] && break
done

# ── Step 2: Group folder ───────────────────────────────────────────────────────

# ── Customise for your setup ───────────────────────────────────────────────────
# Add friendly display names and descriptions for your own folders.
# Example:
#   Work)     echo "Work" ;;
#   Personal) echo "Personal" ;;
folder_display_name() {
  case "$1" in
    *) echo "$1" ;;
  esac
}

# Example:
#   Work)     echo "Client projects and day-job work" ;;
#   Personal) echo "Side projects and experiments" ;;
folder_desc() {
  case "$1" in
    *) echo "" ;;
  esac
}
# ──────────────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  Where does this one live?${RESET}"
echo -e "${DIM}  Pick a home for your project.${RESET}"

# Guard: projects root must exist
if [[ ! -d "$PROJECTS_ROOT" ]]; then
  echo ""
  warn "Projects folder not found at $PROJECTS_ROOT"
  echo -e "  ${DIM}Run ${BOLD}./install.sh${RESET}${DIM} to set it up, or create the folder manually.${RESET}"
  exit 1
fi

# Collect group folders — glob expansion avoids ls alias / word-splitting issues
RAW_FOLDERS=()
for dir in "$PROJECTS_ROOT"/*/; do
  [[ -d "$dir" ]] || continue
  name="${dir%/}"
  name="${name##*/}"
  case "$name" in
    .manager|.claude|node_modules|.git) continue ;;
  esac
  RAW_FOLDERS+=("$name")
done

# Edge case: no subfolders yet — offer to create the first one
if [[ ${#RAW_FOLDERS[@]} -eq 0 ]]; then
  echo ""
  warn "No folders found in $PROJECTS_ROOT yet."
  echo -e "  ${DIM}What do you want to call your first one? (e.g. Personal, Work)${RESET}"
  printf "  → "
  read -r FIRST_FOLDER
  FIRST_FOLDER=$(sanitize_name "$FIRST_FOLDER")
  [[ -z "$FIRST_FOLDER" ]] && die "Need at least one folder to continue."
  mkdir -p "$PROJECTS_ROOT/$FIRST_FOLDER"
  success "Created folder: $FIRST_FOLDER"
  RAW_FOLDERS=("$FIRST_FOLDER")
fi

FOLDERS=("${RAW_FOLDERS[@]}")

echo ""
i=1
for g in "${FOLDERS[@]}"; do
  display=$(folder_display_name "$g")
  desc=$(folder_desc "$g")
  echo -e "  ${CYAN}${BOLD}$i)${RESET} ${BOLD}${display}${RESET}"
  [[ -n "$desc" ]] && echo -e "     ${DIM}${desc}${RESET}"
  echo ""
  i=$(( i + 1 ))
done
echo -e "  ${CYAN}${BOLD}$i)${RESET} ${BOLD}+ New folder${RESET}"
echo -e "     ${DIM}Create a brand-new home for this project${RESET}"
NEW_OPT=$i

while true; do
  printf "\n  → "
  read -r CHOICE
  CHOICE="${CHOICE:-1}"

  if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE < NEW_OPT )); then
    GROUP="${FOLDERS[$((CHOICE-1))]}"
    DISPLAY_GROUP=$(folder_display_name "$GROUP")
    success "Dropping it in ${DISPLAY_GROUP}."
    break
  elif [[ "$CHOICE" == "$NEW_OPT" ]]; then
    printf "  Name the new folder: "
    read -r NEW_FOLDER
    NEW_FOLDER=$(sanitize_name "$NEW_FOLDER")
    [[ -z "$NEW_FOLDER" ]] && warn "Needs a name." && continue
    GROUP="$NEW_FOLDER"
    DISPLAY_GROUP="$GROUP"
    mkdir -p "$PROJECTS_ROOT/$GROUP"
    success "New folder ready: $GROUP"
    break
  else
    warn "Pick a number from 1 to $NEW_OPT."
  fi
done

PROJECT_PATH="$PROJECTS_ROOT/$GROUP/$PROJECT_NAME"

# Guard: project already exists
if [[ -d "$PROJECT_PATH" ]]; then
  die "A project already exists at $PROJECT_PATH"
fi

# ── Steps 3–5: Install the stack (with entertainment) ─────────────────────────
echo ""
echo -e "${BOLD}  Firing up the kitchen…${RESET}"
echo -e "${DIM}  Three steps. Some bad jokes. Bear with us.${RESET}"

cd "$PROJECTS_ROOT/$GROUP"
run_fun 0 "Scaffold" 0 15 \
  npm create vite@latest "$PROJECT_NAME" -- --template react-ts --yes

cd "$PROJECT_PATH"
run_fun 1 "npm install" 1 45 \
  npm install

run_fun 2 "Tailwind v4" 2 25 \
  npm install -D tailwindcss @tailwindcss/vite

# ── Step 5: Configure Tailwind v4 ─────────────────────────────────────────────
cat > vite.config.ts << 'VITEEOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
VITEEOF

cat > src/index.css << 'CSSEOF'
@import "tailwindcss";
CSSEOF

success "Tailwind v4 configured"

# ── Step 6: CLAUDE.md ──────────────────────────────────────────────────────────
DISPLAY_NAME=$(echo "$PROJECT_NAME" \
  | sed 's/-/ /g' \
  | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

cat > CLAUDE.md << MDEOF
**Instruction (act on this immediately):** The user just created this project with dhoom. Greet them warmly, tell them the stack is ready, and ask what they want to build or explore today. Get even a rough idea, then suggest a first step to start building it.

# $DISPLAY_NAME

## Tech Stack
- React + TypeScript
- Vite
- Tailwind CSS v4

## Goal
_Not set yet — ask the user._

## Notes
MDEOF

success "CLAUDE.md created"

# ── Step 7: /publish skill ─────────────────────────────────────────────────────
mkdir -p .claude/commands

cat > .claude/commands/publish.md << 'SKILLEOF'
Push this project to a new GitHub repository.

Steps:
1. Check git status — if there are uncommitted changes, ask whether to commit them first with a short message.
2. Ask: should the repo be public or private?
3. Confirm the repo name (default: current directory name).
4. Run: gh repo create <name> --<public|private> --source=. --remote=origin --push
5. Show the new repo URL when done.

If `gh` is not authenticated, tell the user to run `gh auth login` first.
If a remote named "origin" already exists, skip repo creation and just run: git push -u origin main
SKILLEOF

success "/publish skill ready"

# ── Step 8: Git init ───────────────────────────────────────────────────────────
git init -q
git add .
git commit -q -m "chore: initial React + TS + Vite + Tailwind v4 setup"
success "Git initialized with initial commit"

# ── Step 9: Notify Project Manager (if running) ───────────────────────────────
curl -s http://localhost:3030/api/projects > /dev/null 2>&1 || true

# ── Step 10: Open Claude ───────────────────────────────────────────────────────
osascript \
  -e "tell application \"Terminal\" to do script \"cd '$PROJECT_PATH' && claude --remote-control '$PROJECT_NAME' '.'\"" \
  -e "tell application \"Terminal\" to activate" 2>/dev/null || \
  warn "Could not open Terminal automatically. Run: cd '$PROJECT_PATH' && claude --remote-control '$PROJECT_NAME'"

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}💥 dhoom! Go cook something great.${RESET}"
echo -e "   ${CYAN}Project:${RESET}  $DISPLAY_NAME"
echo -e "   ${CYAN}Folder:${RESET}   $DISPLAY_GROUP"
echo -e "   ${CYAN}Path:${RESET}     $PROJECT_PATH"
echo -e "   ${CYAN}Remote:${RESET}   claude --remote-control '$PROJECT_NAME' (session name)"
echo -e "   ${CYAN}Skill:${RESET}    /publish → push to GitHub when ready"
echo ""
