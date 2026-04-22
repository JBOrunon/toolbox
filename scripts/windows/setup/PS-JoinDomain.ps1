<#
.TITLE
    PS-JoinDomain

.AUTHOR
    JBOrunon

.WRITTEN
    Unknown

.MODIFIED
    2026-04-21 — promoted from one-liner; added parameters, standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Joins the local machine to an Active Directory domain.

.DESCRIPTION
    Runs Add-Computer with the specified domain name and credentials. The machine
    must be restarted after joining for the change to take effect.

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator, network access to domain

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$DomainName,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$Credential
)

try {
    Add-Computer -DomainName $DomainName -Credential $Credential -ErrorAction Stop
    Write-Host "Successfully joined domain: $DomainName" -ForegroundColor Green
    Write-Host "Restart the machine to complete the domain join." -ForegroundColor Yellow
} catch {
    Write-Host "ERROR: Failed to join domain '$DomainName': $_" -ForegroundColor Red
    exit 1
}
