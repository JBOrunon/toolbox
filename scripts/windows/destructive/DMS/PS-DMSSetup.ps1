#Requires -RunAsAdministrator
<#
.TITLE
    PS-DMSSetup

.AUTHOR
    JBOrunon

.WRITTEN
    2026-04-22

.MODIFIED
    2026-04-22

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    One-time setup for PS-DMS: creates the registry keys and stores the password hash.

.DESCRIPTION
    Creates the DMS registry path under HKCU:\Software\JBOrunon\DMS, sets the initial
    flag to 1 (armed), and prompts for a security password. The password is hashed with
    SHA-256 and stored in the registry — the plaintext is never written anywhere.

    Re-run this script to change the password. The flag is reset to 1 each time.

    Run once before configuring the Task Scheduler task. See README.md for full setup
    instructions.

.REQUIRES
    PowerShell 5.1+, local administrator account.

.REPO
    https://github.com/JBOrunon/toolbox
#>

$RegPath = "HKCU:\Software\JBOrunon\DMS"

if (-not (Test-Path "C:\jb\logs")) { New-Item -ItemType Directory -Path "C:\jb\logs" | Out-Null }
if (-not (Test-Path $RegPath))     { New-Item -Path $RegPath -Force | Out-Null }

Set-ItemProperty -Path $RegPath -Name "Flag" -Value 1 -Type DWord

$securePass = Read-Host -AsSecureString "Set DMS security password"
$bstr       = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
$plaintext  = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

$bytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)
$plaintext = $null
[GC]::Collect()

$hash = [System.BitConverter]::ToString(
    [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)) -replace '-', ''
[Array]::Clear($bytes, 0, $bytes.Length)

Set-ItemProperty -Path $RegPath -Name "AuthHash" -Value $hash -Type String

Write-Host ""
Write-Host "DMS initialized."
Write-Host "  Flag:     1 (armed)"
Write-Host "  Password: hash stored in registry (plaintext never saved)"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Create your reference file — see DMSReference-example.txt"
Write-Host "  2. Configure Task Scheduler — see README.md"
