<#
.TITLE
    PS-MakeMonthFolder

.AUTHOR
    JBOrunon

.WRITTEN
    2023-01-26

.MODIFIED
    2026-04-21 — promoted from .txt; replaced hardcoded path with parameter,
                 stripped identifying info, simplified structure, standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Creates a yyyy_MM named subfolder under a given path if it does not already exist.

.DESCRIPTION
    Checks whether a folder named with the current year and month (e.g. 2026_04)
    exists under Path. Creates it if missing, reports if it already exists.
    Intended to be scheduled on the first of each month.

.REQUIRES
    PowerShell 5.1+, Windows (any)

.REPO
    https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path
)

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "ERROR: Path not found: $Path" -ForegroundColor Red
    exit 1
}

$folderName = Get-Date -Format "yyyy_MM"
$fullPath   = Join-Path $Path $folderName

if (Test-Path -LiteralPath $fullPath) {
    Write-Host "Folder already exists: $fullPath" -ForegroundColor Yellow
} else {
    New-Item -Path $Path -ItemType Directory -Name $folderName | Out-Null
    Write-Host "Created: $fullPath" -ForegroundColor Green
}
