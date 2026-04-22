# Ace Backup Scripts

## Overview

| Script | What it does |
|---|---|
| `PS-DailyAce.ps1` | Copies a defined list of folders to a verified external drive |
| `PS-LadyAce.ps1` | Same as DailyAce, plus a System Restore Point and full system image backup via `wbadmin` |

Both scripts identify the target drive by its Windows Volume GUID rather than a drive letter,
so they work reliably even when the drive isn't consistently connected or always assigned the
same letter.

---

## Setup

### 1. Find your drive's Volume GUID

Connect the target drive, then run this in an elevated PowerShell window:

```powershell
Get-Volume | Select-Object DriveLetter, FileSystemLabel, UniqueId
```

The `UniqueId` column is the Volume GUID. It looks like:

```
\\?\Volume{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}\
```

Copy the full string including the leading `\\?\Volume{` and trailing `}\`. You will need it
for the Task Scheduler argument.

---

### 2. Create your reference file

Create a plain text file listing one source folder path per line. Use the example files as
a starting point:

- `DailyAceReference-example.txt` — for DailyAce
- `LadyAceReference-example.txt` — for LadyAce

By default the scripts expect the reference file at `C:\Ace\DailyAce\DailyAceReference.txt`
and `C:\Ace\LadyAce\LadyAceReference.txt`. This can be overridden with the `-DailyAceReference`
or `-LadyAceReference` parameters.

---

### 3. Configure Task Scheduler

Both scripts are designed to run on a schedule via Windows Task Scheduler.

**Account requirements:**
- The task must run as a **local administrator account** (not a standard user with elevation)
- Set **"Run whether user is logged on or not"**
- Set **"Run with highest privileges"**

**Action settings:**

| Field | Value |
|---|---|
| Program/script | `powershell.exe` |
| Arguments (DailyAce) | `-NonInteractive -File "C:\path\to\PS-DailyAce.ps1" -TargetVolumeId "\\?\Volume{your-guid-here}\"` |
| Arguments (LadyAce) | `-NonInteractive -File "C:\path\to\PS-LadyAce.ps1" -TargetVolumeId "\\?\Volume{your-guid-here}\"` |

Replace `C:\path\to\` with the actual script location and `your-guid-here` with the GUID
from Step 1.

**If scripts fail to run:** PowerShell's execution policy may be blocking them. Run this once
in an elevated PowerShell window to allow local scripts:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

### 4. Log output

Both scripts write failure logs to `C:\jb\logs\`. The log file is only created if there are
errors. The `PS-PrepToolbox.ps1` script in this repo creates the `C:\jb\logs\` directory if
it does not already exist; alternatively the scripts will create it on first run.

---

## Restoring from a LadyAce backup

The system image created by `PS-LadyAce.ps1` is stored in a `WindowsImageBackup` folder
on the external drive (and a local copy under `C:\Ace\LadyAce\`). To restore:

1. Boot from Windows installation media (USB)
2. Choose **Repair your computer** > **Troubleshoot** > **System Image Recovery**
3. Point it at the `WindowsImageBackup` folder on the external drive

---

## Migrating from the PIN-based version (pre-v2)

Prior versions identified the target drive using a targeting file (`DailyAceTargeting.txt` /
`LadyAceTargeting.txt`) placed in the drive root, with a PIN on the last line. This mechanism
has been replaced by Volume GUID identification.

Once you have updated your Task Scheduler tasks to use `-TargetVolumeId`, the targeting files
on your drives are no longer needed and can be deleted.
