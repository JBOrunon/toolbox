#Requires -RunAsAdministrator
<#
.TITLE
    PS-LadyAce

.AUTHOR
    JBOrunon

.WRITTEN
    2024-05-28

.MODIFIED
    2026-04-22 — promoted to toolbox; stripped private info; conventions and header applied;
                 PIN made mandatory; log moved to C:\jb\logs\; replaced deprecated WMI with
                 Checkpoint-Computer; fixed backup search path, undefined $backupImagePath,
                 and double-Move bug; backup preserved as .vhdx (WindowsImageBackup structure)

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Copies a defined list of folders to a verified external drive and creates a full system image backup.

.DESCRIPTION
    Finds an external drive by looking for a target identification file (LadyAceTargeting.txt)
    and verifying a PIN on its last line. Copies each folder listed in the reference file into
    a HOSTNAME-LadyAce folder on that drive. Also creates a Windows System Restore Point and a
    full system image backup using wbadmin. The WindowsImageBackup folder structure is copied to
    both the external LadyAce folder and to local storage. Failures are logged to C:\jb\logs\.

    Designed for scheduled execution via Windows Task Scheduler. The task must run under a
    local administrator account with "Run whether user is logged on or not" and "Run with
    highest privileges" enabled. Pass -LadyAcePin as an argument in the Task Scheduler action.

    The target drive must contain a file named LadyAceTargeting.txt with the PIN on its last
    line. System Restore must be enabled on C:\ for the restore point step to succeed.
    See LadyAceReference-example.txt for the expected reference file format.

.REQUIRES
    PowerShell 5.1+, local administrator account, target drive with LadyAceTargeting.txt

.REPO
    https://github.com/JBOrunon/toolbox
#>

param (
    [string]$LocalLadyAce = "C:\Ace\LadyAce",
    [string]$LadyAceReference = "$LocalLadyAce\LadyAceReference.txt",
    [string]$LadyAceTarget = "LadyAceTargeting.txt",
    [Parameter(Mandatory)]
    [string]$LadyAcePin,
    [string]$ExternalFolderName = "External-LadyAce"
)

$dateSuffix = (Get-Date).ToString("MMddyy")
$LadyAceLog = "C:\jb\logs\LadyAce-CopyFailures-$dateSuffix.log"
$HostName = $env:COMPUTERNAME
$LadyAceFolderName = "$HostName-LadyAce"

function Get-DestinationDrive {
    $drives = Get-PSDrive -PSProvider FileSystem
    foreach ($drive in $drives) {
        $targetFilePath = "$($drive.Root)\$LadyAceTarget"
        if (Test-Path $targetFilePath) {
            $lines = Get-Content -Path $targetFilePath
            $pin = $lines[-1]
            if ($pin -eq $LadyAcePin) {
                return $drive.Root
            } else {
                $global:failures += "PIN verification failed for drive $($drive.Root)."
            }
        }
    }
    throw "Destination drive with ID file '$LadyAceTarget' and valid PIN not found."
}

function Copy-FolderContents {
    param (
        [string]$sourceFolder,
        [string]$destinationFolder
    )
    try {
        Get-ChildItem -Path $sourceFolder -Recurse | ForEach-Object {
            $destPath = $_.FullName.Replace($sourceFolder, $destinationFolder)
            if ($_.PSIsContainer) {
                if (-not (Test-Path $destPath)) {
                    New-Item -ItemType Directory -Path $destPath
                }
            } else {
                Copy-Item -Path $_.FullName -Destination $destPath -Force -ErrorAction Stop
            }
        }
    } catch {
        $global:failures += "$sourceFolder to $destinationFolder : $($_.Exception.Message)"
    }
}

function Create-SystemRestorePoint {
    param ([string]$description)
    try {
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"
    } catch {
        $global:failures += "Failed to create system restore point: $($_.Exception.Message)"
    }
}

function Create-SystemImageBackup {
    param (
        [string]$destinationDrive,
        [string]$ladyAcePath,
        [string]$localBackupPath
    )
    try {
        wbadmin start backup -backupTarget:$destinationDrive -include:C: -allCritical -quiet

        $backupSource = Join-Path -Path $destinationDrive -ChildPath "WindowsImageBackup"
        $vhdxFiles = Get-ChildItem -Path $backupSource -Filter "*.vhdx" -Recurse -ErrorAction SilentlyContinue

        if ($null -eq $vhdxFiles -or $vhdxFiles.Count -eq 0) {
            throw "System image backup not found at '$backupSource'."
        }

        Copy-Item -Path $backupSource -Destination (Join-Path -Path $ladyAcePath -ChildPath "WindowsImageBackup") -Recurse -Force
        Copy-Item -Path $backupSource -Destination (Join-Path -Path $localBackupPath -ChildPath "WindowsImageBackup") -Recurse -Force
    } catch {
        $global:failures += "Exception during system image backup: $($_.Exception.Message)"
    }
}

$global:failures = @()
if (-not (Test-Path "C:\jb\logs")) { New-Item -ItemType Directory -Path "C:\jb\logs" | Out-Null }
if (Test-Path $LadyAceLog) { Remove-Item $LadyAceLog }

try {
    $destinationDrive = Get-DestinationDrive
    $ladyAcePath = Join-Path -Path $destinationDrive -ChildPath $LadyAceFolderName
    $externalPath = Join-Path -Path $destinationDrive -ChildPath $ExternalFolderName
    if (-not (Test-Path $ladyAcePath)) { New-Item -ItemType Directory -Path $ladyAcePath }
    if (-not (Test-Path $externalPath)) { New-Item -ItemType Directory -Path $externalPath }
    if (-not (Test-Path $LocalLadyAce)) { New-Item -ItemType Directory -Path $LocalLadyAce }
} catch {
    $global:failures += $_.Exception.Message
    $global:failures | Out-File -FilePath $LadyAceLog
    exit
}

$folders = Get-Content -Path $LadyAceReference
$totalFolders = $folders.Count
$currentFolderIndex = 0
$startTime = Get-Date

foreach ($folder in $folders) {
    $currentFolderIndex++
    $destFolder = Join-Path -Path $ladyAcePath -ChildPath (Split-Path -Path $folder -Leaf)

    $progressPercentage = [math]::Round(($currentFolderIndex / $totalFolders) * 100, 2)
    $elapsedTime = (Get-Date) - $startTime
    $estimatedTotalTime = [timespan]::FromTicks(($elapsedTime.Ticks / $currentFolderIndex) * $totalFolders)
    $estimatedRemainingTime = $estimatedTotalTime - $elapsedTime
    Write-Progress -Activity "Copying folders" -Status "Processing $currentFolderIndex of $totalFolders" -PercentComplete $progressPercentage -SecondsRemaining $estimatedRemainingTime.Seconds

    Copy-FolderContents -sourceFolder $folder -destinationFolder $destFolder
}

Create-SystemRestorePoint -description "LadyAce scheduled backup"

Create-SystemImageBackup -destinationDrive $destinationDrive -ladyAcePath $ladyAcePath -localBackupPath $LocalLadyAce

if ($global:failures.Count -gt 0) {
    $global:failures | Out-File -FilePath $LadyAceLog
}
