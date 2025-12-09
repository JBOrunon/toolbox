<#
.SYNOPSIS
  Collects network-related information for troubleshooting.

.DESCRIPTION
  Generates a text report with adapter details, IP configuration,
  DNS servers, routes, ARP table, and basic connectivity tests.

.REPO
  https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    [string]$OutputPath,

    [string[]]$TestTargets = @(
        "1.1.1.1",      # Cloudflare DNS
        "8.8.8.8",      # Google DNS
        "github.com"    # Common HTTPS endpoint
    )
)

# If no output path is specified, write to the current directory
if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $fileName = "NetworkInfo-$($env:COMPUTERNAME)-$timestamp.txt"
    $OutputPath = Join-Path -Path (Get-Location) -ChildPath $fileName
}

Write-Host "Generating network information report..."
Write-Host "Output file: $OutputPath"
Write-Host ""

# Helper function to append a header to the report
function Add-Section {
    param(
        [string]$Title
    )
    "==================================================" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
    "=== $Title" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
    "==================================================`r`n" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# Start with a fresh file
"Network Information Report" | Out-File -FilePath $OutputPath -Encoding UTF8
"Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
"Computer: $($env:COMPUTERNAME)" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
"User: $($env:USERNAME)`r`n" | Out-File -FilePath $OutputPath -Append -Encoding UTF8

# --- Basic Adapter Summary ---
Add-Section "Network Adapters (Up)"
try {
    Get-NetAdapter |
        Where-Object { $_.Status -eq "Up" } |
        Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed, MacAddress |
        Format-Table -AutoSize |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect adapter information: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- Full Adapter List ---
Add-Section "All Network Adapters"
try {
    Get-NetAdapter |
        Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed, DriverVersion |
        Format-Table -AutoSize |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect full adapter list: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- IP Configuration ---
Add-Section "IP Configuration (Get-NetIPConfiguration)"
try {
    Get-NetIPConfiguration |
        Format-List |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect IP configuration: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- DNS Servers ---
Add-Section "DNS Client Server Addresses"
try {
    Get-DnsClientServerAddress |
        Select-Object InterfaceAlias, AddressFamily, ServerAddresses |
        Format-Table -AutoSize |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect DNS server information: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- Routing Table (IPv4) ---
Add-Section "Routing Table (IPv4)"
try {
    Get-NetRoute -AddressFamily IPv4 |
        Sort-Object DestinationPrefix, InterfaceIndex |
        Format-Table -AutoSize |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect routing table: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- ARP Table (IPv4 Neighbors) ---
Add-Section "ARP Table / Neighbors (IPv4)"
try {
    Get-NetNeighbor -AddressFamily IPv4 |
        Sort-Object IPAddress |
        Format-Table -AutoSize |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect neighbor information: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- Wireless Info (if applicable) ---
Add-Section "Wireless (netsh wlan show interfaces)"
try {
    netsh wlan show interfaces |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect wireless interface info: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

Add-Section "Wireless Networks (netsh wlan show networks mode=bssid)"
try {
    netsh wlan show networks mode=bssid |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect wireless network info: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- Connectivity Tests ---
Add-Section "Connectivity Tests (Test-Connection)"
foreach ($target in $TestTargets) {
    "Target: $target" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
    try {
        $result = Test-Connection -ComputerName $target -Count 3 -Quiet -ErrorAction SilentlyContinue
        if ($result) {
            "  Result: Reachable" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
        } else {
            "  Result: Unreachable or blocked" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
        }
    } catch {
        "  Error testing connectivity: $($_.Exception.Message)" |
            Out-File -FilePath $OutputPath -Append -Encoding UTF8
    }
    "" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

Write-Host ""
Write-Host "Done. Network report written to:"
Write-Host "  $OutputPath"
Write-Host ""
Write-Host "You can send this file to your technician for review."
