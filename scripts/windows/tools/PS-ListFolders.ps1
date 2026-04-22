<#
.TITLE
    PS-ListFolders

.AUTHOR
    JBOrunon

.WRITTEN
    2024-03-04

.MODIFIED
    2026-04-21 — promoted from .txt; replaced hardcoded paths with parameters,
                 standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Lists subfolders of a directory into a deduplicated, sorted text file.

.DESCRIPTION
    Gets all immediate subfolders of Path and appends any new folder names to
    OutputFile, skipping duplicates. Sorts the file alphabetically after writing.
    Creates OutputFile if it does not exist.

.REQUIRES
    PowerShell 5.1+, Windows (any)

.REPO
    https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [string]$OutputFile = "C:\jb\FolderList.txt"
)

# --- Validate source ---
if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "ERROR: Path not found: $Path" -ForegroundColor Red
    exit 1
}

# --- Ensure output file exists ---
$outputDir = Split-Path -Parent $OutputFile
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $OutputFile)) {
    New-Item -ItemType File -Path $OutputFile | Out-Null
}

# --- Get folders and deduplicate ---
$folders = Get-ChildItem -Path $Path -Directory | Select-Object -ExpandProperty Name
$existing = Get-Content -Path $OutputFile

$added = 0
foreach ($folder in $folders) {
    if ($existing -notcontains $folder) {
        Add-Content -Path $OutputFile -Value $folder
        $added++
    }
}

# --- Sort alphabetically ---
Get-Content $OutputFile | Sort-Object | Set-Content $OutputFile

Write-Host "Done. $added new folder(s) added." -ForegroundColor Green
Write-Host "Output: $OutputFile"
