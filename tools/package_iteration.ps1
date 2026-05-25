<#
Package a snapshot of the Godot project at the current iteration boundary.

Usage:
    .\tools\package_iteration.ps1 -Id "0.4" -Name "stage0-discipline" -Description "Stage 0 complete: skeleton, seeded RNG, commands, run log."

Produces:
    builds/iter-<Id>-<Name>-source.zip   (always - source archive, .godot/ excluded)
    builds/iter-<Id>-<Name>-win64.exe    (best-effort - requires Godot export templates installed)
    builds/INDEX.md                      (running index of all packaged iterations)

Source zip can be opened by:
    1. Unzip somewhere
    2. Open Godot 4.6+ -> Import -> point at the extracted folder's project.godot
    3. F5 to play
#>
param(
    [Parameter(Mandatory=$true)][string]$Id,
    [Parameter(Mandatory=$true)][string]$Name,
    [string]$Description = ""
)

$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root "duelyst-td"
$builds = Join-Path $root "builds"
New-Item -ItemType Directory -Force -Path $builds | Out-Null

$slug = "iter-$Id-$Name"
$zipPath = Join-Path $builds "$slug-source.zip"
$exePath = Join-Path $builds "$slug-win64.exe"

Write-Host "Packaging $slug ..."

# ---- Source zip ----
$stage = Join-Path $env:TEMP "package_iter_$(Get-Random)"
New-Item -ItemType Directory -Force -Path $stage | Out-Null
try {
    # robocopy excludes .godot/ (editor cache) and import cache; copies everything else
    $rc = robocopy $project $stage /MIR /XD .godot /NJH /NJS /NDL /NFL /NP
    # robocopy exit codes 0-7 are success
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zipPath -CompressionLevel Optimal
    $zipSize = (Get-Item $zipPath).Length / 1MB
    Write-Host ("  source zip:  {0,7:N1} MB  ->  builds/{1}-source.zip" -f $zipSize, $slug)
} finally {
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
}

# ---- Optional .exe export ----
$godot = 'E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
$exeOk = $false
$exeNote = "(skipped - Godot not found at expected path)"
if (Test-Path $godot) {
    Write-Host "  attempting .exe export ..."
    if (Test-Path $exePath) { Remove-Item $exePath -Force }
    # Run Godot export. Discard verbose savepack chatter via | Out-Null
    # (do NOT use *> $null — that breaks file write timing).
    & $godot --headless --path $project --export-debug "Windows Desktop" $exePath | Out-Null
    # Godot may return before the OS has finished flushing the (~100 MB) write.
    $waited = 0
    while (-not (Test-Path -LiteralPath $exePath) -and $waited -lt 30000) {
        Start-Sleep -Milliseconds 200
        $waited += 200
    }
    if (Test-Path -LiteralPath $exePath) {
        $exeOk = $true
        $exeSize = (Get-Item $exePath).Length / 1MB
        Write-Host ("  windows exe: {0,7:N1} MB  ->  builds/{1}-win64.exe" -f $exeSize, $slug)
    } else {
        $exeNote = "(export failed - likely missing export templates; install via Godot Editor > Editor > Manage Export Templates)"
        Write-Host "  windows exe: SKIPPED $exeNote"
    }
}

# ---- INDEX.md update ----
$indexPath = Join-Path $builds "INDEX.md"
if (-not (Test-Path $indexPath)) {
    @"
# Build Index

Local snapshots of the project at each iteration boundary. Each entry is
a self-contained zip you can extract and open in Godot to play that
iteration's state. Where available, a Windows .exe is included too.

To re-package the current state from a fresh iteration:
``````powershell
.\tools\package_iteration.ps1 -Id "X.X" -Name "short-slug" -Description "What landed."
``````

See ``docs/debug_guide.md`` for per-iteration test checklists.

---
"@ | Set-Content -Path $indexPath -Encoding UTF8
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$exeLine = if ($exeOk) { "- Windows: ``$slug-win64.exe``" } else { "- Windows: $exeNote" }
$entry = @"

## $Id - $Name  _($timestamp)_

$Description

- Source: ``$slug-source.zip``
$exeLine
"@
Add-Content -Path $indexPath -Value $entry -Encoding UTF8

Write-Host ""
Write-Host "Done. See builds/INDEX.md for the full list."
# Reset $LASTEXITCODE so the script reports success (Godot export tends to leave it non-zero).
$global:LASTEXITCODE = 0
exit 0
