# toolbox
Toolbox of various IT Tools, including scripts, programs, ISOs, drivers, etc

## Windows: PS-GetSystemInfo.ps1

Collects basic system information (OS, hardware, disks, network, recent hotfixes)
and writes a text report to a file.

### Download

In **PowerShell**:

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-GetSystemInfo.ps1" `
  -OutFile ".\PS-GetSystemInfo.ps1"
