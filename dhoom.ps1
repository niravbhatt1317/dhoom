#Requires -Version 5.1
# dhoom — scaffold a new React + TS + Vite + Tailwind project (Windows / PowerShell)
$ErrorActionPreference = 'Stop'

# ── Config ─────────────────────────────────────────────────────────────────────
$configPath = Join-Path $HOME '.dhoom\config.ps1'
$script:PROJECTS_ROOT = Join-Path $HOME 'Claude-Projects'
if (Test-Path $configPath) { . $configPath }

# ── ANSI colours (Windows Terminal, VS Code, PowerShell 7+) ───────────────────
$ESC = [char]27
$script:ansi = $env:WT_SESSION -or $env:TERM_PROGRAM -or
               ($PSVersionTable.PSVersion.Major -ge 7) -or $env:ANSICON

if ($script:ansi) {
    $R = "$ESC[0;31m"; $G = "$ESC[0;32m"; $Y = "$ESC[1;33m"
    $C = "$ESC[0;36m"; $B = "$ESC[1m";    $D = "$ESC[2m"; $X = "$ESC[0m"
    $UP = "$ESC[1A"
} else {
    $R=$G=$Y=$C=$B=$D=$X=$UP=''
}

function ok($msg)   { Write-Host ($G + [char]0x2713 + $X + ' ' + $msg) }
function warn($msg) { Write-Host ($Y + '!' + $X + ' ' + $msg) }
function die($msg)  { Write-Host ($R + [char]0x2717 + $X + ' ' + $msg); exit 1 }

# ── Sanitise project name ──────────────────────────────────────────────────────
function Sanitize-Name($raw) {
    $s = $raw.ToLower()
    $s = $s -replace '[^a-z0-9]', '-'
    $s = $s -replace '-+', '-'
    $s = $s.Trim('-')
    return $s
}

# ── Fun install data ───────────────────────────────────────────────────────────
$SPINNER = [char[]]@(0x280B,0x2819,0x2839,0x2838,0x283C,0x2834,0x2826,0x2827,0x2807,0x280F)
$MSGS = @(
    'Downloading the entire internet...'
    'node_modules: *laughs in 300MB*'
    'Convincing npm to behave...'
    'React is judging your future code...'
    'Bribing the compiler with coffee...'
    'TypeScript side-eyeing your types already'
    '99 little bugs in the code, 99 little bugs...'
    'npm: 22% JavaScript, 78% philosophy'
    'Counting Tailwind classes... still counting...'
    'Your node_modules will outlive the sun'
    'Installing excellence. Please hold.'
    'A tree is planted to offset every npm install'
)
$LATE_MSGS = @(
    'Any second now, we promise...'
    'Still going... but nearly there!'
    'npm is taking its sweet time.'
    'Almost done. Probably.'
    'Just a liiittle bit longer...'
    "It's not frozen. We checked."
    'npm is buffering. Like YouTube in 2008.'
    'Good things take time. Great things take npm.'
    'Patience is a virtue. npm is testing yours.'
)
$JOKES = @(
    'Why do Java devs wear glasses?|Because they don''t C#.'
    'A SQL query walks into a bar...|...asks two tables: Can I join you?'
    'Why do programmers prefer dark mode?|Light attracts bugs.'
    'I had a joke about recursion...|...but first, I had a joke about recursion.'
)
$PHASE_LABELS = @('Scaffold', 'npm install', 'Tailwind')
$PHASE_STATUS = @(0, 0, 0)   # 0=pending 1=running 2=done

function Get-PhaseBar {
    $bar = ''
    for ($j = 0; $j -lt 3; $j++) {
        $lbl = $PHASE_LABELS[$j]
        switch ($PHASE_STATUS[$j]) {
            2 { $bar += "  ${G}[" + [char]0x2713 + "]${X} $lbl" }
            1 { $bar += "  ${C}[" + [char]0x25CF + "]${X} $lbl" }
            default { $bar += "  ${D}[ ] $lbl${X}" }
        }
    }
    return $bar
}

