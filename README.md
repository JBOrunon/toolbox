# Toolbox

Scripts and utilities I use for troubleshooting, setup, and automation —
on machines I own and machines I don't.

Scripts here do a range of things: diagnostics, installs, configuration, downloads.
What they have in common: they're **plain text, auditable, and documented**.
Read before you run.

> **Important:** Nothing in this repo is obfuscated. If it ever looks unexpectedly
> complex or suspicious, treat it as untrusted until reviewed.

----------------------------------------------------------------------------------------------------------------------

## Structure

```
scripts/
  linux/
    diagnostics/    — read-only info gathering and reporting
    setup/          — installs, configuration, prep
    tools/          — general-purpose utility actions
  windows/
    diagnostics/
    setup/
    tools/
  macos/
    diagnostics/
    setup/
    tools/
```

----------------------------------------------------------------------------------------------------------------------

## Quick start

### Windows

**Prepare a working folder and download tools**

1. In **PowerShell** on the target machine:

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/setup/PS-PrepToolbox.ps1" `
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
  https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/linux/setup/LX-PrepToolbox.sh \
  -o LX-PrepToolbox.sh

chmod +x LX-PrepToolbox.sh
./LX-PrepToolbox.sh --download-tools
```

This will:
- Create a working directory (default: $HOME/jb)
- Write a README.txt into that folder
- Download these Linux tools into $HOME/jb:
	- LX-GetSystemInfo.sh
	- LX-GetNetworkInfo.sh

2. Run the tools from $HOME/jb

```bash
cd "${HOME}/jb"

./LX-GetSystemInfo.sh
./LX-GetNetworkInfo.sh
```

Each script writes a timestamped report under $HOME/jb.

----------------------------------------------------------------------------------------------------------------------

## Tool index

### Windows — diagnostics

- **PS-GetSystemInfo.ps1** — Collects OS, hardware, disk, and basic network information into a report under C:\jb.
- **PS-GetNetworkInfo.ps1** — Collects adapter, IP, DNS, route, wireless, and connectivity information into a report under C:\jb.

### Windows — tools

- **PS-ScheduleShutdown.ps1** — Schedules a forced shutdown after a configurable number of hours (default: 2). Supports -Cancel to abort.

### Windows — setup

- **PS-PrepToolbox.ps1** — Prepares C:\jb, writes README.txt, and can download Windows diagnostic scripts.
- **PS-GetSoftwareOKTools.ps1** — Downloads selected freeware tools by Nenad Hrg / SoftwareOK into C:\jb\softwareok.

### Linux — diagnostics

- **LX-GetSystemInfo.sh** — Collects OS/CPU/memory/disk information into a report under $HOME/jb.
- **LX-GetNetworkInfo.sh** — Collects interface, route, DNS, hosts, and connectivity information into a report under $HOME/jb.

### Linux — setup

- **LX-PrepToolbox.sh** — Prepares $HOME/jb, writes README.txt, and can download Linux diagnostic scripts.
- **LX-InstallObsidian.sh** — Downloads and installs the latest Obsidian AppImage for the current architecture.

----------------------------------------------------------------------------------------------------------------------

## Security & trust model

- Scripts are plain text — no obfuscation, no compiled binaries
- Read a script before running it; nothing here requires blind trust
- Default output goes under C:\jb (Windows) or $HOME/jb (Linux) — easy to find and clean up
- Scripts that require elevated privileges say so explicitly

----------------------------------------------------------------------------------------------------------------------

# If something in this repo ever looks unexpectedly complex or suspicious, assume it is untrusted until reviewed.
