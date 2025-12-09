<#
.SYNOPSIS
  Prepares a working folder for toolbox scripts.

.DESCRIPTION
  - Creates a working directory (default: %TEMP%\YohanToolbox)
  - Writes a README.txt explaining what this folder is for
  - Optionally downloads other toolbox scripts into that folder
  - Does NOT change system-wide settings or registry

.REPO
  https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    # Where to create the toolbox working directory.
    # Default: %TEMP%\YohanToolbox
    [string]$WorkingDirectory,

    # If specified, download selected toolbox scripts into the working directory.
    [switch]$DownloadTools
)

# --- Default working directory ---
if (-not $WorkingDirectory) {
    $WorkingDirectory = Join-Path -Path $env:TEMP -ChildPath "YohanToolbox"
}

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
    "This folder was created by PS-PrepToolbox.ps1.",
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
    $baseUrl = "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows"

    # Add any Windows toolbox scripts you want to pull by default:
    $toolFiles = @(
        "PS-GetSystemInfo.ps1",
        "PS-GetNetworkInfo.ps1"
    )

    foreach ($tool in $toolFiles) {
        $sourceUrl = "$baseUrl/$tool"
        $destPath  = Join-Path -Path $WorkingDirectory -ChildPath $tool

        Write-Host "  -> $tool"
        Write-Host "     Source: $sourceUrl"
        Write-Host "     Dest:   $destPath"

        try {
            Invoke-WebRequest -Uri $sourceUrl -OutFile $destPath -UseBasicParsing
            $downloadedFiles += $destPath
        }
        catch {
            Write-Host "     ERROR: Failed to download $tool: $($_.Exception.Message)" -ForegroundColor Red
        }

        Write-Host ""
    }
}

Write-Host ""
Write-Host "Preparation complete."
Write-Host "Working directory: $WorkingDirectory"
Write-Host "README:            $readmePath"

if ($downloadedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Downloaded scripts:" -ForegroundColor Green
    foreach ($path in $downloadedFiles) {
        Write-Host "  $path"
    }
}

Write-Host ""
Write-Host "You can safely delete this folder when troubleshooting is done."
