# Toolbox

Public, non-sensitive scripts and utilities I use for troubleshooting and setup
on machines I don’t own (clients, friends, family, etc.).

This repository is designed to be:

- **Safe to inspect** – scripts are plain text, intended to be readable.
- **Easy to consume** from the command line (PowerShell, curl, etc.).
- **Non-invasive** – tools here avoid making permanent system-wide changes.

> **Important:** Always download a script, read it, and only then run it.  
> Nothing in this repo is obfuscated; if it ever is, treat that as a red flag.

---

## Quick start (Windows, recommended path)

### 1) Prepare a working folder and download tools

In **PowerShell** on the target machine:

```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/windows/PS-PrepToolbox.ps1" `
  -OutFile ".\PS-PrepToolbox.ps1"

powershell -ExecutionPolicy Bypass -File .\PS-PrepToolbox.ps1 -DownloadTools
