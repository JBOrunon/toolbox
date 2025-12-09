# Windows Toolbox (PowerShell)

Windows-focused scripts intended for troubleshooting and information gathering on
machines I don’t own. Scripts are designed to be:

- **Read-only** (collecting information, not changing config)
- **Auditable** (plain PowerShell, no obfuscation)
- **Consistent** in where they write output

## Requirements

- Windows 10 / Server 2016 or later (typical)
- PowerShell 5.1 or PowerShell 7+
- Internet access (for downloading scripts and, optionally, connectivity tests)

## Conventions

- Default working directory: **`C:\jb`**
- Report files are created under `C:\jb` unless:
  - You specify `-OutputPath`, or
  - You override `-WorkingDirectory` (where available)
- All scripts can be downloaded directly from GitHub using `Invoke-WebRequest`.

--------------------------------------------------------------------------------------------------------------------------

## PS-PrepToolbox.ps1

Prepares a working directory for toolbox scripts.

### Behavior

- Creates a working directory (default: `C:\jb`)
- Writes a `README.txt` into that directory with:
  - Purpose of the folder
  - Links to the GitHub repo and scripts
- Optionally downloads:
  - `PS-GetSystemInfo.ps1`
  - `PS-GetNetworkInfo.ps1`

### Download

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-PrepToolbox.ps1" `
  -OutFile ".\PS-PrepToolbox.ps1"
```

================

## PS-PrepToolbox.ps1

Prepares a working directory for toolbox scripts.

### Behavior

- Creates a working directory (default: `C:\jb`)
- Writes a `README.txt` into that directory with:
  - Purpose of the folder
  - Links to the GitHub repo and scripts
- Optionally downloads:
  - `PS-GetSystemInfo.ps1`
  - `PS-GetNetworkInfo.ps1`

### Download

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-PrepToolbox.ps1" `
  -OutFile ".\PS-PrepToolbox.ps1"
```

### Usage

- Basic (folder + README only):

```powershell 
powershell -ExecutionPolicy Bypass -File .\PS-PrepToolbox.ps1
```

-Full prep (folder + README + download tools):

```powershell
powershell -ExecutionPolicy Bypass -File .\PS-PrepToolbox.ps1 -DownloadTools
```

- Custom working directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\PS-PrepToolbox.ps1 `
  -WorkingDirectory "C:\Temp\YohanToolbox" `
  -DownloadTools
```

--------------------------------------------------------------------------------------------------------------------------

## PS-GetSystemInfo.ps1

Collects general system information into a text report.

### What it collects

- Operating system details (name, version, build, install date)
- CPU and physical memory details
- Volumes (drive letter, filesystem, size, free space, health status)
- Active network adapters
- ipconfig /all output
- Recent hotfixes (last 20)

### Download

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-GetSystemInfo.ps1" `
  -OutFile ".\PS-GetSystemInfo.ps1"
```

### Usage

- Default (writes under C:\jb):

```powershell
powershell -ExecutionPolicy Bypass -File .\PS-GetSystemInfo.ps1
```

This will create a file such as:
> C:\jb\SystemInfo-COMPUTERNAME-YYYYMMDD-HHMMSS.txt

- Explicit output path:

```powershell
powershell -ExecutionPolicy Bypass -File .\PS-GetSystemInfo.ps1 `
  -OutputPath "C:\jb\SystemInfo.txt"
```

- Custom working directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\PS-GetSystemInfo.ps1 `
  -WorkingDirectory "D:\Temp\jb-reports"
```

> Note: If -OutputPath is provided, it takes precedence over -WorkingDirectory.

--------------------------------------------------------------------------------------------------------------------------

## PS-GetNetworkInfo.ps1

Collects network-related information into a text report.

### What it collects
- Active network adapters (name, description, MAC, link speed)
- All network adapters (including driver version)
- IP configuration (Get-NetIPConfiguration)
- DNS client server addresses
- IPv4 routing table (Get-NetRoute)
- ARP / neighbor table (Get-NetNeighbor)
- Wireless interfaces and visible networks (netsh wlan ...)
- Connectivity tests to a list of targets via Test-Connection

### Download

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-GetNetworkInfo.ps1" `
  -OutFile ".\PS-GetNetworkInfo.ps1"
```

### Usage

- Default (writes under C:\jb):

```powershell
powershell -ExecutionPolicy Bypass -File .\PS-GetNetworkInfo.ps1
```

- This will create a file such as:
> C:\jb\NetworkInfo-COMPUTERNAME-YYYYMMDD-HHMMSS.txt

- Explicit output path:

```powershell
powershell -ExecutionPolicy Bypass -File .\PS-GetNetworkInfo.ps1 `
  -OutputPath "C:\jb\NetworkInfo.txt"
```

- Custom working directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\PS-GetNetworkInfo.ps1 `
  -WorkingDirectory "D:\Temp\jb-reports"
```

- Custom connectivity targets:

```powershell
powershell -ExecutionPolicy Bypass -File .\PS-GetNetworkInfo.ps1 `
  -TestTargets "8.8.8.8","1.1.1.1","github.com"
```

--------------------------------------------------------------------------------------------------------------------------

## Getting help from within PowerShell

Each script supports comment-based help. You can read it directly in PowerShell:

> Get-Help .\PS-PrepToolbox.ps1 -Detailed
> Get-Help .\PS-GetSystemInfo.ps1 -Detailed
> Get-Help .\PS-GetNetworkInfo.ps1 -Detailed

This works even if you only have the .ps1 files and no access to GitHub.