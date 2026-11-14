$ErrorActionPreference = 'SilentlyContinue'
$OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::UTF8

function Show-Events($ids, $days, $label) {
    Write-Output "===== $label ====="
    Get-WinEvent -FilterHashtable @{LogName='Application'; Id=$ids; StartTime=(Get-Date).AddDays(-$days)} -MaxEvents 300 -ErrorAction SilentlyContinue |
        ForEach-Object {
            $m = $_.Message -replace "`r?`n", ' ; '
            if ($m.Length -gt 400) { $m = $m.Substring(0,400) }
            Write-Output ("[{0}] id={1} src={2}`n    {3}" -f $_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'), $_.Id, $_.ProviderName, $m)
        }
}

Show-Events @(1000) 120 'Application Error 1000'
Show-Events @(1001) 120 'WER 1001'
Show-Events @(1002) 120 'Application Hang 1002'

Write-Output "===== Events around 2026-11-13 10:19-10:22 (all logs, System+Application) ====="
$start = Get-Date '2026-11-13 10:15:00'
$end   = Get-Date '2026-11-13 10:25:00'
foreach ($log in @('Application','System')) {
    Get-WinEvent -FilterHashtable @{LogName=$log; StartTime=$start; EndTime=$end} -MaxEvents 200 -ErrorAction SilentlyContinue |
        ForEach-Object {
            $m = $_.Message -replace "`r?`n", ' ; '
            if ($m.Length -gt 250) { $m = $m.Substring(0,250) }
            Write-Output ("{0} [{1}] id={2} lvl={3} src={4} :: {5}" -f $log, $_.TimeCreated.ToString('HH:mm:ss'), $_.Id, $_.LevelDisplayName, $_.ProviderName, $m)
        }
}

Write-Output "===== AppCompat / Application-Experience ====="
Get-WinEvent -LogName 'Microsoft-Windows-Application-Experience/Program-Telemetry' -MaxEvents 40 -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Output ("[{0}] id={1} {2}" -f $_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'), $_.Id, (($_.Message -replace "`r?`n",' ; '))) }

Write-Output "===== SM faults (bugcheck / LiveKernelEvent) last 90d ====="
Get-WinEvent -FilterHashtable @{LogName='System'; Id=@(1001,1018,41,6008,4101); StartTime=(Get-Date).AddDays(-90)} -MaxEvents 60 -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Output ("[{0}] id={1} {2} :: {3}" -f $_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'), $_.Id, $_.ProviderName, (($_.Message -replace "`r?`n",' ; ').Substring(0,[Math]::Min(250,($_.Message -replace "`r?`n",' ; ').Length)))) }

Write-Output "===== LocalDumps registry ====="
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps' -ErrorAction SilentlyContinue | Format-List
foreach ($k in (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps' -ErrorAction SilentlyContinue)) {
    Write-Output "--- $($k.PSChildName) ---"
    Get-ItemProperty $k.PSPath | Select-Object * -Exclude PS* | Format-List
}
