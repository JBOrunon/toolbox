<#
.TITLE
    PS-AddLocalAdmin

.AUTHOR
    JBOrunon

.WRITTEN
    Unknown

.MODIFIED
    2026-04-21 — promoted from snippet; added parameters, error handling, confirmation output

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Creates a local user account and adds it to the Administrators group.

.DESCRIPTION
    Creates a new local user with the specified username and password, then adds
    that user to the local Administrators group. Confirms each step with colored
    output. Requires an elevated session.

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Username,

    [Parameter(Mandatory)]
    [SecureString]$Password
)

# --- Create user ---
try {
    New-LocalUser -Name $Username -Password $Password -FullName $Username -Description "Local admin" -ErrorAction Stop
    Write-Host "User created: $Username" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to create user '$Username': $_" -ForegroundColor Red
    exit 1
}

# --- Add to Administrators ---
try {
    Add-LocalGroupMember -Group "Administrators" -Member $Username -ErrorAction Stop
    Write-Host "Added '$Username' to Administrators." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to add '$Username' to Administrators: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Done. '$Username' is now a local administrator." -ForegroundColor Green
