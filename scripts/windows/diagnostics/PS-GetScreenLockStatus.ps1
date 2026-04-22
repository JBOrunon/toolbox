<#
.TITLE
    PS-GetScreenLockStatus

.AUTHOR
    JBOrunon

.WRITTEN
    2025-09-16

.MODIFIED
    2026-04-21 — promoted from .txt; replaced Get-WmiObject with Get-CimInstance, formatted

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Reports whether the current user's screen is locked.

.DESCRIPTION
    Detects the presence of the logonui.exe process, which Windows runs when the
    screen is locked. Reports the logged-in username alongside the lock status.

.REQUIRES
    PowerShell 5.1+, Windows (any)

.REPO
    https://github.com/JBOrunon/toolbox
#>

$loggedInUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
$isLocked     = [bool](Get-Process -Name "logonui" -ErrorAction SilentlyContinue)

if ($isLocked) {
    Write-Host "Screen is LOCKED   — User: $loggedInUser" -ForegroundColor Yellow
} else {
    Write-Host "Screen is UNLOCKED — User: $loggedInUser" -ForegroundColor Green
}
