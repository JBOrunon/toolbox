<#
.TITLE
    PS-RemoveEmptyFolders

.AUTHOR
    JBOrunon

.WRITTEN
    2026-01-07

.MODIFIED
    2026-04-21 — promoted from .ps1; added -WhatIf support, colored output,
                 standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Deletes empty immediate subfolders of a given directory.

.DESCRIPTION
    Checks each top-level subfolder of RootPath (non-recursive) and removes any
    that are empty. Supports -WhatIf for a dry run to preview what would be deleted
    without making any changes.

.REQUIRES
    PowerShell 5.1+, Windows (any)

.REPO
    https://github.com/JBOrunon/toolbox
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$RootPath
)

if (-not (Test-Path -LiteralPath $RootPath)) {
    Write-Host "ERROR: Path not found: $RootPath" -ForegroundColor Red
    exit 1
}

$deleted = 0

Get-ChildItem -Path $RootPath -Directory | ForEach-Object {
    if (-not (Get-ChildItem -Path $_.FullName -Force)) {
        if ($PSCmdlet.ShouldProcess($_.FullName, "Remove empty folder")) {
            Remove-Item -Path $_.FullName -Force
            Write-Host "Deleted: $($_.FullName)" -ForegroundColor Yellow
            $deleted++
        }
    }
}

if (-not $WhatIfPreference) {
    Write-Host ""
    Write-Host "$deleted empty folder(s) removed." -ForegroundColor Green
}
