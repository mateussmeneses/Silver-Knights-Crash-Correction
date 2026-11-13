# Launch a Silver Knights binary in a controlled way and capture process evidence.
# Does NOT modify the binary. Writes a JSON-ish report to stdout.
param(
    [string]$Exe = "C:\projetos\Silver-Knights-Crash-Correction\SK-Startup.exe",
    [int]$TimeoutSec = 30,
    [string]$WorkDir = "C:\projetos\Silver-Knights-Crash-Correction"
)
$ErrorActionPreference = 'Stop'

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Exe
$psi.WorkingDirectory = $WorkDir
$psi.UseShellExecute = $false

$start = Get-Date
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi
[void]$p.Start()
$pid_ = $p.Id
Write-Output "STARTED pid=$pid_ exe=$Exe at=$($start.ToString('yyyy-MM-dd HH:mm:ss.fff'))"

$exited = $p.WaitForExit($TimeoutSec * 1000)
$end = Get-Date

if (-not $exited) {
    Write-Output "RESULT=STILL_RUNNING after ${TimeoutSec}s (killing)"
    try { $p.Kill() } catch {}
    try { [void]$p.WaitForExit(5000) } catch {}
    Write-Output "EXITCODE=KILLED"
} else {
    Write-Output "RESULT=EXITED"
    Write-Output ("EXITCODE=0x{0:X8} ({1})" -f $p.ExitCode, $p.ExitCode)
}
Write-Output "ELAPSED_SEC=$([math]::Round(($end-$start).TotalSeconds,2))"

# Any child processes still alive (SK-Main is spawned by SK-Startup)
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Output "STILL_ALIVE pid=$($_.Id) name=$($_.ProcessName) threads=$($_.Threads.Count) ws=$([math]::Round($_.WorkingSet64/1MB,1))MB" }

# Recent Application Error / WER for our binaries
Write-Output "--- new WER/AppError events (last 10 min) ---"
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=@(1000,1001,1002); StartTime=(Get-Date).AddMinutes(-10)} -MaxEvents 30 -ErrorAction SilentlyContinue |
    ForEach-Object {
        $m = $_.Message -replace "`r?`n", ' ; '
        if ($m.Length -gt 500) { $m = $m.Substring(0,500) }
        Write-Output ("[{0}] id={1} {2} :: {3}" -f $_.TimeCreated.ToString('HH:mm:ss'), $_.Id, $_.ProviderName, $m)
    }
