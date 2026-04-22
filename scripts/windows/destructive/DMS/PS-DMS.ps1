#Requires -RunAsAdministrator
<#
.TITLE
    PS-DMS

.AUTHOR
    JBOrunon

.WRITTEN
    2020-09-01

.MODIFIED
    2026-04-22 — promoted to toolbox as v0.9; full rewrite from v0.4; binary registry flag
                 replacing txt file; SHA-256 password auth; WinForms timed prompt; WinRT
                 toast notifications; pure-PowerShell secure deletion; reference file for
                 wipe targets; fixed string-vs-integer flag comparison; removed MessageBox,
                 email, MDM wipe, and local account manipulation

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Dead Man Switch — wipes targeted files if a scheduled security check is not answered.

.DESCRIPTION
    Runs on a schedule via Task Scheduler during business hours (Mon-Fri, 8am-5pm).
    On each run, reads a binary flag from the registry:

      Flag = 1 (armed): Displays a timed password prompt. Correct answer logs success
             and exits. Wrong answer or timeout sets the flag to 0 and shows a toast
             notification. No wipe occurs immediately.

      Flag = 0 (triggered): Wipes all paths listed in the reference file using
             overwrite-then-delete, then shows a completion toast. Flag remains 0
             until manually reset with PS-DMSReset.ps1.

    Designed to run only when the user is logged on. See README.md for Task Scheduler
    setup, first-time initialization, and reference file format.

.REQUIRES
    PowerShell 5.1+, Windows 10/11, local administrator account.
    Run PS-DMSSetup.ps1 before first use.

.REPO
    https://github.com/JBOrunon/toolbox
#>

param (
    [string]$ReferenceFile  = "C:\DMS\DMSReference.txt",
    [int]$TimeoutSeconds     = 60
)

$RegPath    = "HKCU:\Software\JBOrunon\DMS"
$dateSuffix = (Get-Date).ToString("MMddyy")
$LogFile    = "C:\jb\logs\DMS-$dateSuffix.log"

if (-not (Test-Path "C:\jb\logs")) { New-Item -ItemType Directory -Path "C:\jb\logs" | Out-Null }

function Write-DMSLog {
    param ([string]$Message)
    $ts = (Get-Date).ToString("MMddyy:HHmm")
    Add-Content -Path $LogFile -Value "$ts - $Message"
}

function Test-BusinessHours {
    $now = Get-Date
    if ($now.DayOfWeek -in @('Saturday', 'Sunday')) { return $false }
    if ($now.Hour -lt 8 -or $now.Hour -gt 17) { return $false }
    return $true
}

function Get-DMSFlag {
    try {
        return (Get-ItemProperty -Path $RegPath -Name "Flag" -ErrorAction Stop).Flag
    } catch {
        return $null
    }
}

function Set-DMSFlag {
    param ([int]$Value)
    Set-ItemProperty -Path $RegPath -Name "Flag" -Value $Value -Type DWord
}

function Get-PasswordHash {
    param ([string]$Password)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Password)
    $hash  = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash) -replace '-', ''
}

function Test-DMSPassword {
    param ([string]$Input)
    if ([string]::IsNullOrEmpty($Input)) { return $false }
    try {
        $stored = (Get-ItemProperty -Path $RegPath -Name "AuthHash" -ErrorAction Stop).AuthHash
        return (Get-PasswordHash $Input) -eq $stored
    } catch {
        return $false
    }
}

