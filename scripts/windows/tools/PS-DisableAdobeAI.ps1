<#
.TITLE
    PS-DisableAdobeAI

.AUTHOR
    JBOrunon

.WRITTEN
    2024-03-22

.MODIFIED
    2026-04-21 — promoted from .txt; added admin requirement, path creation guard,
                 error handling, confirmation read-back, and log output

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Disables Adobe Acrobat AI/Generative features via registry policy.

.DESCRIPTION
    Sets bEnableGentech to 1 under Adobe Acrobat's FeatureLockDown policy key,
    which disables AI/Generative features in Acrobat DC. Creates the registry
    path if it does not already exist. Logs actions and result to C:\jb\logs\.

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator, Adobe Acrobat DC installed

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

$registryPath = "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"
$valueName    = "bEnableGentech"
$logDir       = "C:\jb\logs"
$timestamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile      = Join-Path $logDir "DisableAdobeAI-$timestamp.txt"

# --- Prepare log ---
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $line = "$(Get-Date -Format 'HH:mm:ss')  $Message"
    Add-Content -Path $logFile -Value $line
    Write-Host $Message -ForegroundColor $Color
}

Write-Log "PS-DisableAdobeAI started"
Write-Log "Registry path : $registryPath"
Write-Log "Value name    : $valueName"
Write-Log ""

# --- Ensure registry path exists ---
if (-not (Test-Path -Path $registryPath)) {
    Write-Log "Registry path not found. Creating..." "Cyan"
    try {
        New-Item -Path $registryPath -Force | Out-Null
        Write-Log "Path created." "Green"
    }
    catch {
        Write-Log "ERROR: Failed to create registry path: $_" "Red"
        exit 1
    }
} else {
    Write-Log "Registry path exists." "Green"
}

# --- Set value ---
try {
    Set-ItemProperty -Path $registryPath -Name $valueName -Value 1 -Type DWord
    Write-Log "Set $valueName = 1 (DWord)" "Green"
}
catch {
    Write-Log "ERROR: Failed to set registry value: $_" "Red"
    exit 1
}

# --- Confirm ---
$result = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue

if ($result.$valueName -eq 1) {
    Write-Log ""
    Write-Log "Confirmed: Adobe AI features disabled successfully." "Green"
} else {
    Write-Log ""
    Write-Log "WARNING: Value could not be confirmed. Check registry manually." "Yellow"
}

Write-Log ""
Write-Log "Log written to: $logFile"
