# SoftwareOK Utilities (mirror)

This folder mirrors a **small set of excellent freeware utilities** written by  
**Nenad Hrg** and published on [SoftwareOK.com](https://www.softwareok.com/).

All credit for these tools goes to **Nenad Hrg / SoftwareOK**.  
This repo only:

- Keeps a copy of a few ZIPs I personally rely on
- Adds some helper scripts to download fresh copies directly from SoftwareOK
- Provides easy one-liner usage for troubleshooting on client machines

If you find these tools useful, **please support the author**:
- Homepage: <https://www.softwareok.com/>
- Many pages include a “☕ Buy SoftwareOK a Coffee ☕” link — use it! 😊

---

## Tools mirrored here

| Key (for scripts)        | Canonical file name              | Official info page                                               |
|--------------------------|----------------------------------|------------------------------------------------------------------|
| `DeleteOnReboot`         | `Delete.On.Reboot.zip`           | https://www.softwareok.com/?seite=Freeware/Delete.On.Reboot     |
| `DesktopNoteOKInstaller` | `DesktopNoteOK_Installer.zip`    | https://www.softwareok.com/?Download=DesktopNoteOK              |
| `DesktopNoteOKPortable`  | `DesktopNoteOK_Portable.zip`     | https://www.softwareok.com/?Download=DesktopNoteOK              |
| `ThisIsMyFile`           | `ThisIsMyFile.zip`               | https://www.softwareok.com/?Download=ThisIsMyFile               |
| `DirPrintOKInstaller`    | `DirPrintOK_Installer.zip`       | https://www.softwareok.com/?Download=DirPrintOK                 |
| `DirPrintOKPortable`     | `DirPrintOK_Portable.zip`        | https://www.softwareok.com/?Download=DirPrintOK                 |
| `DontSleep`              | `DontSleep.zip`                  | https://www.softwareok.com/?Download=DontSleep                  |
| `DontSleepPortable`      | `DontSleep_Portable.zip`         | https://www.softwareok.com/?Download=DontSleep                  |
| `QDirInstaller`          | `Q-Dir_Installer.zip`            | https://www.softwareok.com/?Download=Q-Dir                      |
| `QDirPortable`           | `Q-Dir_Portable.zip`             | https://www.softwareok.com/?Download=Q-Dir                      |

> **Important:** Always prefer downloading from **SoftwareOK.com** when you can.  
> This mirror is just a convenience / fallback in case access to the official site is blocked or slow.

---

## License & redistribution

Each of these tools is freeware under the SoftwareOK EULA (linked from each tool’s page).  
The license (summarized):

- Says the software is the property of **Hrg Nenad / SoftwareOK**
- Allows you to distribute **unmodified copies** of the software freely
- Disclaims liability for any damage from using the tools

This repo:

- Stores **unmodified ZIPs** exactly as downloaded
- Does **not** change the binaries, icons, or installers
- Does **not** claim ownership or authorship of any SoftwareOK utilities

If you’re using this repo, you agree that:

- You’ll respect the original license for each tool
- You’ll treat this as a convenience cache, not a fork or derivative product

---

## Helper script

On Windows, you can use:

- `scripts/windows/PS-GetSoftwareOKTools.ps1`

to download fresh copies directly from SoftwareOK into `C:\jb\softwareok` (by default).  
See the comment-based help in that script for usage examples.
