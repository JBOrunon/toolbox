<#
.TITLE
    PS-ClearPrintSpooler

.AUTHOR
    JBOrunon

.WRITTEN
    2026-04-21

.MODIFIED
    2026-04-21 — promoted from .txt; added RunAsAdministrator, service status check

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Clears the print queue and restarts the Print Spooler service.

.DESCRIPTION
    Stops the Print Spooler service, deletes all files in the spool directory,
    and restarts the service. Useful for clearing stuck or corrupted print jobs.
    Confirms service status after restart.

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

$spoolFolder = "$env:SystemRoot\System32\spool\PRINTERS"

Write-Host "Stopping Print Spooler service..." -ForegroundColor Cyan
Stop-Service -Name Spooler -Force

Write-Host "Clearing print queue at $spoolFolder..." -ForegroundColor Cyan
Remove-Item "$spoolFolder\*" -Force -ErrorAction SilentlyContinue

Write-Host "Starting Print Spooler service..." -ForegroundColor Cyan
Start-Service -Name Spooler

$status = (Get-Service -Name Spooler).Status
if ($status -eq "Running") {
    Write-Host "Print Spooler restarted successfully. Queue cleared." -ForegroundColor Green
} else {
    Write-Host "WARNING: Print Spooler may not have started correctly. Status: $status" -ForegroundColor Yellow
}
