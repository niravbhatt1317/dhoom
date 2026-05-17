Scaffold a new dhoom project: React + TypeScript + Vite + Tailwind CSS v4, with CLAUDE.md, a /publish skill, git init, and a remote-control Claude session.

Read ~/.dhoom/config if it exists to find PROJECTS_ROOT (default: ~/Claude-Projects).

---

## Step 1 — Project name

Ask the user: "What are we calling this thing?"

Sanitize the input into a slug: lowercase, replace non-alphanumeric chars with hyphens, collapse consecutive hyphens, strip leading/trailing hyphens.

Show the slug and confirm before continuing.

---

## Step 2 — Group folder

Read PROJECTS_ROOT from ~/.dhoom/config, or default to ~/Claude-Projects.

If PROJECTS_ROOT doesn't exist, tell the user to run install.sh first and stop.

Scan PROJECTS_ROOT for immediate subdirectories. Skip: .manager, .claude, node_modules, .git.

If no subfolders exist, ask the user to name their first one, create it with mkdir, and use it.

Present the folders numbered. Add a "+ New folder" option at the end. Ask which to use.

---

## Step 3 — Scaffold Vite project

```bash
cd <PROJECTS_ROOT>/<group>/
echo y | npm create vite@latest <slug> -- --template react-ts --yes
```

Tell the user this may take a minute.

---

## Step 4 — Install dependencies

```bash
cd <PROJECTS_ROOT>/<group>/<slug>/
npm install
npm install -D tailwindcss @tailwindcss/vite
```

Run sequentially. Inform the user after each one finishes.

---

## Step 5 — Configure Tailwind v4

Rewrite `vite.config.ts`:
```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
```

Replace `src/index.css` with:
```css
@import "tailwindcss";
```

---

## Step 6 — Create CLAUDE.md

Create `CLAUDE.md` at the project root. Derive the display name by title-casing the slug (hyphens → spaces, capitalize each word):

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

Create `.claude/commands/publish.md` inside the project:

```
Push this project to a new GitHub repository.

Steps:
1. Check git status — if uncommitted changes exist, ask whether to commit first.
2. Ask: public or private repo?
3. Confirm the repo name (default: current directory name).
4. Run: gh repo create <name> --<public|private> --source=. --remote=origin --push
5. Show the new repo URL.

If `gh` is not authenticated, tell the user to run `gh auth login` first.
If remote "origin" already exists, skip creation and run: git push -u origin main
```

---

## Step 8 — Git init

```bash
git init -q
git add .
git commit -q -m "chore: initial React + TS + Vite + Tailwind v4 setup"
```

---

## Step 9 — Notify Project Manager (if running)

```bash
curl -s http://localhost:3030/api/projects > /dev/null 2>&1 || true
```

This is a no-op if no Project Manager is running.

---

## Step 10 — Open Claude with Remote Control

```bash
osascript \
  -e "tell application \"Terminal\" to do script \"cd '<project_path>' && claude --remote-control '<slug>' '.'\"" \
  -e "tell application \"Terminal\" to activate"
```

If osascript fails (non-macOS), tell the user to run: `cd '<project_path>' && claude --remote-control '<slug>'`

---

## Done

Tell the user:
- **Project:** display name
- **Folder:** group name
- **Path:** full absolute path
- **Remote control:** `claude --remote-control '<slug>'` to reconnect from any device
- **Tip:** type `/publish` in the new Claude session to push to GitHub when ready
