<#
.SYNOPSIS
  Collects basic system information for troubleshooting.

.DESCRIPTION
  Generates a text report with OS, hardware, disk, and network info.
  Intended to be safe and readable so users (or you) can review what it does.

.REPO
  https://github.com/JBOrunon/toolbox
#>

param(
    [string]$OutputPath
)

# If no output path is specified, write to the current directory
if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $fileName = "SystemInfo-$($env:COMPUTERNAME)-$timestamp.txt"
    $OutputPath = Join-Path -Path (Get-Location) -ChildPath $fileName
}

Write-Host "Generating system information report..."
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
"System Information Report" | Out-File -FilePath $OutputPath -Encoding UTF8
"Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
"Computer: $($env:COMPUTERNAME)" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
"User: $($env:USERNAME)`r`n" | Out-File -FilePath $OutputPath -Append -Encoding UTF8

# --- OS Info ---
Add-Section "Operating System"
try {
    Get-CimInstance Win32_OperatingSystem |
        Select-Object Caption, Version, BuildNumber, InstallDate |
        Format-List |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect OS information: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- Hardware Info ---
Add-Section "Hardware"
try {
    "CPU:" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
    Get-CimInstance Win32_Processor |
        Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed |
        Format-List |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8

    "`r`nMemory (Physical):" | Out-File -FilePath $OutputPath -Append -Encoding UTF8
    Get-CimInstance Win32_PhysicalMemory |
        Select-Object Manufacturer, PartNumber, @{Name="CapacityGB";Expression={[math]::Round($_.Capacity / 1GB,2)}} |
        Format-Table -AutoSize |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect hardware information: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- Disk Info ---
Add-Section "Disks & Volumes"
try {
    Get-Volume |
        Select-Object DriveLetter, FileSystemLabel, FileSystem, Size, SizeRemaining, HealthStatus |
        Format-Table -AutoSize |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect volume information: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- Network Adapters ---
Add-Section "Network Adapters (Up)"
try {
    Get-NetAdapter |
        Where-Object {$_.Status -eq "Up"} |
        Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed |
        Format-Table -AutoSize |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect adapter information: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- IP Configuration ---
Add-Section "IP Configuration (ipconfig /all)"
try {
    ipconfig /all |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to run ipconfig: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

# --- Recent Hotfixes ---
Add-Section "Recent Hotfixes (last 20)"
try {
    Get-HotFix |
        Sort-Object InstalledOn -Descending |
        Select-Object -First 20 |
        Format-Table -AutoSize |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
} catch {
    "Failed to collect hotfix information: $($_.Exception.Message)" |
        Out-File -FilePath $OutputPath -Append -Encoding UTF8
}

Write-Host ""
Write-Host "Done. Report written to:"
Write-Host "  $OutputPath"
Write-Host ""
Write-Host "You can send this file to your technician for review."
