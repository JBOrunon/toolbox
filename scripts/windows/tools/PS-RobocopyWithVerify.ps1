<#
.TITLE
    PS-RobocopyWithVerify

.AUTHOR
    JBOrunon

.WRITTEN
    2025-05-01

.MODIFIED
    2026-04-21 — promoted from .txt; replaced hardcoded paths with parameters,
                 timestamped logs under C:\jb\logs, added summary counts,
                 standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Copies files between locations using Robocopy, then verifies integrity via SHA256.

.DESCRIPTION
    Uses Robocopy (/E /R:2 /W:2 /MT:8) to transfer files from Source to Destination,
    then performs a SHA256 hash comparison on every file to confirm the copy is
    identical. Logs copy output and integrity results to separate timestamped files
    under LogDir. Reports match, mismatch, and missing counts at completion.

.REQUIRES
    PowerShell 5.1+, Windows (any), Robocopy (built into Windows)

.REPO
    https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Source,

    [Parameter(Mandatory)]
    [string]$Destination,

    [string]$LogDir = "C:\jb\logs"
)

# --- Validate source ---
if (-not (Test-Path -LiteralPath $Source)) {
    Write-Host "ERROR: Source not found: $Source" -ForegroundColor Red
    exit 1
}

# --- Prepare logs ---
if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$copyLog     = Join-Path $LogDir "Robocopy-$timestamp.txt"
$integrityLog = Join-Path $LogDir "RobocopyVerify-$timestamp.txt"

# --- Robocopy ---
Write-Host "Starting Robocopy..." -ForegroundColor Cyan
Write-Host "  Source      : $Source"
Write-Host "  Destination : $Destination"
Write-Host "  Copy log    : $copyLog"
Write-Host ""

Add-Content -Path $copyLog -Value "Copy started: $(Get-Date)"

$robocopyArgs = "`"$Source`" `"$Destination`" /E /R:2 /W:2 /MT:8 /LOG+:`"$copyLog`" /V /NP /XO"
Start-Process -FilePath "robocopy" -ArgumentList $robocopyArgs -Wait -NoNewWindow

Add-Content -Path $copyLog -Value "Copy completed: $(Get-Date)"
Write-Host "Robocopy complete." -ForegroundColor Green

# --- Integrity check ---
Write-Host ""
Write-Host "Running SHA256 integrity check..." -ForegroundColor Cyan
Write-Host "  Integrity log: $integrityLog"
Write-Host ""

Add-Content -Path $integrityLog -Value "Integrity check started: $(Get-Date)"
Add-Content -Path $integrityLog -Value "Source      : $Source"
Add-Content -Path $integrityLog -Value "Destination : $Destination"
Add-Content -Path $integrityLog -Value ""

$matched  = 0
$mismatched = 0
$missing  = 0

$sourceFiles = Get-ChildItem -Path $Source -File -Recurse -ErrorAction SilentlyContinue

foreach ($file in $sourceFiles) {
    $relativePath = $file.FullName.Substring($Source.Length).TrimStart("\")
    $destFile     = Join-Path $Destination $relativePath

    try {
        if (Test-Path -LiteralPath $destFile) {
            $srcHash  = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
            $dstHash  = (Get-FileHash -Path $destFile -Algorithm SHA256).Hash

            if ($srcHash -eq $dstHash) {
                Add-Content -Path $integrityLog -Value "MATCH   : $relativePath"
                $matched++
            } else {
                Add-Content -Path $integrityLog -Value "MISMATCH: $relativePath"
                $mismatched++
            }
        } else {
            Add-Content -Path $integrityLog -Value "MISSING : $relativePath"
            $missing++
        }
    } catch {
        Add-Content -Path $integrityLog -Value "ERROR   : $relativePath — $_"
    }
}

Add-Content -Path $integrityLog -Value ""
Add-Content -Path $integrityLog -Value "Integrity check completed: $(Get-Date)"
Add-Content -Path $integrityLog -Value "Match: $matched  |  Mismatch: $mismatched  |  Missing: $missing"

# --- Summary ---
Write-Host "Integrity check complete." -ForegroundColor Green
Write-Host "  Matched  : $matched" -ForegroundColor Green
if ($mismatched -gt 0) {
    Write-Host "  Mismatch : $mismatched" -ForegroundColor Red
} else {
    Write-Host "  Mismatch : $mismatched" -ForegroundColor Green
}
if ($missing -gt 0) {
    Write-Host "  Missing  : $missing" -ForegroundColor Red
} else {
    Write-Host "  Missing  : $missing" -ForegroundColor Green
}
Write-Host ""
Write-Host "Logs saved to: $LogDir"
