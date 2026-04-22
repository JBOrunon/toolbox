<#
.TITLE
    PS-KeepAlive

.AUTHOR
    JBOrunon

.WRITTEN
    2026-04-21

.MODIFIED
    2026-04-21 — promoted from PrintScreen-based original; rewritten using SetThreadExecutionState

.LLM
    Claude Sonnet 4.6

.SYNOPSIS
    Prevents the PC from sleeping or locking the screen while the script is running.

.DESCRIPTION
    Uses the Windows SetThreadExecutionState API to signal that the system and display
    should remain active. No keyboard simulation, no clipboard side effects. Runs until
    the user presses Enter or closes the window. The execution state is automatically
    restored when the script exits.

.REQUIRES
    PowerShell 5.1+, Windows (any)

.REPO
    https://github.com/JBOrunon/toolbox
#>

[CmdletBinding()]
param(
    [int]$IntervalSeconds = 60
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class PowerState {
    [DllImport("kernel32.dll")]
    public static extern uint SetThreadExecutionState(uint esFlags);
}
"@

# ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
$activeFlags = [uint32]0x80000001 -bor [uint32]0x00000002
$resetFlags  = [uint32]0x80000000

try {
    [PowerState]::SetThreadExecutionState($activeFlags) | Out-Null

    Write-Host ""
    Write-Host "Keep-alive active." -ForegroundColor Green
    Write-Host "  The system and display will not sleep while this window is open."
    Write-Host "  Press Enter to stop."
    Write-Host ""

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    while ($true) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::Enter) { break }
        }

        if ($stopwatch.Elapsed.TotalSeconds -ge $IntervalSeconds) {
            [PowerState]::SetThreadExecutionState($activeFlags) | Out-Null
            $stopwatch.Restart()
        }

        Start-Sleep -Milliseconds 500
    }
}
finally {
    [PowerState]::SetThreadExecutionState($resetFlags) | Out-Null
    Write-Host "Keep-alive stopped. Power settings restored." -ForegroundColor Yellow
}
