#Requires -Version 5.1
# dhoom installer for Windows
$ErrorActionPreference = 'Stop'

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

$ESC = [char]27
$ansi = $env:WT_SESSION -or $env:TERM_PROGRAM -or ($PSVersionTable.PSVersion.Major -ge 7) -or $env:ANSICON
if ($ansi) {
    $G = "$ESC[0;32m"; $Y = "$ESC[1;33m"; $C = "$ESC[0;36m"
    $B = "$ESC[1m"; $D = "$ESC[2m"; $R = "$ESC[0;31m"; $X = "$ESC[0m"
} else { $G=$Y=$C=$B=$D=$R=$X='' }

function ok($msg)   { Write-Host ($G + [char]0x2713 + $X + ' ' + $msg) }
function warn($msg) { Write-Host ($Y + '! ' + $X + $msg) }
function step($msg) { Write-Host (''); Write-Host ($C + $B + '→ ' + $X + $msg) }

Write-Host ''
Write-Host ("${B}💥 dhoom — Windows installer${X}")
Write-Host ("${C}────────────────────────────${X}")
Write-Host ("${D}  Sets up your projects folder, Claude skill, and PowerShell function.${X}")

# ── Step 1: Projects root ──────────────────────────────────────────────────────
step 'Where do you want to store your projects?'
Write-Host ("   ${D}This is the folder dhoom will create all your projects inside.${X}")
$defaultRoot = Join-Path $HOME 'Claude-Projects'
$inputRoot = Read-Host "   Path [$defaultRoot]"
if ([string]::IsNullOrWhiteSpace($inputRoot)) { $inputRoot = $defaultRoot }
$PROJECTS_ROOT = $inputRoot

if (-not (Test-Path $PROJECTS_ROOT)) {
    Write-Host ''
    Write-Host ("   ${D}$PROJECTS_ROOT doesn't exist yet.${X}")
    $confirm = Read-Host '   Create it? [Y/n]'
    if ([string]::IsNullOrWhiteSpace($confirm) -or $confirm -match '^[Yy]') {
        New-Item -ItemType Directory -Path $PROJECTS_ROOT -Force | Out-Null
        ok "Created $PROJECTS_ROOT"

        Write-Host ''
        Write-Host ("   ${D}Want to create any starter folders inside it?${X}")
        Write-Host ("   ${D}(e.g. Personal,Work — comma-separated, or Enter to skip)${X}")
        $starterInput = Read-Host '   →'
        if (-not [string]::IsNullOrWhiteSpace($starterInput)) {
            foreach ($s in ($starterInput -split ',')) {
                $folder = $s.Trim()
                if ([string]::IsNullOrEmpty($folder)) { continue }
                New-Item -ItemType Directory -Path (Join-Path $PROJECTS_ROOT $folder) -Force | Out-Null
                ok "Created folder: $folder"
            }
        }
    } else {
        Write-Host ("   ${R}✗ Cannot continue without a projects folder.${X}")
        exit 1
    }
} else {
    ok "Found existing projects folder: $PROJECTS_ROOT"
}

# ── Step 2: Save config ────────────────────────────────────────────────────────
step 'Saving config'
$configDir = Join-Path $HOME '.dhoom'
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
@"
# dhoom config — edit anytime
`$PROJECTS_ROOT = "$PROJECTS_ROOT"
"@ | Set-Content (Join-Path $configDir 'config.ps1') -Encoding UTF8
ok 'Config saved to ~/.dhoom/config.ps1'

# ── Step 3: Install Claude skill ───────────────────────────────────────────────
step 'Installing /dhoom Claude skill'
$claudeCommands = Join-Path $HOME '.claude\commands'
New-Item -ItemType Directory -Path $claudeCommands -Force | Out-Null
Copy-Item (Join-Path $SCRIPT_DIR '.claude\commands\dhoom.md') (Join-Path $claudeCommands 'dhoom.md') -Force
ok 'Skill installed → type /dhoom in any Claude Code session'

# ── Step 4: Add function to PowerShell profile ────────────────────────────────
step 'Adding dhoom function to PowerShell profile'

# Ensure profile file exists
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
$fnLine = "function dhoom { & `"$SCRIPT_DIR\dhoom.ps1`" @args }"

if ($profileContent -and $profileContent -match 'function dhoom') {
    warn 'dhoom function already exists in PowerShell profile — skipping'
} else {
    Add-Content $PROFILE "`n# dhoom — project scaffold tool`n$fnLine"
    ok "Function added to $PROFILE"
}

# ── Done ───────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host ("${G}${B}All set! Here's what you've got:${X}")
Write-Host ("   ${C}Projects root:${X}  $PROJECTS_ROOT")
Write-Host ("   ${C}Claude skill:${X}   /dhoom  (in any Claude Code session)")
Write-Host ("   ${C}Terminal command:${X} dhoom   (after restarting PowerShell)")
Write-Host ''
Write-Host ("${D}  Restart PowerShell (or run: . `$PROFILE) then type ${B}dhoom${X}${D} to create your first project.${X}")
Write-Host ''
