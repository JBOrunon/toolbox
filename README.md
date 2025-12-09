# Toolbox

Public, non-sensitive scripts and utilities I use for troubleshooting and setup
on machines I don’t own (clients, friends, family, etc.).

This repository is designed to be:

- **Safe to inspect** – scripts are plain text, intended to be readable.
- **Easy to consume** from the command line (PowerShell, curl, etc.).
- **Non-invasive** – tools here avoid making permanent system-wide changes.

> **Important:** Always download a script, read it, and only then run it.  
> Nothing in this repo is obfuscated; if it ever is, treat that as a red flag.

----------------------------------------------------------------------------------------------------------------------

## Quick start

### Windows

**Prepare a working folder and download tools**

1. In **PowerShell** on the target machine:

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-PrepToolbox.ps1" `
  -OutFile ".\PS-PrepToolbox.ps1"

powershell -ExecutionPolicy Bypass -File .\PS-PrepToolbox.ps1 -DownloadTools
```

This will:
- Create a working directory (default: C:\jb)
- Write a README.txt into that folder
- Download these Windows tools into C:\jb:
	- PS-GetSystemInfo.ps1
	- PS-GetNetworkInfo.ps1

2. Run the tools from C:\jb
```powershell
Set-Location C:\jb
# System info report
powershell -ExecutionPolicy Bypass -File .\PS-GetSystemInfo.ps1
# Network info report
powershell -ExecutionPolicy Bypass -File .\PS-GetNetworkInfo.ps1
```

Each script writes a timestamped report under C:\jb, for example:
> C:\jb\SystemInfo-MACHINE-YYYYMMDD-HHMMSS.txt
> C:\jb\NetworkInfo-MACHINE-YYYYMMDD-HHMMSS.txt

----------------------------------------------------------------------------------------------------------------------

### Linux

1. Prep and download tools

```bash
curl -fsSL \
  https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/linux/linux-prep-toolbox.sh \
  -o linux-prep-toolbox.sh

chmod +x linux-prep-toolbox.sh
./linux-prep-toolbox.sh --download-tools
```

This will:
- Create a working directory (default: $HOME/jb)
- Write a README.txt into that folder
- Download these Linux tools into $HOME/jb:
	- linux-get-system-info.sh
	- linux-get-network-info.sh

2. Run the tools from $HOME/jb

```bash
    cd "${HOME}/jb"

    ./linux-get-system-info.sh
    ./linux-get-network-info.sh
```

Each script writes a timestamped report under $HOME/jb.

----------------------------------------------------------------------------------------------------------------------

## Tool index
### Windows

All Windows tools live under scripts/windows

- PS-PrepToolbox.ps1
	Prepares C:\jb, writes README.txt, and can download other Windows toolbox scripts.

- PS-GetSystemInfo.ps1
	Collects OS, hardware, disk, and basic network information into a report under C:\jb.

- PS-GetNetworkInfo.ps1
	Collects adapter, IP, DNS, route, wireless, and connectivity information into a report under C:\jb.

- PS-GetSoftwareOKTools.ps1
	Convenience downloader for selected freeware tools by Nenad Hrg / SoftwareOK,
	saving ZIPs into C:\jb\softwareok. (See scripts/windows/README.md and
	thirdparty/softwareok/README.md for details and attribution.)

### Linux

All Linux tools live under scripts/linux

- linux-prep-toolbox.sh
	Prepares $HOME/jb, writes README.txt, and can download other Linux toolbox scripts.

- linux-get-system-info.sh
	Collects OS/CPU/memory/disk information into a report under $HOME/jb.

- linux-get-network-info.sh
	Collects interface, route, DNS, hosts, and connectivity information into a report under $HOME/jb.

----------------------------------------------------------------------------------------------------------------------

## Security & trust model

- Scripts are intended to be auditable:
    - No obfuscation
    - No silent persistence or registry hacks
- Default behavior:
    - Write reports under C:\jb (Windows) or $HOME/jb (Linux)
    - Avoid machine-wide configuration changes
- Recommended usage:
    - Download the script.
    - Open it in a text editor and review it.
    - Run it with appropriate flags (e.g., ExecutionPolicy Bypass only for that invocation).

----------------------------------------------------------------------------------------------------------------------

# If something in this repo ever looks unexpectedly complex or suspicious, assume it is untrusted until reviewed.