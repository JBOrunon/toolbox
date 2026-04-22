# DMS — Dead Man Switch

> ## ⚠ WARNING — DESTRUCTIVE SCRIPT
>
> **This script permanently destroys data. There is no undo, no recycle bin, no recovery.**
>
> When triggered, `PS-DMS.ps1` overwrites every file in your reference list with random
> bytes, then zeros, then deletes them. Files wiped this way are **not recoverable** by
> normal means, including from the Recycle Bin or standard recovery tools.
>
> **Do not deploy this script unless you fully understand what it does and have verified
> your reference file contains exactly what you intend to destroy.**
>
> Misconfiguration — a wrong path, a typo, a reference file pointed at the wrong
> location — can result in permanent loss of files you did not intend to wipe.
> Test in a controlled environment with expendable data before live deployment.

Wipes targeted files and folders if a scheduled security check goes unanswered.

## How it works

`PS-DMS.ps1` runs on a schedule during business hours (Mon–Fri, 8am–5pm). Each run:

1. Checks a binary flag stored in the registry
2. **Flag = 1 (armed):** Displays a password prompt with a countdown timer
   - Correct password → logs success, exits. Flag stays at 1.
   - Wrong password or timeout → sets flag to 0, shows a toast notification. No wipe yet.
3. **Flag = 0 (triggered):** Wipes all paths listed in your reference file, then shows a
   completion toast. Flag stays at 0 until you manually re-arm with `PS-DMSReset.ps1`.

The intended scenario is a machine that was stolen or seized while you were logged in.
Each missed check increments toward a wipe — one wrong answer sets the flag, the next
scheduled run executes it.

---

## First-time setup

### 1. Run PS-DMSSetup.ps1

Open an elevated PowerShell window and run:

```powershell
.\PS-DMSSetup.ps1
```

This creates the registry key at `HKCU:\Software\JBOrunon\DMS`, sets the initial flag
to 1, and prompts you to set a security password. The password is hashed with SHA-256
and stored in the registry — the plaintext is never saved anywhere.

To change your password later, just re-run `PS-DMSSetup.ps1`.

---

### 2. Create your reference file

Copy `DMSReference-example.txt` to `C:\DMS\DMSReference.txt` and edit it to list the
files and folders you want wiped. One path per line. Lines starting with `#` are comments.

```
C:\Users\YourName\Documents\PersonalFolder
C:\Users\YourName\AppData\Roaming\SomeApp
C:\Users\YourName\Desktop\SensitiveFile.txt
```

The reference file path can be overridden with the `-ReferenceFile` parameter if you
prefer a different location.

---

### 3. Configure Task Scheduler

`PS-DMS.ps1` must run as the logged-in user (it shows a GUI prompt and only needs to
access user-profile files).

**Create a new task with these settings:**

| Setting | Value |
|---|---|
| **General → Security options** | Run only when user is logged on |
| **General → Run with highest privileges** | Checked |
| **Trigger** | On a schedule — repeat every 2–4 hours during your working hours |
| **Action → Program/script** | `powershell.exe` |
| **Action → Arguments** | `-NonInteractive -File "C:\path\to\PS-DMS.ps1"` |

The `-TimeoutSeconds` parameter defaults to 60. To change it:

```
-NonInteractive -File "C:\path\to\PS-DMS.ps1" -TimeoutSeconds 90
```

---

## Re-arming after a wipe or deliberate disarm

Run `PS-DMSReset.ps1` in an elevated PowerShell window:

```powershell
.\PS-DMSReset.ps1
```

This sets the flag back to 1. The script also logs the reset to `C:\jb\logs\`.

---

## Disarming temporarily

To pause DMS without running a wipe, set the flag to a value above 1. Flag values
greater than 1 cause the script to exit without prompting or wiping.

From an elevated PowerShell window:

```powershell
Set-ItemProperty -Path "HKCU:\Software\JBOrunon\DMS" -Name "Flag" -Value 2
```

Set it back to 1 with `PS-DMSReset.ps1` when you want to re-arm.

---

## Log output

All activity is logged to `C:\jb\logs\DMS-MMDDYY.log`. A new log file is created each day.
The log is only created if something happens during that day's run (authentication, flag
change, or wipe).
