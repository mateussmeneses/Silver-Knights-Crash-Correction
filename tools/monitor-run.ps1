# Monitor a Silver Knights launch: processes, windows, log transitions, exit codes.
# Read-only observation; the game writes its own log.
param(
    [string]$Exe  = "C:\projetos\Silver-Knights-Crash-Correction\SK-Startup.exe",
    [string]$WorkDir = "C:\projetos\Silver-Knights-Crash-Correction",
    [int]$Seconds = 40,
    [int]$PollMs = 400
)
$ErrorActionPreference = 'SilentlyContinue'
$log = Join-Path $WorkDir 'SilverKnights.log'

function LogSize { if (Test-Path $log) { (Get-Item $log).Length } else { -1 } }

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Exe
$psi.WorkingDirectory = $WorkDir
$psi.UseShellExecute = $false
$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
[void]$proc.Start()

$t0 = Get-Date
$lastSize = LogSize
$seen = @{}
Write-Output "T+0.000 LAUNCH $Exe pid=$($proc.Id)  logsize=$lastSize"

$deadline = $t0.AddSeconds($Seconds)
$exitAt = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds $PollMs
    $el = ((Get-Date) - $t0).TotalSeconds

    $procs = @(Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue)
    foreach ($p in $procs) {
        $key = "$($p.Id)/$($p.ProcessName)"
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $title = ($p.MainWindowTitle -replace "`r?`n",' ')
            Write-Output ("T+{0:N2} SPAWN {1} hwnd={2} title='{3}' threads={4} ws={5}MB" -f $el, $key, $p.MainWindowHandle, $title, $p.Threads.Count, [math]::Round($p.WorkingSet64/1MB,1))
        } else {
            $title = ($p.MainWindowTitle -replace "`r?`n",' ')
            if ($p.MainWindowHandle -ne 0 -and $title -ne '') {
                $tkey = "$key/title:$title"
                if (-not $seen.ContainsKey($tkey)) {
                    $seen[$tkey] = $true
                    Write-Output ("T+{0:N2} WINDOW {1} hwnd={2} title='{3}'" -f $el, $key, $p.MainWindowHandle, $title)
                }
            }
        }
    }

    $sz = LogSize
    if ($sz -ne $lastSize) {
        Write-Output ("T+{0:N2} LOG GREW {1} -> {2}" -f $el, $lastSize, $sz)
        Get-Content $log -Tail 2 | ForEach-Object { Write-Output "        | $_" }
        $lastSize = $sz
    }

    if ($proc.HasExited -and -not $exitAt) {
        $exitAt = $el
        Write-Output ("T+{0:N2} PARENT EXIT code=0x{1:X8} ({1})" -f $el, $proc.ExitCode)
    }
    if ($exitAt -and -not ($procs | Where-Object { $_.ProcessName -eq 'SK-Main' })) {
        Write-Output ("T+{0:N2} ALL GONE" -f $el)
        break
    }
}

Write-Output "--- FINAL ---"
if ($proc.HasExited) { Write-Output ("parent_exit=0x{0:X8} elapsed={1:N2}s" -f $proc.ExitCode, ((Get-Date)-$t0).TotalSeconds) }
else { Write-Output "parent STILL RUNNING -> killing"; try { $proc.Kill() } catch {} }
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Output "leftover pid=$($_.Id) $($_.ProcessName)"; try { $_.Kill() } catch {}
}
Write-Output "--- log tail ---"
if (Test-Path $log) { Get-Content $log -Tail 6 }
