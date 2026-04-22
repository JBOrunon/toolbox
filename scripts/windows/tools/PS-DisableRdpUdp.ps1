<#
.TITLE
    PS-DisableRdpUdp

.AUTHOR
    JBOrunon

.WRITTEN
    Unknown

.MODIFIED
    2026-04-21 — promoted from .txt; stripped identifying info, moved log to
                 C:\jb\logs, removed unreachable toast code, added admin
                 requirement, standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Disables UDP on RDP port 3389 via registry and restarts Remote Desktop Services.

.DESCRIPTION
    Checks for active RDP sessions and UDP availability on port 3389, then sets
    fClientDisableUDP = 1 in the Terminal Services Client policy key and restarts
    the Remote Desktop Services (TermService). Returns specific exit codes for
    use in RMM or scripted deployment contexts.

    Exit codes:
      1 — Active RDP session detected; cannot proceed
      2 — UDP not enabled on port 3389; no change needed
      3 — Failed to update registry
      4 — Failed to restart Remote Desktop Services
      5 — Success

.REQUIRES
    PowerShell 5.1+, Windows (any), run as Administrator

.REPO
    https://github.com/JBOrunon/toolbox
#>

#Requires -RunAsAdministrator

$logDir  = "C:\jb\logs"
$logFile = Join-Path $logDir "DisableRdpUdp-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $line = "$(Get-Date -Format 'HH:mm:ss')  $Message"
    Add-Content -Path $logFile -Value $line
    Write-Host $Message -ForegroundColor $Color
}

Write-Log "PS-DisableRdpUdp started."

# 1. Check for active RDP session
$rdpSessions = qwinsta | Select-String -Pattern "rdp-tcp"
if ($rdpSessions) {
    Write-Log "Active RDP session detected. Cannot proceed." "Red"
    exit 1
}

# 2. Check if UDP is enabled on port 3389
$udpEnabled = $null -ne (Get-NetUDPEndpoint -LocalPort 3389 -ErrorAction SilentlyContinue)
if (-not $udpEnabled) {
    Write-Log "UDP not enabled on port 3389. No change needed." "Yellow"
    exit 2
}

# 3. Set registry key to disable UDP for RDP
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client"
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
try {
    New-ItemProperty -Path $regPath -Name "fClientDisableUDP" -Value 1 -PropertyType DWORD -Force | Out-Null
    Write-Log "Registry updated: fClientDisableUDP = 1" "Green"
} catch {
    Write-Log "Failed to update registry: $_" "Red"
    exit 3
}

# 4. Restart Remote Desktop Services
try {
    Restart-Service -Name "TermService" -Force
    Write-Log "Remote Desktop Services restarted." "Green"
} catch {
    Write-Log "Failed to restart Remote Desktop Services: $_" "Red"
    exit 4
}

Write-Log "All steps completed successfully." "Green"
Write-Log "Log: $logFile"
exit 5
