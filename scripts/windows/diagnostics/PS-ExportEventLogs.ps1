<#
.TITLE
    PS-ExportEventLogs

.AUTHOR
    JBOrunon

.WRITTEN
    2025-08-19

.MODIFIED
    2026-04-21 — promoted from .txt; renamed, added parameters and admin requirement,
                 standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Exports Windows and PrintService event logs and compresses them into a ZIP file.

.DESCRIPTION
    Exports the following event logs to .evtx files under OutputFolder:
      - Microsoft-Windows-PrintService/Operational
      - Microsoft-Windows-PrintService/Admin
      - Application, System, Security
    Then compresses all exported .evtx files into a single ZIP archive.
    Creates OutputFolder if it does not exist.

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$OutputFolder = "C:\jb\EventLogs",
    [string]$ZipFile      = "C:\jb\EventLogs\Exported_Logs.zip"
)

# --- Ensure output folder exists ---
if (-not (Test-Path -LiteralPath $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# --- Export logs ---
$logs = @{
    "Microsoft-Windows-PrintService/Operational" = "PrintService_Operational.evtx"
    "Microsoft-Windows-PrintService/Admin"       = "PrintService_Admin.evtx"
    "Application"                                = "Application.evtx"
    "System"                                     = "System.evtx"
    "Security"                                   = "Security.evtx"
}

foreach ($logName in $logs.Keys) {
    $dest = Join-Path $OutputFolder $logs[$logName]
    Write-Host "Exporting: $logName" -ForegroundColor Cyan
    try {
        wevtutil epl $logName $dest
        Write-Host "  -> $dest" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: Failed to export '$logName': $_" -ForegroundColor Yellow
    }
}

# --- Compress ---
Write-Host ""
Write-Host "Compressing logs to: $ZipFile" -ForegroundColor Cyan
Compress-Archive -Path "$OutputFolder\*.evtx" -DestinationPath $ZipFile -Force
Write-Host "Done." -ForegroundColor Green