function Invoke-Fun {
    param([int]$PhaseIdx, [string]$Label, [int]$JokeIdx, [int]$Estimate, [string]$CmdLine)

    # Flash the joke
    $parts = $JOKES[$JokeIdx] -split '\|'
    Write-Host ''
    Write-Host ("  ${D}" + $parts[0] + "${X}")
    Write-Host ("  ${Y}${B}" + $parts[1] + "${X}")
    Start-Sleep 2

    # Phase bar
    $PHASE_STATUS[$PhaseIdx] = 1
    Write-Host ''
    if ($script:ansi) { Write-Host -NoNewline ($UP + "`r" + (Get-PhaseBar) + "  `n") }

    # Launch process via cmd /c so .cmd extensions and PATH work
    $psi = [System.Diagnostics.ProcessStartInfo]::new('cmd.exe', "/c $CmdLine")
    $psi.WorkingDirectory = (Get-Location).Path
    $psi.UseShellExecute  = $false
    $psi.RedirectStandardInput  = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.StandardInput.WriteLine('y')
    $proc.StandardInput.Close()

    $start = [DateTime]::Now
    $i = $mi = $tick = $lmi = $ltick = 0

    while (-not $proc.HasExited) {
        $elapsed = [int]([DateTime]::Now - $start).TotalSeconds
        $frame   = $SPINNER[$i % 10]

        if ($elapsed -lt $Estimate) {
            $msg   = $MSGS[$mi]
            $timer = "${D}~$($Estimate - $elapsed)s left${X}"
            $tick++
            if ($tick -ge 20) { $tick = 0; $mi = ($mi + 1) % $MSGS.Count }
        } else {
            $msg   = $LATE_MSGS[$lmi]
            $timer = "${Y}${elapsed}s · running long${X}"
            $ltick++
            if ($ltick -ge 25) { $ltick = 0; $lmi = ($lmi + 1) % $LATE_MSGS.Count }
        }

        $line = "`r  ${C}$frame${X}  ${B}$($Label.PadRight(18))${X}  ${D}·${X}  ${Y}$msg${X}  $timer    "
        Write-Host -NoNewline $line
        $i++
        Start-Sleep -Milliseconds 100
    }
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    $elapsed  = [int]([DateTime]::Now - $start).TotalSeconds

    Write-Host -NoNewline ("`r" + ' ' * 80 + "`r")   # clear spinner line

    $PHASE_STATUS[$PhaseIdx] = 2
    if ($script:ansi) { Write-Host -NoNewline ($UP + "`r" + (Get-PhaseBar) + "  `n") }

    if ($exitCode -eq 0) { ok "$Label  [${elapsed}s]" }
    else                  { die "$Label failed after ${elapsed}s" }
}

# ── Step 1: Project name ───────────────────────────────────────────────────────
Write-Host ''
Write-Host ("${B}💥 dhoom — what are we cooking today?${X}")
Write-Host ("${C}──────────────────────────────────────${X}")
Write-Host ("${D}  New project. Clean slate. Let's build something.${X}")

$PROJECT_NAME = ''
while ($true) {
    Write-Host ''
    Write-Host ("${B}  What are we calling this thing?${X}")
    Write-Host ("${D}  (spaces & special chars → auto-fixed)${X}")
    Write-Host ''
    $RAW_NAME = Read-Host '  →'
    if ([string]::IsNullOrWhiteSpace($RAW_NAME)) { warn 'Give it a name — anything works.'; continue }

    $PROJECT_NAME = Sanitize-Name $RAW_NAME
    if ([string]::IsNullOrEmpty($PROJECT_NAME)) { warn 'That name produces an empty slug. Try something else.'; continue }

    if ($RAW_NAME -ne $PROJECT_NAME) { Write-Host ("  ${D}slug:${X} ${B}$PROJECT_NAME${X}") }

    $lock = Read-Host '  Lock it in? [Y/n]'
    if ([string]::IsNullOrWhiteSpace($lock) -or $lock -match '^[Yy]') { break }
}

# ── Step 2: Group folder ───────────────────────────────────────────────────────

# Customise these for your own folders:
function Get-FolderDisplayName($name) {
    # Example:  'Work'     { return 'Work' }
    return $name
}
function Get-FolderDesc($name) {
    # Example:  'Work'     { return 'Client projects and day-job work' }
    return ''
}

