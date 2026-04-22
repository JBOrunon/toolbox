<#
.TITLE
    PS-GetBitLockerKey

.AUTHOR
    JBOrunon

.WRITTEN
    2022-08-15

.MODIFIED
    2026-04-21 — promoted from .txt; fixed format-list/Out-File bug, added -OutputFile
                 parameter, fixed BiosSeralNumber typo, standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Exports BitLocker key protector info and basic computer details to a text file.

.DESCRIPTION
    Collects BIOS serial number, manufacturer, model, computer name, and current
    username alongside the BitLocker key protector details for the C: drive.
    Saves everything to OutputFile for offline recovery reference.

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator, BitLocker enabled on C:

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$OutputFile = "C:\jb\BDE-RecoveryKey.txt"
)

$outputDir = Split-Path -Parent $OutputFile
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "Collecting computer info..." -ForegroundColor Cyan
Get-ComputerInfo -Property "BiosSerialNumber","CSManufacturer","CSModel","CSName" |
    Format-List | Out-File -FilePath $OutputFile -Encoding UTF8

"Username: $env:USERNAME" | Out-File -FilePath $OutputFile -Append -Encoding UTF8

Write-Host "Collecting BitLocker key protector info..." -ForegroundColor Cyan
Get-BitLockerVolume -MountPoint "C:" |
    Select-Object -ExpandProperty KeyProtector |
    Format-List | Out-File -FilePath $OutputFile -Append -Encoding UTF8

Write-Host "Done. Output saved to: $OutputFile" -ForegroundColor Green
