<#
.TITLE
    PS-ForceWindowsUpdate

.AUTHOR
    JBOrunon

.WRITTEN
    2026-04-21

.MODIFIED
    2026-04-21 — promoted from one-liner; added module check, reboot delay, user notification

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Forces a full Windows Update run (including Microsoft/Office updates) and schedules
    a notified reboot if one is required.

.DESCRIPTION
    Installs the PSWindowsUpdate module if not already present, registers the Microsoft
    Update service, and runs all available updates. If a reboot is required, schedules
    one after a configurable delay and notifies the logged-in user via the shutdown dialog.
    The reboot can be cancelled with 'shutdown -a' before the timer expires.

.REQUIRES
    PowerShell 5.1+, Windows 10 / Server 2016+, run as Administrator,
    internet access (for module install and Windows Update)

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [int]$RebootDelayMinutes = 5
)

# ---------------------------------------------------------------------------
# 1. Ensure PSWindowsUpdate module is available
# ---------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "==> PSWindowsUpdate module not found. Installing..." -ForegroundColor Cyan
    Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers
    Write-Host "    Installed." -ForegroundColor Green
} else {
    Write-Host "==> PSWindowsUpdate module already installed." -ForegroundColor Green
}

Import-Module PSWindowsUpdate

# ---------------------------------------------------------------------------
# 2. Register Microsoft Update service (catches Office, drivers, etc.)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Registering Microsoft Update service..." -ForegroundColor Cyan
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
Write-Host "    Done." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 3. Run all available updates (no immediate auto-reboot)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Running Windows Update..." -ForegroundColor Cyan
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Verbose

# ---------------------------------------------------------------------------
# 4. Schedule reboot if required
# ---------------------------------------------------------------------------
Write-Host ""
$rebootRequired = (Get-WURebootStatus -Silent)

if ($rebootRequired) {
    $seconds     = $RebootDelayMinutes * 60
    $rebootTime  = (Get-Date).AddMinutes($RebootDelayMinutes).ToString("h:mm tt")
    $message     = "Windows Update complete. This computer will restart in $RebootDelayMinutes minute(s) at approximately $rebootTime. Save your work. To cancel: shutdown -a"

    shutdown -r -t $seconds -c "$message"

    Write-Host "Reboot required. Restart scheduled." -ForegroundColor Yellow
    Write-Host "  In    : $RebootDelayMinutes minute(s)"
    Write-Host "  At    : ~$rebootTime"
    Write-Host "  To cancel: shutdown -a"
} else {
    Write-Host "No reboot required. All done." -ForegroundColor Green
}