Write-Host ''
Write-Host ("${B}  Where does this one live?${X}")
Write-Host ("${D}  Pick a home for your project.${X}")

if (-not (Test-Path $PROJECTS_ROOT)) {
    Write-Host ''
    warn "Projects folder not found at $PROJECTS_ROOT"
    Write-Host ("  ${D}Run ${B}.\install.ps1${X}${D} to set it up, or create the folder manually.${X}")
    exit 1
}

# Collect subfolders
$RAW_FOLDERS = @(Get-ChildItem -Path $PROJECTS_ROOT -Directory |
    Where-Object { $_.Name -notmatch '^(\.manager|\.claude|node_modules|\.git)$' } |
    Select-Object -ExpandProperty Name)

# Edge case: no subfolders yet
if ($RAW_FOLDERS.Count -eq 0) {
    Write-Host ''
    warn "No folders found in $PROJECTS_ROOT yet."
    Write-Host ("  ${D}What do you want to call your first one? (e.g. Personal, Work)${X}")
    $first = Read-Host '  →'
    $first = ($first.Trim())
    if ([string]::IsNullOrEmpty($first)) { die 'Need at least one folder to continue.' }
    New-Item -ItemType Directory -Path (Join-Path $PROJECTS_ROOT $first) -Force | Out-Null
    ok "Created folder: $first"
    $RAW_FOLDERS = @($first)
}

$FOLDERS = $RAW_FOLDERS

Write-Host ''
for ($idx = 0; $idx -lt $FOLDERS.Count; $idx++) {
    $g    = $FOLDERS[$idx]
    $disp = Get-FolderDisplayName $g
    $desc = Get-FolderDesc $g
    Write-Host ("  ${C}${B}$($idx+1))${X} ${B}$disp${X}")
    if (-not [string]::IsNullOrEmpty($desc)) { Write-Host ("     ${D}$desc${X}") }
    Write-Host ''
}
$NEW_OPT = $FOLDERS.Count + 1
Write-Host ("  ${C}${B}$NEW_OPT)${X} ${B}+ New folder${X}")
Write-Host ("     ${D}Create a brand-new home for this project${X}")

$GROUP = ''; $DISPLAY_GROUP = ''
while ($true) {
    $choice = Read-Host "`n  →"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }

    if ($choice -match '^\d+$') {
        $n = [int]$choice
        if ($n -ge 1 -and $n -lt $NEW_OPT) {
            $GROUP = $FOLDERS[$n - 1]
            $DISPLAY_GROUP = Get-FolderDisplayName $GROUP
            ok "Dropping it in $DISPLAY_GROUP."
            break
        }
        if ($n -eq $NEW_OPT) {
            $newFolder = (Read-Host '  Name the new folder').Trim()
            if ([string]::IsNullOrEmpty($newFolder)) { warn 'Needs a name.'; continue }
            $GROUP = $newFolder; $DISPLAY_GROUP = $newFolder
            New-Item -ItemType Directory -Path (Join-Path $PROJECTS_ROOT $GROUP) -Force | Out-Null
            ok "New folder ready: $GROUP"
            break
        }
    }
    warn "Pick a number from 1 to $NEW_OPT."
}

$PROJECT_PATH = Join-Path $PROJECTS_ROOT $GROUP $PROJECT_NAME

if (Test-Path $PROJECT_PATH) { die "A project already exists at $PROJECT_PATH" }

# ── Steps 3–5: Install the stack ──────────────────────────────────────────────
Write-Host ''
Write-Host ("${B}  Firing up the kitchen…${X}")
Write-Host ("${D}  Three steps. Some bad jokes. Bear with us.${X}")

