<#
.TITLE
    PS-ScheduleShutdown

.AUTHOR
    JBOrunon

.WRITTEN
    2026-04-21

.MODIFIED
    2026-04-21 — promoted from one-liner; added -Hours parameter and -Cancel support

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Schedules a forced Windows shutdown after a specified number of hours.

.DESCRIPTION
    Wraps the built-in shutdown command with a configurable delay (default: 2 hours).
    Forces running applications to close. Displays the scheduled time and a reminder
    of how to cancel. Use -Cancel to abort a previously scheduled shutdown.

.REQUIRES
    PowerShell 5.1+, Windows (any)

.REPO
    https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    [double]$Hours = 2,
    [switch]$Cancel
)

if ($Cancel) {
    shutdown -a
    Write-Host "Scheduled shutdown cancelled." -ForegroundColor Green
    exit
}

$seconds  = [int]($Hours * 3600)
$time     = (Get-Date).AddSeconds($seconds).ToString("h:mm tt")

shutdown -s -t $seconds -f

Write-Host ""
Write-Host "Shutdown scheduled." -ForegroundColor Yellow
Write-Host "  In    : $Hours hour(s)"
Write-Host "  At    : ~$time"
Write-Host "  To cancel: shutdown -a"
Write-Host "           or: .\PS-ScheduleShutdown.ps1 -Cancel"
