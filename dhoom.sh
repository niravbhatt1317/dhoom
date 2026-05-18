#!/usr/bin/env bash
# dhoom — scaffold a new React + TS + Vite + Tailwind project
set -euo pipefail

PROJECTS_ROOT="$HOME/Claude-Projects"
MANAGER_CONFIG="$PROJECTS_ROOT/.manager/config.json"

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

trap 'printf "\033[?25h"; stty sane 2>/dev/null || true' EXIT INT TERM
info()    { echo -e "${CYAN}→${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}!${RESET} $*"; }
die()     { echo -e "${RED}✗${RESET} $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

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
      # Before estimate: show regular funny messages + countdown
      msg="${MSGS[$mi]}"
      local remaining=$(( estimate - elapsed ))
      timer="${DIM}~${remaining}s left${RESET}"
      tick=$(( tick + 1 ))
      if (( tick >= 20 )); then
        tick=0
        mi=$(( (mi + 1) % ${#MSGS[@]} ))
      fi
    else
      # Over estimate: flip to "overtime" messages + elapsed
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

# Friendly display name for each known folder (bash 3.2 safe — no associative arrays)
folder_display_name() {
  case "$1" in
    Service-ops)       echo "Service Ops" ;;
    Observe-ops)       echo "Observe Ops" ;;
    Mtdt-experiments)  echo "Motadata Experiments" ;;
    Personal)          echo "Personal" ;;
    *)                 echo "$1" ;;
  esac
}

# One-liner description for each known folder
folder_desc() {
  case "$1" in
    Service-ops)       echo "ITSM design — ticket workflows, service desk interfaces, support tooling" ;;
    Observe-ops)       echo "IT monitoring design — AI Insight Hub, observability dashboards, alert interfaces" ;;
    Mtdt-experiments)  echo "Cross-product work — design systems, shared components, exploratory R&D" ;;
    Personal)          echo "Just for you — side projects, experiments, anything that gives you wings" ;;
    *)                 echo "" ;;
  esac
}

# Collect group folders — glob expansion avoids ls alias / word-splitting issues
[[ -d "$PROJECTS_ROOT" ]] || die "Claude-Projects folder not found at $PROJECTS_ROOT"
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
[[ ${#RAW_FOLDERS[@]} -eq 0 ]] && die "No group folders found in $PROJECTS_ROOT"

# Sort into preferred order: known folders first, then any extras alphabetically
PREFERRED_ORDER=("Service-ops" "Observe-ops" "Mtdt-experiments" "Personal")
FOLDERS=()
for preferred in "${PREFERRED_ORDER[@]}"; do
  for f in "${RAW_FOLDERS[@]}"; do
    [[ "$f" == "$preferred" ]] && FOLDERS+=("$f") && break
  done
done
for f in "${RAW_FOLDERS[@]}"; do
  found=0
  for preferred in "${PREFERRED_ORDER[@]}"; do
    [[ "$f" == "$preferred" ]] && found=1 && break
  done
  if [[ "$found" == "0" ]]; then FOLDERS+=("$f"); fi
done

# Arrow-key picker ─────────────────────────────────────────────────────────────
PICKER_ITEMS=("${FOLDERS[@]}" "__NEW__")
PICKER_COUNT=${#PICKER_ITEMS[@]}
PICKER_LINES=$(( PICKER_COUNT * 3 ))  # each item: blank + name + desc

_render_picker() {
  local sel=$1 i=0 item display desc
  for item in "${PICKER_ITEMS[@]}"; do
    if [[ "$item" == "__NEW__" ]]; then
      display="${BOLD}+ New folder${RESET}"
      desc="Create a brand-new home for this project"
    else
      display="${BOLD}$(folder_display_name "$item")${RESET}"
      desc="$(folder_desc "$item")"
    fi
    echo ""
    if [[ $i -eq $sel ]]; then
      echo -e "  ${CYAN}→${RESET} ${display}"
    else
      echo -e "    ${display}"
    fi
    echo -e "      ${DIM}${desc}${RESET}"
    i=$(( i + 1 ))
  done
}

_KEY=""
_read_key() {
  _KEY=""
  local char="" rest=""
  IFS= read -r -s -n1 char || true
  case "$char" in
    $'\033')
      # Read the next 2 bytes together — avoids timing issues with separate reads
      # bash 3.2 (macOS default) only accepts integer timeouts; 1s is fine since
      # the bytes after ESC arrive instantly when an arrow key is pressed
      IFS= read -r -s -n2 -t 1 rest || true
      case "$rest" in
        '[A') _KEY="UP" ;;
        '[B') _KEY="DOWN" ;;
      esac
      ;;
    '') _KEY="ENTER" ;;
  esac
}

SEL=0
_PICK_ROW=1
GROUP=""
DISPLAY_GROUP=""

_picker_update() {
  # Rewrite only the two name lines that changed (old → deselected, new → selected).
  # Item i's name line is at: _PICK_ROW + i*3 + 1
  local old_sel=$1 new_sel=$2
  local item row display

  item="${PICKER_ITEMS[$old_sel]}"
  row=$(( _PICK_ROW + old_sel * 3 + 1 ))
  [[ "$item" == "__NEW__" ]] && display="${BOLD}+ New folder${RESET}" \
    || display="${BOLD}$(folder_display_name "$item")${RESET}"
  printf "\033[%d;1H\033[2K" "$row"
  echo -e "    ${display}"

  item="${PICKER_ITEMS[$new_sel]}"
  row=$(( _PICK_ROW + new_sel * 3 + 1 ))
  [[ "$item" == "__NEW__" ]] && display="${BOLD}+ New folder${RESET}" \
    || display="${BOLD}$(folder_display_name "$item")${RESET}"
  printf "\033[%d;1H\033[2K" "$row"
  echo -e "  ${CYAN}→${RESET} ${display}"
}