Push-Location (Join-Path $PROJECTS_ROOT $GROUP)
Invoke-Fun 0 'Scaffold' 0 15 "echo y | npm create vite@latest `"$PROJECT_NAME`" -- --template react-ts --yes"

Set-Location $PROJECT_PATH
Invoke-Fun 1 'npm install' 1 45 'npm install'
Invoke-Fun 2 'Tailwind v4' 2 25 'npm install -D tailwindcss @tailwindcss/vite'
Pop-Location

# ── Configure Tailwind v4 ──────────────────────────────────────────────────────
@'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
'@ | Set-Content (Join-Path $PROJECT_PATH 'vite.config.ts') -Encoding UTF8

'@import "tailwindcss";' | Set-Content (Join-Path $PROJECT_PATH 'src\index.css') -Encoding UTF8

ok 'Tailwind v4 configured'

# ── CLAUDE.md ──────────────────────────────────────────────────────────────────
$DISPLAY_NAME = ($PROJECT_NAME -replace '-', ' ') -replace '\b(\w)', { $_.Value.ToUpper() }

@"
**Instruction (act on this immediately):** The user just created this project with dhoom. Greet them warmly, tell them the stack is ready, and ask what they want to build or explore today. Get even a rough idea, then suggest a first step to start building it.

# $DISPLAY_NAME

## Tech Stack
- React + TypeScript
- Vite
- Tailwind CSS v4

## Goal
_Not set yet — ask the user._

## Notes
"@ | Set-Content (Join-Path $PROJECT_PATH 'CLAUDE.md') -Encoding UTF8

ok 'CLAUDE.md created'

# ── /publish skill ─────────────────────────────────────────────────────────────
$cmdDir = Join-Path $PROJECT_PATH '.claude\commands'
New-Item -ItemType Directory -Path $cmdDir -Force | Out-Null

@'
Push this project to a new GitHub repository.

Steps:
1. Check git status — if there are uncommitted changes, ask whether to commit them first with a short message.
2. Ask: should the repo be public or private?
3. Confirm the repo name (default: current directory name).
4. Run: gh repo create <name> --<public|private> --source=. --remote=origin --push
5. Show the new repo URL when done.

If `gh` is not authenticated, tell the user to run `gh auth login` first.
If a remote named "origin" already exists, skip repo creation and just run: git push -u origin main
'@ | Set-Content (Join-Path $cmdDir 'publish.md') -Encoding UTF8

ok '/publish skill ready'

# ── Git init ───────────────────────────────────────────────────────────────────
Set-Location $PROJECT_PATH
& git init -q
& git add .
& git commit -q -m 'chore: initial React + TS + Vite + Tailwind v4 setup'
ok 'Git initialized with initial commit'

# ── Notify Project Manager (if running) ───────────────────────────────────────
try { Invoke-WebRequest -Uri 'http://localhost:3030/api/projects' -UseBasicParsing -TimeoutSec 2 | Out-Null } catch {}

# ── Open Claude with Remote Control ───────────────────────────────────────────
$opened = $false

# Try Windows Terminal first
$wtPath = Get-Command wt -ErrorAction SilentlyContinue
if ($wtPath) {
    try {
        $cmd = "pwsh -NoExit -Command `"Set-Location '$PROJECT_PATH'; claude --remote-control '$PROJECT_NAME' '.'`""
        Start-Process wt -ArgumentList $cmd
        $opened = $true
    } catch {}
}

# Fall back to PowerShell window
if (-not $opened) {
    try {
        $cmd = "-NoExit -Command `"Set-Location '$PROJECT_PATH'; claude --remote-control '$PROJECT_NAME' '.'`""
        $ps = Get-Command pwsh -ErrorAction SilentlyContinue
        Start-Process ($ps ? 'pwsh' : 'powershell') -ArgumentList $cmd
        $opened = $true
    } catch {}
}

if (-not $opened) {
    warn "Could not open a new terminal automatically."
    Write-Host ("  ${D}Run manually: cd `"$PROJECT_PATH`" && claude --remote-control `"$PROJECT_NAME`"${X}")
}

# ── Done ───────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host ("${G}${B}💥 dhoom! Go cook something great.${X}")
Write-Host ("   ${C}Project:${X}  $DISPLAY_NAME")
Write-Host ("   ${C}Folder:${X}   $DISPLAY_GROUP")
Write-Host ("   ${C}Path:${X}     $PROJECT_PATH")
Write-Host ("   ${C}Remote:${X}   claude --remote-control '$PROJECT_NAME' (session name)")
Write-Host ("   ${C}Skill:${X}    /publish -> push to GitHub when ready")
Write-Host ''
