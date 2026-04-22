#Requires -RunAsAdministrator
<#
.TITLE
    PS-DailyAce

.AUTHOR
    JBOrunon

.WRITTEN
    2024-12-18

.MODIFIED
    2026-04-22 — promoted to toolbox; stripped private info; conventions and header applied;
                 PIN made mandatory; log moved to C:\jb\logs\

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Copies a defined list of folders to a verified external drive.

.DESCRIPTION
    Finds an external drive by looking for a target identification file (DailyAceTargeting.txt)
    and verifying a PIN on its last line. Copies each folder listed in the reference file into
    a HOSTNAME-DailyAce folder on that drive. Failures are logged to C:\jb\logs\.

    Designed for scheduled execution via Windows Task Scheduler. The task must run under a
    local administrator account with "Run whether user is logged on or not" and "Run with
    highest privileges" enabled. Pass -DailyAcePin as an argument in the Task Scheduler action.

    The target drive must contain a file named DailyAceTargeting.txt with the PIN on its last
    line. See DailyAceReference-example.txt for the expected reference file format.

.REQUIRES
    PowerShell 5.1+, local administrator account, target drive with DailyAceTargeting.txt

.REPO
    https://github.com/JBOrunon/toolbox
#>

param (
    [string]$LocalDailyAce = "C:\Ace\DailyAce",
    [string]$DailyAceReference = "$LocalDailyAce\DailyAceReference.txt",
    [string]$DailyAceTarget = "DailyAceTargeting.txt",
    [Parameter(Mandatory)]
    [string]$DailyAcePin,
    [string]$ExternalFolderName = "External-DailyAce"
)

$dateSuffix = (Get-Date).ToString("MMddyy")
$DailyAceLog = "C:\jb\logs\DailyAce-CopyFailures-$dateSuffix.log"
$HostName = $env:COMPUTERNAME
$DailyAceFolderName = "$HostName-DailyAce"

function Get-DestinationDrive {
    $drives = Get-PSDrive -PSProvider FileSystem
    foreach ($drive in $drives) {
        $targetFilePath = "$($drive.Root)\$DailyAceTarget"
        if (Test-Path $targetFilePath) {
            $lines = Get-Content -Path $targetFilePath
            $pin = $lines[-1]
            if ($pin -eq $DailyAcePin) {
                return $drive.Root
            } else {
                $global:failures += "PIN verification failed for drive $($drive.Root)."
            }
        }
    }
    throw "Destination drive with ID file '$DailyAceTarget' and valid PIN not found."
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

$global:failures = @()
if (-not (Test-Path "C:\jb\logs")) { New-Item -ItemType Directory -Path "C:\jb\logs" | Out-Null }
if (Test-Path $DailyAceLog) { Remove-Item $DailyAceLog }

try {
    $destinationDrive = Get-DestinationDrive
    $DailyAcePath = Join-Path -Path $destinationDrive -ChildPath $DailyAceFolderName
    $externalPath = Join-Path -Path $destinationDrive -ChildPath $ExternalFolderName
    if (-not (Test-Path $DailyAcePath)) { New-Item -ItemType Directory -Path $DailyAcePath }
    if (-not (Test-Path $externalPath)) { New-Item -ItemType Directory -Path $externalPath }
    if (-not (Test-Path $LocalDailyAce)) { New-Item -ItemType Directory -Path $LocalDailyAce }
} catch {
    $global:failures += $_.Exception.Message
    $global:failures | Out-File -FilePath $DailyAceLog
    exit
}

$folders = Get-Content -Path $DailyAceReference
$totalFolders = $folders.Count
$currentFolderIndex = 0
$startTime = Get-Date

foreach ($folder in $folders) {
    $currentFolderIndex++
    $destFolder = Join-Path -Path $DailyAcePath -ChildPath (Split-Path -Path $folder -Leaf)

    $progressPercentage = [math]::Round(($currentFolderIndex / $totalFolders) * 100, 2)
    $elapsedTime = (Get-Date) - $startTime
    $estimatedTotalTime = [timespan]::FromTicks(($elapsedTime.Ticks / $currentFolderIndex) * $totalFolders)
    $estimatedRemainingTime = $estimatedTotalTime - $elapsedTime
    Write-Progress -Activity "Copying folders" -Status "Processing $currentFolderIndex of $totalFolders" -PercentComplete $progressPercentage -SecondsRemaining $estimatedRemainingTime.Seconds

    Copy-FolderContents -sourceFolder $folder -destinationFolder $destFolder
}

if ($global:failures.Count -gt 0) {
    $global:failures | Out-File -FilePath $DailyAceLog
}
