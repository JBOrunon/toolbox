<#
.TITLE
    PS-RemoveNetworkProfiles

.AUTHOR
    JBOrunon

.WRITTEN
    2024-02-00

.MODIFIED
    2026-04-21 — promoted from .txt; added admin requirement, colored output,
                 standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Removes all Windows network connection profiles.

.DESCRIPTION
    Retrieves all network connection profiles and removes each one. This resets
    the network category (Public/Private/Domain) assigned to each interface —
    it does not remove saved Wi-Fi passwords. Useful for resetting network trust
    state on a machine before handoff or reprovisioning.

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

$profiles = Get-NetConnectionProfile

if (-not $profiles) {
    Write-Host "No network profiles found." -ForegroundColor Yellow
    exit 0
}

foreach ($profile in $profiles) {
    Remove-NetConnectionProfile -InterfaceAlias $profile.InterfaceAlias -Confirm:$false
    Write-Host "Removed: $($profile.Name) ($($profile.InterfaceAlias))" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "All network connection profiles removed." -ForegroundColor Green
