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
    2026-04-22 — v2: replaced PIN/targeting-file drive identification with Volume GUID;
                 removed ExternalFolderName parameter

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Copies a defined list of folders to a verified external drive.

.DESCRIPTION
    Finds an external drive by its Windows Volume GUID and copies each folder listed in the
    reference file into a HOSTNAME-DailyAce folder on that drive. Failures are logged to
    C:\jb\logs\.

    Designed for scheduled execution via Windows Task Scheduler. The task must run under a
    local administrator account with "Run whether user is logged on or not" and "Run with
    highest privileges" enabled. Pass -TargetVolumeId as an argument in the Task Scheduler
    action. See README.md in this folder for setup instructions.

    See DailyAceReference-example.txt for the expected reference file format.

.REQUIRES
    PowerShell 5.1+, local administrator account, target drive Volume GUID

.REPO
    https://github.com/JBOrunon/toolbox
#>

param (
    [string]$LocalDailyAce = "C:\Ace\DailyAce",
    [string]$DailyAceReference = "$LocalDailyAce\DailyAceReference.txt",
    [Parameter(Mandatory)]
    [string]$TargetVolumeId
)

$dateSuffix = (Get-Date).ToString("MMddyy")
$DailyAceLog = "C:\jb\logs\DailyAce-CopyFailures-$dateSuffix.log"
$HostName = $env:COMPUTERNAME
$DailyAceFolderName = "$HostName-DailyAce"

function Get-DestinationDrive {
    param ([string]$volumeId)
    $volume = Get-Volume | Where-Object { $_.UniqueId -eq $volumeId }
    if ($null -eq $volume) {
        throw "Target volume '$volumeId' not found. Ensure the drive is connected."
    }
    if ($null -eq $volume.DriveLetter) {
        throw "Target volume found but has no drive letter assigned."
    }
    return "$($volume.DriveLetter):\"
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
    $destinationDrive = Get-DestinationDrive -volumeId $TargetVolumeId
    $DailyAcePath = Join-Path -Path $destinationDrive -ChildPath $DailyAceFolderName
    if (-not (Test-Path $DailyAcePath)) { New-Item -ItemType Directory -Path $DailyAcePath }
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
