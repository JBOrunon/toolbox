<#
.SYNOPSIS
    Download selected SoftwareOK tools directly from SoftwareOK.com.

.DESCRIPTION
    Convenience downloader for a handful of excellent freeware utilities
    written by Nenad Hrg and published on SoftwareOK.com.

    Defaults:
      - Uses C:\jb as the overall work area
      - Downloads into: C:\jb\softwareok

    This script:
      - Always downloads from the OFFICIAL SoftwareOK URLs
      - Never modifies the downloaded ZIPs
      - Can optionally download a subset by name, or everything at once

.PARAMETER Name
    One or more tool keys to download. Valid values:

      DeleteOnReboot
      DesktopNoteOKInstaller
      DesktopNoteOKPortable
      ThisIsMyFile
      DirPrintOKInstaller
      DirPrintOKPortable
      DontSleep
      DontSleepPortable
      QDirInstaller
      QDirPortable

.PARAMETER All
    Download all known tools.

.PARAMETER Destination
    Target directory for the ZIP files.
    Defaults to: C:\jb\softwareok

.EXAMPLE
    # Download everything into the default work area (C:\jb\softwareok)
    .\PS-GetSoftwareOKTools.ps1 -All

.EXAMPLE
    # Download just Q-Dir (installer + portable)
    .\PS-GetSoftwareOKTools.ps1 -Name QDirInstaller, QDirPortable

.EXAMPLE
    # Custom destination
    .\PS-GetSoftwareOKTools.ps1 -All -Destination 'D:\Tools\SoftwareOK'

.NOTES
    All credit for these tools goes to Nenad Hrg / SoftwareOK.
    Homepage: https://www.softwareok.com/
#>

[CmdletBinding()]
param(
    [ValidateSet(
        'DeleteOnReboot',
        'DesktopNoteOKInstaller',
        'DesktopNoteOKPortable',
        'ThisIsMyFile',
        'DirPrintOKInstaller',
        'DirPrintOKPortable',
        'DontSleep',
        'DontSleepPortable',
        'QDirInstaller',
        'QDirPortable'
    )]
    [string[]]$Name,

    [string]$Destination = 'C:\jb\softwareok',

    [switch]$All
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ensure base work area exists (C:\jb)
$workRoot = 'C:\jb'
if (-not (Test-Path -LiteralPath $workRoot)) {
    New-Item -Path $workRoot -ItemType Directory -Force | Out-Null
}

# Ensure destination exists
if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -Path $Destination -ItemType Directory -Force | Out-Null
}

# Be explicit about TLS for older PowerShells
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    Write-Verbose "Could not set TLS12 explicitly: $($_.Exception.Message)"
}

# Map of logical names -> official filenames + URLs
$tools = @{
    'DeleteOnReboot' = @{
        FileName = 'Delete.On.Reboot.zip'
        Url      = 'https://www.softwareok.com/Download/Delete.On.Reboot.zip'
        InfoUrl  = 'https://www.softwareok.com/?seite=Freeware/Delete.On.Reboot'
    }
    'DesktopNoteOKInstaller' = @{
        FileName = 'DesktopNoteOK_Installer.zip'
        Url      = 'https://www.softwareok.com/Download/DesktopNoteOK_Installer.zip'
        InfoUrl  = 'https://www.softwareok.com/?Download=DesktopNoteOK'
    }
    'DesktopNoteOKPortable' = @{
        FileName = 'DesktopNoteOK_Portable.zip'
        Url      = 'https://www.softwareok.com/Download/DesktopNoteOK_Portable.zip'
        InfoUrl  = 'https://www.softwareok.com/?Download=DesktopNoteOK'
    }
    'ThisIsMyFile' = @{
        FileName = 'ThisIsMyFile.zip'
        Url      = 'https://www.softwareok.com/Download/ThisIsMyFile.zip'
        InfoUrl  = 'https://www.softwareok.com/?Download=ThisIsMyFile'
    }
    'DirPrintOKInstaller' = @{
        FileName = 'DirPrintOK_Installer.zip'
        Url      = 'https://www.softwareok.com/Download/DirPrintOK_Installer.zip'
        InfoUrl  = 'https://www.softwareok.com/?Download=DirPrintOK'
    }
    'DirPrintOKPortable' = @{
        FileName = 'DirPrintOK_Portable.zip'
        Url      = 'https://www.softwareok.com/Download/DirPrintOK_Portable.zip'
        InfoUrl  = 'https://www.softwareok.com/?Download=DirPrintOK'
    }
    'DontSleep' = @{
        FileName = 'DontSleep.zip'
        Url      = 'https://www.softwareok.com/Download/DontSleep.zip'
        InfoUrl  = 'https://www.softwareok.com/?Download=DontSleep'
    }
    'DontSleepPortable' = @{
        FileName = 'DontSleep_Portable.zip'
        Url      = 'https://www.softwareok.com/Download/DontSleep_Portable.zip'
        InfoUrl  = 'https://www.softwareok.com/?Download=DontSleep'
    }
    'QDirInstaller' = @{
        FileName = 'Q-Dir_Installer.zip'
        Url      = 'https://www.softwareok.com/Download/Q-Dir_Installer.zip'
        InfoUrl  = 'https://www.softwareok.com/?Download=Q-Dir'
    }
    'QDirPortable' = @{
        FileName = 'Q-Dir_Portable.zip'
        Url      = 'https://www.softwareok.com/Download/Q-Dir_Portable.zip'
        InfoUrl  = 'https://www.softwareok.com/?Download=Q-Dir'
    }
}

# Work out which tools to download
if ($All -or -not $Name) {
    $targets = $tools.Keys
} else {
    $targets = $Name
}

Write-Host "Downloading SoftwareOK tools to: $Destination" -ForegroundColor Cyan

foreach ($key in $targets) {
    if (-not $tools.ContainsKey($key)) {
        Write-Warning "Unknown tool key '$key' – skipping."
        continue
    }

    $tool    = $tools[$key]
    $outFile = Join-Path -Path $Destination -ChildPath $tool.FileName

    Write-Host ""
    Write-Host "==> $key" -ForegroundColor Yellow
    Write-Host "    URL : $($tool.Url)"
    Write-Host "    File: $outFile"

    try {
        Invoke-WebRequest -Uri $tool.Url -OutFile $outFile -UseBasicParsing
        Write-Host "    ✓ Downloaded OK" -ForegroundColor Green
    }
    catch {
        Write-Warning "    ✗ Failed to download $key: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "All download attempts complete." -ForegroundColor Cyan
Write-Host "You can now unzip and run the tools as needed." -ForegroundColor Cyan
