# toolbox
Toolbox of various IT Tools, including scripts, programs, ISOs, drivers, etc

--------------------------------------------------------------------------------------------------------------

## Windows: PS-GetSystemInfo.ps1

Collects basic system information (OS, hardware, disks, network, recent hotfixes)
and writes a text report to a file.

### Download

In **PowerShell**:

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-GetSystemInfo.ps1" `
  -OutFile ".\PS-GetSystemInfo.ps1"
```

--------------------------------------------------------------------------------------------------------------

## Windows: PS-GetNetworkInfo.ps1

Collects network-related information for troubleshooting:

- Active and all network adapters
- IP configuration
- DNS client server addresses
- IPv4 routing table
- ARP / neighbor table
- Wireless interfaces and visible networks
- Basic connectivity tests to a few common targets

### Download

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-GetNetworkInfo.ps1" `
  -OutFile ".\PS-GetNetworkInfo.ps1"
```

--------------------------------------------------------------------------------------------------------------

## Windows: PS-PrepToolbox.ps1

Prepares a clean working folder for toolbox scripts.

What it does:

- Creates a working directory (default: `%TEMP%\YohanToolbox`)
- Writes a `README.txt` explaining what the folder is for
- Optionally downloads other toolbox scripts into that directory
- Does **not** make any machine-wide changes (no registry, no global ExecutionPolicy changes)

### Download

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-PrepToolbox.ps1" `
  -OutFile ".\PS-PrepToolbox.ps1"
```

--------------------------------------------------------------------------------------------------------------

