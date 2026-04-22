<#
.TITLE
    PS-PrepToolbox

.AUTHOR
    JBOrunon

.WRITTEN
    2025-12-09

.MODIFIED
    2026-04-21 — updated header; fixed name leak in README.txt; added logs subfolder creation

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Prepares a working folder for toolbox scripts.

.DESCRIPTION
    Creates a working directory (default: C:\jb) and a logs subfolder (C:\jb\logs),
    writes a README.txt explaining the folder's purpose, and optionally downloads
    PS-GetSystemInfo.ps1 and PS-GetNetworkInfo.ps1. Does not change system-wide
    settings or registry.

.REQUIRES
    PowerShell 5.1+, Windows 10 / Server 2016+, internet access (for -DownloadTools)

.REPO
    https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    [string]$WorkingDirectory = "C:\jb",
    [switch]$DownloadTools
)

$logsDirectory = Join-Path $WorkingDirectory "logs"

Write-Host "Preparing toolbox working directory..."
Write-Host "Target directory: $WorkingDirectory"
Write-Host ""

# --- Ensure working directory exists ---
try {
    if (Test-Path -Path $WorkingDirectory) {
        $item = Get-Item -LiteralPath $WorkingDirectory
        if (-not $item.PSIsContainer) {
            throw "Path '$WorkingDirectory' exists but is not a directory."
        }
    } else {
        New-Item -ItemType Directory -Path $WorkingDirectory -Force | Out-Null
    }
}
catch {
    Write-Host "ERROR: Failed to prepare working directory: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# --- Ensure logs subdirectory exists ---
if (-not (Test-Path -LiteralPath $logsDirectory)) {
    New-Item -ItemType Directory -Path $logsDirectory -Force | Out-Null
}
Write-Host "Logs directory: $logsDirectory"

# --- Write README.txt ---
$readmePath = Join-Path $WorkingDirectory "README.txt"

$readmeLines = @(
    "JB Toolbox Working Directory",
    "=============================",
    "",
    "This folder was prepared by PS-PrepToolbox.ps1.",
    "",
    "Default location:",
    "  C:\jb",
    "",
    "Purpose:",
    "- Provide a central location for temporary troubleshooting scripts and reports.",
    "- All scripts are sourced from:",
    "    https://github.com/JBOrunon/toolbox",
    "",
    "Subfolders:",
    "  logs\   Script execution logs (e.g. from PS-CopyWithLog.ps1)",
    "",
    "Notes:",
    "- This folder is safe to delete once troubleshooting is complete.",
    "- No permanent system changes are made by PS-PrepToolbox itself.",
    "",
    "Common scripts (Windows):",
    "- PS-GetSystemInfo.ps1",
    "- PS-GetNetworkInfo.ps1",
    "",
    "GitHub raw URLs:",
    "- PS-GetSystemInfo.ps1:",
    "  https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/diagnostics/PS-GetSystemInfo.ps1",
    "",
    "- PS-GetNetworkInfo.ps1:",
    "  https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/diagnostics/PS-GetNetworkInfo.ps1",
    "",
    "Recommended usage pattern:",
    "- Download a script into this folder.",
    "- Review the script in a text editor.",
    "- Then run it from PowerShell using:",
    "    powershell -ExecutionPolicy Bypass -File .\ScriptName.ps1",
    "",
    "Default report locations:",
    "- PS-GetSystemInfo.ps1  -> C:\jb\SystemInfo-MACHINE-TIMESTAMP.txt",
    "- PS-GetNetworkInfo.ps1 -> C:\jb\NetworkInfo-MACHINE-TIMESTAMP.txt",
    "- PS-CopyWithLog.ps1    -> C:\jb\logs\CopyLog-TIMESTAMP.txt",
    ""
)

try {
    $readmeLines | Set-Content -Path $readmePath -Encoding UTF8
    Write-Host "Wrote README: $readmePath"
}
catch {
    Write-Host "WARNING: Failed to write README.txt: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- Optional: download toolbox scripts ---
if ($DownloadTools.IsPresent) {
    Write-Host ""
    Write-Host "DownloadTools requested. Downloading Windows diagnostic scripts..." -ForegroundColor Cyan

    $baseUrl = "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/diagnostics"
    $files   = @("PS-GetSystemInfo.ps1", "PS-GetNetworkInfo.ps1")

    foreach ($name in $files) {
        $url  = "$baseUrl/$name"
        $dest = Join-Path $WorkingDirectory $name

        Write-Host "  -> $name"
        Write-Host "     Source: $url"
        Write-Host "     Dest  : $dest"

        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
            Write-Host "     Downloaded OK" -ForegroundColor Green
        }
        catch {
            Write-Host "     FAILED: $($_.Exception.Message)" -ForegroundColor Red
        }

        Write-Host ""
    }
}

Write-Host ""
Write-Host "Preparation complete." -ForegroundColor Green
Write-Host "Working directory : $WorkingDirectory"
Write-Host "Logs directory    : $logsDirectory"
Write-Host "Safe to delete this folder when done."
