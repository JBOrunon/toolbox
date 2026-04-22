#Requires -RunAsAdministrator
<#
.TITLE
    PS-DMSReset

.AUTHOR
    JBOrunon

.WRITTEN
    2020-09-01

.MODIFIED
    2026-04-22 — promoted to toolbox as v0.9; registry flag replaces txt file

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Resets the DMS flag to 1 (armed).

.DESCRIPTION
    Sets the DMS registry flag back to 1, re-arming the Dead Man Switch after a
    triggered wipe or a deliberate disarm. Run this script whenever you want to
    confirm you still have control of the machine and restart the check cycle.

    Run PS-DMSSetup.ps1 first if the registry has not been initialized.

.REQUIRES
    PowerShell 5.1+, local administrator account. PS-DMSSetup.ps1 must have been run.

.REPO
    https://github.com/JBOrunon/toolbox
#>

$RegPath    = "HKCU:\Software\JBOrunon\DMS"
$dateSuffix = (Get-Date).ToString("MMddyy")
$LogFile    = "C:\jb\logs\DMS-$dateSuffix.log"

if (-not (Test-Path "C:\jb\logs")) { New-Item -ItemType Directory -Path "C:\jb\logs" | Out-Null }

if (-not (Test-Path $RegPath)) {
    Write-Host "DMS registry not found. Run PS-DMSSetup.ps1 first."
    exit
}

Set-ItemProperty -Path $RegPath -Name "Flag" -Value 1 -Type DWord

$ts = (Get-Date).ToString("MMddyy:HHmm")
Add-Content -Path $LogFile -Value "$ts - DMS reset to 1"

Write-Host "DMS flag reset to 1 (armed)."