echo ""
echo -e "${BOLD}  Where does this one live?${RESET}"
echo -e "${DIM}  ↑ ↓ to move  ·  Enter to select${RESET}"

# Pre-reserve space so terminal scrolling happens before the position query
_pi=0
while [[ $_pi -lt $PICKER_LINES ]]; do echo ""; _pi=$(( _pi + 1 )); done
printf "\033[%dA" "$PICKER_LINES"

# Query cursor row. stty -echo must come FIRST — without it the terminal
# echoes the response (e.g. ^[[16;1R) to the screen before read can read it.
_old_stty=$(stty -g 2>/dev/null)
stty -echo 2>/dev/null || true
printf '\033[6n'
IFS='[;' read -r -d 'R' _ _PICK_ROW _ 2>/dev/null || true
stty "$_old_stty" 2>/dev/null || true
[[ "$_PICK_ROW" =~ ^[0-9]+$ ]] || _PICK_ROW=1

printf '\033[?25l'   # hide cursor for the duration of the picker
_render_picker $SEL
_OLD_SEL=$SEL

# One loop handles navigation + the new-folder prompt.
# "Go back" clears only the lines below the list and falls through —
# no outer loop means the header is never reprinted.
while true; do
  _read_key
  case "$_KEY" in
    UP)
      _OLD_SEL=$SEL
      SEL=$(( (SEL - 1 + PICKER_COUNT) % PICKER_COUNT ))
      _picker_update $_OLD_SEL $SEL
      ;;
    DOWN)
      _OLD_SEL=$SEL
      SEL=$(( (SEL + 1) % PICKER_COUNT ))
      _picker_update $_OLD_SEL $SEL
      ;;
    ENTER)
      if [[ "${PICKER_ITEMS[$SEL]}" == "__NEW__" ]]; then
        while true; do
          printf "\033[%d;1H\033[J" $(( _PICK_ROW + PICKER_LINES ))
          echo ""
          printf "  ${BOLD}New folder name:${RESET} ${DIM}(empty → go back)${RESET}  → "
          IFS= read -r NEW_FOLDER
          [[ -z "$NEW_FOLDER" ]] && break              # go back to picker
          NEW_FOLDER=$(sanitize_name "$NEW_FOLDER")
          [[ -z "$NEW_FOLDER" ]] && continue           # invalid — prompt again
          GROUP="$NEW_FOLDER"
          DISPLAY_GROUP="$GROUP"
          mkdir -p "$PROJECTS_ROOT/$GROUP"
          success "New folder ready: $GROUP"
          break 2
        done
        # Clear prompt lines so picker area looks clean on return
        printf "\033[%d;1H\033[J" $(( _PICK_ROW + PICKER_LINES ))
      else
        GROUP="${PICKER_ITEMS[$SEL]}"
        DISPLAY_GROUP=$(folder_display_name "$GROUP")
        success "Dropping it in ${DISPLAY_GROUP}."
        break
      fi
      ;;
  esac
done
printf '\033[?25h'   # restore cursor

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

# ── Step 9: Notify Project Manager ────────────────────────────────────────────
# Projects under ~/Claude-Projects/ are auto-scanned — just trigger a refresh
curl -s http://localhost:3030/api/projects > /dev/null 2>&1 || true

# ── Step 10: Open Claude ───────────────────────────────────────────────────────
_CMD="cd '$PROJECT_PATH' && claude --remote-control '$PROJECT_NAME' '.'"
case "$OSTYPE" in
  darwin*)
    osascript \
      -e "tell application \"Terminal\" to do script \"$_CMD\"" \
      -e "tell application \"Terminal\" to activate" 2>/dev/null || \
      warn "Could not open Terminal automatically. Run: $_CMD"
    ;;
  linux*)
    if command -v gnome-terminal &>/dev/null; then
      gnome-terminal -- bash -c "$_CMD; exec bash" 2>/dev/null &
    elif command -v xterm &>/dev/null; then
      xterm -e "bash -c '$_CMD; exec bash'" 2>/dev/null &
    elif command -v konsole &>/dev/null; then
      konsole -e bash -c "$_CMD; exec bash" 2>/dev/null &
    else
      warn "Could not detect a terminal emulator. Run: $_CMD"
    fi
    ;;
  msys*|cygwin*)
    # Git Bash / Cygwin on Windows
    start cmd //k "$_CMD" 2>/dev/null || \
      warn "Could not open terminal. Run: $_CMD"
    ;;
  *)
    warn "Platform not supported for auto-open. Run: $_CMD"
    ;;
esac

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}💥 dhoom! Go cook something great.${RESET}"
echo -e "   ${CYAN}Project:${RESET}  $DISPLAY_NAME"
echo -e "   ${CYAN}Folder:${RESET}   $DISPLAY_GROUP"
echo -e "   ${CYAN}Path:${RESET}     $PROJECT_PATH"
echo -e "   ${CYAN}Remote:${RESET}   claude --remote-control '$PROJECT_NAME' (session name)"
echo -e "   ${CYAN}Skill:${RESET}    /publish → push to GitHub when ready"
echo ""
