<#
.TITLE
    PS-RemoveRdpFiles

.AUTHOR
    JBOrunon

.WRITTEN
    Unknown

.MODIFIED
    2026-04-21 — promoted from .txt; added parameters, -WhatIf support, colored
                 output, file count, admin requirement, standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Deletes all .rdp files from every user's Desktop.

.DESCRIPTION
    Iterates all user profile directories under UsersPath and removes any .rdp
    files found on each Desktop. Useful for cleaning up RDP shortcuts before
    handing off or reprovisioning a machine. Supports -WhatIf for a dry run.

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$UsersPath = "C:\Users"
)

if (-not (Test-Path -LiteralPath $UsersPath)) {
    Write-Host "ERROR: UsersPath not found: $UsersPath" -ForegroundColor Red
    exit 1
}

$totalRemoved = 0

Get-ChildItem -Path $UsersPath -Directory | ForEach-Object {
    $desktopPath = Join-Path $_.FullName "Desktop"
    if (Test-Path -LiteralPath $desktopPath) {
        $rdpFiles = Get-ChildItem -Path $desktopPath -Filter "*.rdp" -File -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $rdpFiles) {
            if ($PSCmdlet.ShouldProcess($file.FullName, "Remove .rdp file")) {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "Removed: $($file.FullName)" -ForegroundColor Yellow
                $totalRemoved++
            }
        }
    }
}

if (-not $WhatIfPreference) {
    Write-Host ""
    Write-Host "$totalRemoved .rdp file(s) removed." -ForegroundColor Green
}
