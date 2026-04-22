<#
.TITLE
    PS-CopyWithLog

.AUTHOR
    JBOrunon

.WRITTEN
    2026-04-21

.MODIFIED
    2026-04-21 — promoted from hardcoded script; added parameters, guards, log dir creation

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Copies a folder tree from source to destination with a progress bar and error log.

.DESCRIPTION
    Recursively copies all files and folders from Source to Destination. Logs errors
    to a timestamped file under C:\jb\logs\ (created if missing). Shows a progress bar
    with ETA. Files at the destination are overwritten if they already exist.
    Skips silently if the source is empty.

.REQUIRES
    PowerShell 5.1+, Windows (any)

.REPO
    https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Source,

    [Parameter(Mandatory)]
    [string]$Destination,

    [string]$LogDir = "C:\jb\logs"
)

# ---------------------------------------------------------------------------
# Validate source
# ---------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $Source)) {
    Write-Host "ERROR: Source path not found: $Source" -ForegroundColor Red
    exit 1
}

$items = Get-ChildItem -Path $Source -Recurse
$totalItems = $items.Count

if ($totalItems -eq 0) {
    Write-Host "Source folder is empty — nothing to copy." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# Prepare log file
# ---------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile   = Join-Path $LogDir "CopyLog-$timestamp.txt"

Add-Content -Path $logFile -Value "Copy started : $(Get-Date)"
Add-Content -Path $logFile -Value "Source       : $Source"
Add-Content -Path $logFile -Value "Destination  : $Destination"
Add-Content -Path $logFile -Value "Total items  : $totalItems"
Add-Content -Path $logFile -Value ""

# ---------------------------------------------------------------------------
# Copy
# ---------------------------------------------------------------------------
$counter   = 0
$startTime = Get-Date
$errors    = 0

foreach ($item in $items) {
    $counter++
    $percent     = [math]::Round(($counter / $totalItems) * 100, 2)
    $elapsed     = ((Get-Date) - $startTime).TotalSeconds
    $remaining   = if ($counter -gt 0) { ($elapsed / $counter) * ($totalItems - $counter) } else { 0 }

    Write-Progress -Activity "Copying files" `
                   -Status "$counter of $totalItems — $percent% complete" `
                   -PercentComplete $percent `
                   -SecondsRemaining $remaining

    try {
        $destPath = $item.FullName.Replace($Source, $Destination)
        if ($item.PSIsContainer) {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
        } else {
            Copy-Item -Path $item.FullName -Destination $destPath -Force
        }
    } catch {
        $errors++
        $msg = "ERROR: $($item.FullName) — $_"
        Add-Content -Path $logFile -Value $msg
        Write-Host $msg -ForegroundColor Red
    }
}

Write-Progress -Activity "Copying files" -Completed

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Add-Content -Path $logFile -Value ""
Add-Content -Path $logFile -Value "Copy completed: $(Get-Date)"
Add-Content -Path $logFile -Value "Errors        : $errors"

if ($errors -eq 0) {
    Write-Host "Copy complete. No errors." -ForegroundColor Green
} else {
    Write-Host "Copy complete with $errors error(s). See log: $logFile" -ForegroundColor Yellow
}
