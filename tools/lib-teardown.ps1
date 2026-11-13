# Shared teardown guard. Dot-source this instead of writing your own kill block.
#
# WHY THIS EXISTS
# Before this file, ~25 harnesses each ended with:
#
#     Get-Process -Name 'SK-Main','SK-Startup' | ForEach-Object { $_.Kill() }
#
# That kills EVERY instance of the game, including one another harness is deliberately
# running. It destroyed a 33-minute soak twice and produced a false "the session cap is
# per-process-age" verdict (run-49) that had to be retracted. Killing by name is the bug.
#
# THE RULE
# A harness may only kill processes it launched. This module records the pids it started and
# kills exactly those, refusing to touch anything else. If a stale instance is in the way, it
# says so and stops rather than silently destroying someone else's experiment.
#
# USAGE
#     . "$PSScriptRoot\lib-teardown.ps1"
#     $launcher = Start-GameLauncher -WorkDir $WorkDir        # returns a Process
#     ... test ...
#     Stop-GameLauncher -Launcher $launcher                   # kills only what we started
#
# Or, if a script launches the game itself, at minimum:
#     Register-OwnedProcess -Process $sp
#     Stop-OwnedProcesses

$script:OwnedProcessIds = @()

function Register-OwnedProcess {
    param([Parameter(Mandatory=$true)]$Process)
    if($Process -and $Process.Id){
        $script:OwnedProcessIds += [int]$Process.Id
        Write-Verbose ("registered owned pid {0}" -f $Process.Id)
    }
}

function Get-RunningGameProcesses {
    # Returns game processes that are NOT ours. Useful to warn before starting a competing one.
    $all = @(Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue)
    return @($all | Where-Object { $script:OwnedProcessIds -notcontains $_.Id })
}

function Assert-NoCompetingGame {
    <#
      Call this BEFORE launching. If another harness already has the game running, a new
      instance would both disturb that run and make this run's measurements ambiguous.
    #>
    param([switch]$Force)
    $others = Get-RunningGameProcesses
    if($others.Count -gt 0){
        $ids = ($others | ForEach-Object { "{0}({1})" -f $_.ProcessName,$_.Id }) -join ', '
        if($Force){
            Write-Warning ("competing game process(es) present, proceeding because -Force: {0}" -f $ids)
        } else {
            throw ("another harness is running the game ({0}). Refusing to start a competing instance. " +
                   "Wait for it to finish, or pass -Force if you accept that both runs become untrustworthy." -f $ids)
        }
    }
}

function Start-GameLauncher {
    param(
        [Parameter(Mandatory=$true)][string]$WorkDir,
        [switch]$Force
    )
    Assert-NoCompetingGame -Force:$Force
    $exe = Join-Path $WorkDir 'SK-Startup.exe'
    if(-not (Test-Path $exe)){ throw "launcher not found: $exe" }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    Register-OwnedProcess -Process $p
    return $p
}

function Stop-OwnedProcesses {
    <#
      Kills only the processes this session registered - never by name. Game children
      (SK-Main) are found as descendants of an owned launcher, not by name alone, so a
      parallel run started by someone else is left alone.
    #>
    param([switch]$Quiet)
    foreach($pid_ in $script:OwnedProcessIds){
        $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
        if($proc){
            if(-not $Quiet){ Write-Output ("killing owned {0} {1}" -f $proc.ProcessName, $proc.Id) }
            try { $proc.Kill() } catch { }
        }
    }
    # SK-Main is a CHILD of the launcher; find only descendants of our owned pids.
    foreach($pid_ in $script:OwnedProcessIds){
        $kids = @(Get-CimInstance Win32_Process -Filter ("ParentProcessId={0}" -f $pid_) -ErrorAction SilentlyContinue)
        foreach($k in $kids){
            if($k.Name -match '^SK-Main\.exe$'){
                $kp = Get-Process -Id $k.ProcessId -ErrorAction SilentlyContinue
                if($kp){
                    if(-not $Quiet){ Write-Output ("killing owned child {0} {1}" -f $kp.ProcessName, $kp.Id) }
                    try { $kp.Kill() } catch { }
                }
            }
        }
    }
    $script:OwnedProcessIds = @()
}
