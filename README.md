# dhoom

One command. Full project. Ready to build.

`dhoom` scaffolds a React + TypeScript + Vite + Tailwind CSS v4 project with a fun install experience, a CLAUDE.md that makes Claude ask what you want to build, a `/publish` skill for pushing to GitHub, and a remote-control Claude session — all in under 2 minutes.

```
💥 dhoom — what are we cooking today?
──────────────────────────────────────

  What are we calling this thing?

  → my cool app
  slug: my-cool-app
  Lock it in? [Y/n]
```

---

## Quick install

```bash
git clone https://github.com/niravbhatt/dhoom.git
cd dhoom
./install.sh
source ~/.zshrc
```

`install.sh` will:
- Ask where you want to store your projects (default: `~/Claude-Projects`)
- Create that folder and any starter subfolders you name
- Install the `/dhoom` Claude Code skill globally
- Add a `dhoom` shell alias to `~/.zshrc`

---

## Usage

**From the terminal:**
```bash
dhoom
```

**From inside any Claude Code session:**
```
/dhoom
```

Both do the exact same thing. The Claude skill is handy when you're already in a session and don't want to open a new terminal.

---

## What you get

Each `dhoom` run produces a complete project:

| Thing | What it is |
|-------|-----------|
| React + TS + Vite | Full Vite scaffold via `npm create vite@latest` |
| Tailwind CSS v4 | Installed and wired into Vite via `@tailwindcss/vite` — no config file needed |
| `CLAUDE.md` | Makes Claude greet you and ask what you want to build when the session opens |
| `/publish` skill | Type `/publish` in Claude to push the project to a new GitHub repo |
| Git repo | `git init` + initial commit, ready to push |
| Remote control | Opens with `claude --remote-control` so you can connect from any device |

---

## Customise folder display names

By default dhoom shows your folders exactly as named on disk. To add friendly names and descriptions, edit the two functions near the top of `dhoom.sh`:

```bash
folder_display_name() {
  case "$1" in
    work)     echo "Work" ;;
    personal) echo "Personal" ;;
    *)        echo "$1" ;;   # fallback: show folder name as-is
  esac
}

folder_desc() {
  case "$1" in
    work)     echo "Client projects and day-job work" ;;
    personal) echo "Side projects and experiments" ;;
    *)        echo "" ;;
  esac
}
```

---

## Change your projects folder later

Edit `~/.dhoom/config`:

```bash
PROJECTS_ROOT="/path/to/your/projects"
```

---

## Requirements

| Tool | Why |
|------|-----|
| Node + npm | Runs the Vite scaffold and installs packages |
| git | Initialises the repo and makes the initial commit |
| [Claude Code CLI](https://claude.ai/code) | Opens the new project session with remote control |
| macOS | The auto-open Terminal step uses `osascript` — on Linux/Windows you'll get a manual `cd` command to run instead |
| `gh` (optional) | Only needed if you use the `/publish` skill to push to GitHub |

---

## Project structure

```
dhoom/
├── dhoom.sh                    # bash scaffold script
├── install.sh                  # first-time setup
├── .claude/
│   └── commands/
│       └── dhoom.md            # Claude Code /dhoom skill
└── README.md
```
