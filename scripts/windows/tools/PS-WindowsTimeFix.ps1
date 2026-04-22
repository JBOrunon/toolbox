<#
.TITLE
    PS-WindowsTimeFix

.AUTHOR
    JBOrunon

.WRITTEN
    2025-05-01

.MODIFIED
    2026-04-21 — promoted from .txt; added parameters, admin requirement,
                 standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Resets and reconfigures the Windows Time Service (w32tm).

.DESCRIPTION
    Unregisters, stops, re-registers, and starts the Windows Time Service, then
    configures it to sync from a specified NTP server. Restarts the service to
    apply changes and confirms the new configuration. Useful for fixing time sync
    issues on domain-joined or standalone machines.

    Default NTP server: 132.163.96.1 (time.nist.gov)

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$NtpServer = "132.163.96.1"  # time.nist.gov
)

Write-Host "Current time source and configuration:" -ForegroundColor Cyan
w32tm /query /source
w32tm /query /configuration

Write-Host ""
Write-Host "Resetting Windows Time Service..." -ForegroundColor Cyan

w32tm /unregister
Stop-Service -Name w32time -Force
w32tm /register
Start-Service -Name w32time

Write-Host "Configuring NTP server: $NtpServer" -ForegroundColor Cyan
w32tm /config /manualpeerlist:$NtpServer /syncfromflags:manual /reliable:yes /update

Stop-Service -Name w32time -Force
Start-Service -Name w32time

Write-Host ""
Write-Host "New configuration:" -ForegroundColor Cyan
w32tm /query /configuration

Write-Host ""
Write-Host "Windows Time Service reconfigured." -ForegroundColor Green
