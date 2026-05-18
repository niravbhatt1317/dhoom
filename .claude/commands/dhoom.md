Scaffold a new React + TypeScript + Vite + Tailwind CSS v4 project under ~/Claude-Projects/.

---

## Step 1 — Project name

Ask the user: "What are we calling this thing?"

Sanitize the input into a slug:
- Lowercase everything
- Replace any non-alphanumeric character with a hyphen
- Collapse consecutive hyphens into one
- Strip leading and trailing hyphens

Show the slug and confirm with the user before continuing.

---

## Step 2 — Group folder

Scan `~/Claude-Projects/` for immediate subdirectories. Skip: `.manager`, `.claude`, `node_modules`, `.git`.

Sort them in this preferred order (others go at the end):
1. Service-ops → **Service Ops** — ITSM design: ticket workflows, service desk interfaces, support tooling
2. Observe-ops → **Observe Ops** — IT monitoring: AI Insight Hub, observability dashboards, alert interfaces
3. Mtdt-experiments → **Motadata Experiments** — cross-product work: design systems, shared components, R&D
4. Personal → **Personal** — just for you: side projects, experiments, anything that gives you wings

Present the list with friendly names and one-line descriptions. Offer a "+ New folder" option at the end.

Ask the user to pick one. If they choose new folder, ask for a name, sanitize it, and `mkdir -p ~/Claude-Projects/<name>`.

> **Note:** When running as the `dhoom` bash script, this step uses an interactive arrow-key picker (↑ ↓ to move, Enter to select). When running as a Claude skill, present the list conversationally and let the user type their choice.

---

## Step 3 — Scaffold Vite project

**macOS / Linux / WSL / Git Bash:**
```bash
cd ~/Claude-Projects/<group>/
npm create vite@latest <slug> -- --template react-ts --yes
```

**Windows (PowerShell / cmd):**
```powershell
cd "$HOME\Claude-Projects\<group>"
npm create vite@latest <slug> -- --template react-ts --yes
```

Tell the user each step is running and may take a minute.

---

## Step 4 — Install dependencies

**macOS / Linux / WSL / Git Bash:**
```bash
cd ~/Claude-Projects/<group>/<slug>/
npm install
npm install -D tailwindcss @tailwindcss/vite
```

**Windows (PowerShell / cmd):**
```powershell
cd "$HOME\Claude-Projects\<group>\<slug>"
npm install
npm install -D tailwindcss @tailwindcss/vite
```

Run these sequentially. Inform the user as each finishes.

---

## Step 5 — Configure Tailwind v4

Rewrite `vite.config.ts` to:
```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
```

Replace `src/index.css` entirely with:
```css
@import "tailwindcss";
```

---

## Step 6 — Create CLAUDE.md

Create `CLAUDE.md` at the project root. Use the display name (title-cased from slug):

```
**Instruction (act on this immediately):** The user just created this project with dhoom. Greet them warmly, tell them the stack is ready, and ask what they want to build or explore today. Get even a rough idea, then suggest a first step to start building it.

# <Display Name>

## Tech Stack
- React + TypeScript
- Vite
- Tailwind CSS v4

## Goal
_Not set yet — ask the user._

## Notes
```

---

## Step 7 — Create /publish skill

Create `.claude/commands/publish.md` inside the new project:

```
Push this project to a new GitHub repository.

Steps:
1. Check git status — if there are uncommitted changes, ask whether to commit them first with a short message.
2. Ask: should the repo be public or private?
3. Confirm the repo name (default: current directory name).
4. Run: gh repo create <name> --<public|private> --source=. --remote=origin --push
5. Show the new repo URL when done.

If `gh` is not authenticated, tell the user to run `gh auth login` first.
If a remote named "origin" already exists, skip repo creation and just run: git push -u origin main
```

---

## Step 8 — Git init

**macOS / Linux / WSL / Git Bash:**
```bash
cd ~/Claude-Projects/<group>/<slug>/
git init -q
git add .
git commit -q -m "chore: initial React + TS + Vite + Tailwind v4 setup"
```

**Windows (PowerShell / cmd):**
```powershell
cd "$HOME\Claude-Projects\<group>\<slug>"
git init -q
git add .
git commit -q -m "chore: initial React + TS + Vite + Tailwind v4 setup"
```

---

## Step 9 — Notify Project Manager

**macOS / Linux / WSL / Git Bash:**
```bash
curl -s http://localhost:3030/api/projects > /dev/null 2>&1 || true
```

**Windows (PowerShell):**
```powershell
try { Invoke-WebRequest -Uri http://localhost:3030/api/projects -UseBasicParsing | Out-Null } catch {}
```

---

## Step 10 — Open Claude

Open a new terminal window at the project path and launch Claude. Use the command for the user's OS:

**macOS:**
```bash
osascript \
  -e "tell application \"Terminal\" to do script \"cd '$PROJECT_PATH' && claude\"" \
  -e "tell application \"Terminal\" to activate"
```

**Linux (gnome-terminal):**
```bash
gnome-terminal -- bash -c "cd '$PROJECT_PATH' && claude; exec bash" &
```

**Linux (xterm fallback):**
```bash
xterm -e "bash -c 'cd \"$PROJECT_PATH\" && claude; exec bash'" &
```

**Windows (PowerShell):**
```powershell
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$PROJECT_PATH'; claude"
```

**Windows (cmd):**
```cmd
start cmd /k "cd /d "%PROJECT_PATH%" && claude"
```

If the terminal can't be opened automatically, tell the user to run the following manually:
```
cd <PROJECT_PATH> && claude
```

---

## Done

Tell the user:
- **Project:** display name
- **Folder:** friendly group name
- **Path:** full path
- **Tip:** type `/publish` in the new session to push to GitHub when ready
