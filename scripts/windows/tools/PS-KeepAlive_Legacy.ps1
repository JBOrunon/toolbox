<#
.TITLE
    PS-KeepAlive_Legacy

.AUTHOR
    JBOrunon

.WRITTEN
    Unknown

.MODIFIED
    2026-04-21 — added header; preserved as legacy reference

.LLM
    None

.SYNOPSIS
    Legacy keep-alive script using PrintScreen simulation. See PS-KeepAlive.ps1 for
    the current version.

.DESCRIPTION
    Presses PrintScreen every 60 seconds to prevent screen lock and sleep. Functional
    but has a known side effect: overwrites clipboard contents on each interval.
    Preserved for reference. Prefer PS-KeepAlive.ps1 for new use.

.REQUIRES
    PowerShell 5.1+, Windows (any)

.REPO
    https://github.com/JBOrunon/toolbox
#>

Clear-Host

$opt = (Get-Host).PrivateData
$opt.WarningBackgroundColor = "DarkCyan"
$opt.WarningForegroundColor = "white"

Write-Warning "Your PC will not go to sleep whilst this window is open..."

Do {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("{PRTSC}")
    Start-Sleep -Seconds 60
} While ($true)
