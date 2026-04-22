<#
.TITLE
    PS-UninstallSentinelOne

.AUTHOR
    JBOrunon

.WRITTEN
    Unknown

.MODIFIED
    2026-04-21 — promoted from .txt; added admin requirement, colored output,
                 standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Uninstalls the SentinelOne agent, cleans up leftover files and registry keys.

.DESCRIPTION
    Locates the SentinelOne uninstall executable under C:\Program Files\SentinelOne,
    runs it silently, removes leftover files and registry entries, unregisters
    SentinelOne scheduled tasks, and restarts the machine. Supports anti-tamper
    protected environments via -PassPhrase and -AntiTamper.

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator, SentinelOne installed

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

param(
    [string]$PassPhrase = "",
    [switch]$AntiTamper
)

$agentPath = "C:\Program Files\SentinelOne"

if (-not (Test-Path $agentPath)) {
    Write-Host "SentinelOne not found on this system." -ForegroundColor Yellow
    exit 0
}

$agentFolder = Get-ChildItem $agentPath | Select-Object -First 1
$uninstallExe = Join-Path $agentFolder.FullName "uninstall.exe"

if (-not (Test-Path $uninstallExe)) {
    Write-Host "ERROR: Uninstall executable not found at: $uninstallExe" -ForegroundColor Red
    exit 1
}

# --- Run uninstaller ---
$arguments = "/norestart /q"
if ($AntiTamper -and $PassPhrase) {
    $arguments += " /k=`"$PassPhrase`""
}

Write-Host "Running SentinelOne uninstaller..." -ForegroundColor Cyan
Start-Process -FilePath $uninstallExe -ArgumentList $arguments -Wait

# --- Clean leftover files ---
Write-Host "Removing leftover files..." -ForegroundColor Cyan
Remove-Item -Path $agentPath -Recurse -Force -ErrorAction SilentlyContinue

# --- Clean registry ---
Write-Host "Cleaning registry..." -ForegroundColor Cyan
$registryPaths = @(
    "HKLM:\Software\SentinelOne",
    "HKCU:\Software\SentinelOne",
    "HKLM:\SYSTEM\CurrentControlSet\Services\SentinelAgent"
)
foreach ($path in $registryPaths) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

# --- Remove scheduled tasks ---
Get-ScheduledTask | Where-Object { $_.TaskName -like "*SentinelOne*" } |
    Unregister-ScheduledTask -Confirm:$false

Write-Host "Uninstall complete. Restarting..." -ForegroundColor Green
Restart-Computer -Force
