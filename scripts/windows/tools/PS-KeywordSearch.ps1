<#
.TITLE
    PS-KeywordSearch

.AUTHOR
    JBOrunon

.WRITTEN
    2023-05-19

.MODIFIED
    2026-04-21 — promoted from .txt; replaced hardcoded paths with parameters,
                 replaced Windows MessageBox with console prompt, standard header

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Recursively searches a folder for files containing keywords from a keyword list.

.DESCRIPTION
    Reads keywords from a text file (one per line) and searches all files under
    SearchPath for any matching content. Writes matching file paths and the keywords
    found to OutputFile. Displays a progress bar during the scan. After completion,
    prompts whether to open the results in Notepad.

.REQUIRES
    PowerShell 5.1+, Windows (any)

.REPO
    https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SearchPath,

    [Parameter(Mandatory)]
    [string]$KeywordFile,

    [string]$OutputFile = "C:\jb\PS-KeywordSearch-Output.txt"
)

# --- Validate inputs ---
if (-not (Test-Path -LiteralPath $SearchPath)) {
    Write-Host "ERROR: SearchPath not found: $SearchPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $KeywordFile)) {
    Write-Host "ERROR: KeywordFile not found: $KeywordFile" -ForegroundColor Red
    exit 1
}

$keywords = Get-Content -Path $KeywordFile | Where-Object { $_.Trim() -ne "" }

if ($keywords.Count -eq 0) {
    Write-Host "ERROR: No keywords found in $KeywordFile" -ForegroundColor Red
    exit 1
}

# --- Ensure output directory exists ---
$outputDir = Split-Path -Parent $OutputFile
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# --- Count files for progress tracking ---
Write-Host "Counting files..." -ForegroundColor Cyan
$allFiles = Get-ChildItem -Path $SearchPath -Recurse -File -Force -ErrorAction SilentlyContinue
$totalFiles = $allFiles.Count

if ($totalFiles -eq 0) {
    Write-Host "No files found under: $SearchPath" -ForegroundColor Yellow
    exit 0
}

Write-Host "Scanning $totalFiles file(s) for $($keywords.Count) keyword(s)..."
Write-Host ""

# --- Search ---
$completedFiles = 0
$results = foreach ($file in $allFiles) {
    $completedFiles++
    $percent = [math]::Round(($completedFiles / $totalFiles) * 100, 2)

    Write-Progress -Activity "Searching files" `
                   -Status "Processed $completedFiles of $totalFiles — $percent%" `
                   -CurrentOperation $file.Name `
                   -PercentComplete $percent

    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $matched = $keywords | Where-Object { $content -match [regex]::Escape($_) }
            if ($matched) {
                [PSCustomObject]@{
                    FilePath = $file.FullName
                    Matches  = '[' + ($matched -join ', ') + ']'
                }
            }
        }
    } catch {
        # Skip unreadable files silently
    }
}

Write-Progress -Activity "Searching files" -Completed

# --- Write output ---
if ($results) {
    $results | ForEach-Object { "$($_.FilePath)  $($_.Matches)" } | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Search complete. $($results.Count) file(s) matched." -ForegroundColor Green
} else {
    "No matches found." | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Search complete. No matches found." -ForegroundColor Yellow
}

Write-Host "Results saved to: $OutputFile"
Write-Host ""

# --- Prompt to open results ---
$open = Read-Host "Open results in Notepad? (Y/N)"
if ($open -match '^[Yy]') {
    Start-Process notepad.exe $OutputFile
}
