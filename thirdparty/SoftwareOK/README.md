# SoftwareOK Utilities

A reference page for a set of excellent freeware utilities written by
**Nenad Hrg** and published on [SoftwareOK.com](https://www.softwareok.com/).

All credit for these tools goes to **Nenad Hrg / SoftwareOK**.

If you find these tools useful, **please support the author**:
- Homepage: <https://www.softwareok.com/>
- Many pages include a "Buy SoftwareOK a Coffee" link — use it!

---

## Available tools

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

---

## Download script

Use the Windows PowerShell script to download any or all of these tools directly from SoftwareOK:

```
scripts/windows/PS-GetSoftwareOKTools.ps1
```

Examples:

```powershell
# Download everything into C:\jb\softwareok
.\PS-GetSoftwareOKTools.ps1 -All

# Download just Q-Dir
.\PS-GetSoftwareOKTools.ps1 -Name QDirInstaller, QDirPortable
```

See the script's built-in help for full usage: `Get-Help .\PS-GetSoftwareOKTools.ps1`

---

## License & attribution

Each tool is freeware under the SoftwareOK EULA (linked from each tool's page).
This repo does not store, redistribute, or claim ownership of any SoftwareOK binaries.