function Show-DMSPrompt {
    param ([int]$Timeout)
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form                 = New-Object System.Windows.Forms.Form
    $form.Text            = "Security Check"
    $form.Size            = New-Object System.Drawing.Size(360, 160)
    $form.StartPosition   = "CenterScreen"
    $form.TopMost         = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox     = $false
    $form.MinimizeBox     = $false
    $form.Tag             = @{ Count = $Timeout; Timeout = $false }

    $label          = New-Object System.Windows.Forms.Label
    $label.Text     = "Enter security code. ($Timeout seconds remaining)"
    $label.Location = New-Object System.Drawing.Point(10, 15)
    $label.Size     = New-Object System.Drawing.Size(330, 20)
    $form.Controls.Add($label)

    $textbox                      = New-Object System.Windows.Forms.TextBox
    $textbox.UseSystemPasswordChar = $true
    $textbox.Location             = New-Object System.Drawing.Point(10, 45)
    $textbox.Size                 = New-Object System.Drawing.Size(330, 22)
    $form.Controls.Add($textbox)

    $button              = New-Object System.Windows.Forms.Button
    $button.Text         = "OK"
    $button.Location     = New-Object System.Drawing.Point(140, 80)
    $button.Size         = New-Object System.Drawing.Size(80, 28)
    $button.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton   = $button
    $form.Controls.Add($button)

    $timer          = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
        $form.Tag.Count--
        $label.Text = "Enter security code. ($($form.Tag.Count) seconds remaining)"
        if ($form.Tag.Count -le 0) {
            $timer.Stop()
            $form.Tag.Timeout = $true
            $form.Close()
        }
    })

    $timer.Start()
    $dialogResult = $form.ShowDialog()
    $timer.Stop()

    if ($form.Tag.Timeout -or $dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }
    return $textbox.Text
}

function Show-DMSToast {
    param ([string]$Message)
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        $xml   = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(
                     [Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        $nodes = $xml.GetElementsByTagName("text")
        $nodes[0].AppendChild($xml.CreateTextNode("DMS Security")) | Out-Null
        $nodes[1].AppendChild($xml.CreateTextNode($Message))        | Out-Null
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("DMS Security").Show($toast)
    } catch { }
}

function Remove-SecureFile {
    param ([string]$Path)
    if (-not (Test-Path $Path -PathType Leaf)) { return }
    try {
        $length = (Get-Item $Path).Length
        if ($length -gt 0) {
            $rng    = [System.Security.Cryptography.RandomNumberGenerator]::Create()
            $buffer = New-Object byte[] $length
            $rng.GetBytes($buffer)
            [System.IO.File]::WriteAllBytes($Path, $buffer)
            [System.IO.File]::WriteAllBytes($Path, (New-Object byte[] $length))
        }
        Remove-Item $Path -Force
        Write-DMSLog "Wiped: $Path"
    } catch {
        Write-DMSLog "Failed to wipe: $Path — $($_.Exception.Message)"
    }
}

function Remove-SecurePath {
    param ([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-DMSLog "Not found (skipped): $Path"
        return
    }
    if (Test-Path $Path -PathType Leaf) {
        Remove-SecureFile -Path $Path
    } else {
        Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
            Remove-SecureFile -Path $_.FullName
        }
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
        Write-DMSLog "Removed folder: $Path"
    }
}

function Invoke-Wipe {
    Write-DMSLog "Wipe initiated"
    if (-not (Test-Path $ReferenceFile)) {
        Write-DMSLog "Reference file not found: $ReferenceFile"
        return
    }
    Get-Content $ReferenceFile |
        Where-Object { $_.Trim() -ne '' -and -not $_.TrimStart().StartsWith('#') } |
        ForEach-Object { Remove-SecurePath -Path $_.Trim() }
    Write-DMSLog "Wipe complete"
}

# ── Main ──────────────────────────────────────────────────────────────────────

if (-not (Test-BusinessHours)) { exit }

$flag = Get-DMSFlag
if ($null -eq $flag) {
    Write-DMSLog "Registry not initialized — run PS-DMSSetup.ps1"
    exit
}

if ($flag -eq 1) {
    Write-DMSLog "Flag 1 — prompting for authentication"
    $answer = Show-DMSPrompt -Timeout $TimeoutSeconds
    if (Test-DMSPassword $answer) {
        Write-DMSLog "Authentication successful"
    } else {
        Write-DMSLog "Authentication failed — flag set to 0"
        Set-DMSFlag 0
        Show-DMSToast "DMS flag set to 0. Wipe will run on next scheduled check."
    }
} elseif ($flag -eq 0) {
    Write-DMSLog "Flag 0 — initiating wipe"
    Show-DMSToast "DMS wipe initiated."
    Invoke-Wipe
    Show-DMSToast "DMS wipe complete. Run PS-DMSReset.ps1 to re-arm."
} else {
    Write-DMSLog "Unexpected flag value: $flag — exiting"
}
