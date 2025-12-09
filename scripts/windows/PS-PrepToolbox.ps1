<#
.SYNOPSIS
  Prepares a working folder for toolbox scripts.

.DESCRIPTION
  - Creates a working directory (default: C:\jb)
  - Writes a README.txt explaining what this folder is for
  - Optionally downloads other toolbox scripts into that folder
  - Does NOT change system-wide settings or registry

.REPO
  https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    # Where to create the toolbox working directory.
    # Default: C:\jb
    [string]$WorkingDirectory = "C:\jb",

    # If specified, download selected toolbox scripts into the working directory.
    [switch]$DownloadTools
)

Write-Host "Preparing toolbox working directory..."
Write-Host "Target directory: $WorkingDirectory"
Write-Host ""

# --- Ensure directory exists ---
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

# --- Write README.txt ---
$readmePath = Join-Path -Path $WorkingDirectory -ChildPath "README.txt"

$readmeLines = @(
    "Yohan Toolbox Working Directory",
    "================================",
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
    "  https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-GetSystemInfo.ps1",
    "",
    "- PS-GetNetworkInfo.ps1:",
    "  https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-GetNetworkInfo.ps1",
    "",
    "Recommended usage pattern:",
    "- Download a script into this folder.",
    "- Review the script in a text editor.",
    "- Then run it from PowerShell using:",
    "    powershell -ExecutionPolicy Bypass -File .\\ScriptName.ps1",
    "",
    "Default report locations:",
    "- PS-GetSystemInfo.ps1 writes reports under this folder (e.g., C:\\jb\\SystemInfo-...).",
    "- PS-GetNetworkInfo.ps1 writes reports under this folder (e.g., C:\\jb\\NetworkInfo-...).",
    ""
)

try {
    $readmeLines | Set-Content -Path $readmePath -Encoding UTF8
}
catch {
    Write-Host "WARNING: Failed to write README.txt: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- Optional: download other toolbox scripts ---
$downloadedFiles = @()

if ($DownloadTools.IsPresent) {
    Write-Host "DownloadTools switch specified. Downloading toolbox scripts..."
    $baseUrl = "https://raw.githubusercontent.com/JBOrunon/toolbox/main/
