# T-11: is the 30-minute termination a MATCH time limit or a PROCESS age limit?
#
# run-48 proved the process wrote a clean "End" line at exactly 1800.067 s after "Start"
# while in a live match. Two competing explanations:
#
#   (A) MATCH time limit - the battle has a 30:00 cap and the game ends the session when the
#       match clock reaches it. Then the process would survive if it sat in the MENU for 30
#       minutes instead of a match.
#   (B) PROCESS age limit - the game self-terminates 30 minutes after start regardless of
#       state. Then a 30-minute menu idle would also end it.
#
# This script is the discriminating experiment: sit in the MAIN MENU (no match) for 33
# minutes and watch for the End line. If the process survives past 30:00, (A) holds and the
# limit is a gameplay rule, not a defect. If it ends at 30:00, (B) holds and it is a hard
# session cap affecting every mode.
#
# Cheap: it needs no input once the menu is up, so it cannot be disturbed by focus issues.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox5",
    [int]$Minutes = 33,
    [int]$SampleSec = 60
)
$ErrorActionPreference = 'Continue'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WN {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    public static string T(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string C(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
}
'@
if(-not ("WN" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WN]::EnumWindows({param($h,$z) $o=0;[void][WN]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WN]::C($h);Text=[WN]::T($h);Vis=[WN]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WN]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WN]::C($c);Text=[WN]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

$log = Join-Path $WorkDir 'SilverKnights.log'
$linesBefore = if(Test-Path $log){ (Get-Content $log).Count } else { 0 }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi; [void]$sp.Start()
$t0=Get-Date; Write-Output ("T+0 LAUNCH  (log had {0} lines)" -f $linesBefore)
$myPid = $sp.Id

# get to the main menu, then STOP interacting. No match started: this is the control.
$clicked=$false
$reached=$false
while(((Get-Date)-$t0).TotalSeconds -lt 40){
  Start-Sleep -Milliseconds 400
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WN]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WN]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx){ $reached=$true; if(((Get-Date)-$t0).TotalSeconds -gt 25){ break } } }
}
if(-not $reached){ Write-Output "FATAL: never reached the game window"; exit 1 }
Write-Output "main menu is up - NO match started. Idling from here; no further input."
Write-Output ""

$deadline = (Get-Date).AddMinutes($Minutes)
$ended = $false
while((Get-Date) -lt $deadline){
  Start-Sleep -Seconds $SampleSec
  $el = ((Get-Date)-$t0).TotalSeconds
  $p = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if(-not $p){
    Write-Output ("  T+{0,5:N0}s  PROCESS GONE" -f $el)
    $ended = $true
    break
  }
  Write-Output ("  T+{0,5:N0}s  WS={1,6}MB  thr={2,3}  hnd={3,5}" -f $el,[math]::Round($p.WorkingSet64/1MB,1),$p.Threads.Count,$p.HandleCount)
  if($el -ge 1860){
    Write-Output ("  T+{0:N0}s  SURVIVED past 30:00 - match-limit hypothesis supported" -f $el)
    break
  }
}

Write-Output ""
Write-Output "=== log lines added by this run ==="
if(Test-Path $log){
  $all = Get-Content $log
  $new = $all | Select-Object -Skip $linesBefore
  $new | ForEach-Object { Write-Output ("  {0}" -f $_) }
  $totalSec = ((Get-Date)-$t0).TotalSeconds
  Write-Output ("elapsed this run: {0:N1}s ({1:N2} min)" -f $totalSec,($totalSec/60))
  if($ended){ Write-Output "VERDICT: process did NOT survive menu idle -> PROCESS-AGE cap (hypothesis B)" }
  else { Write-Output "VERDICT: survived 30 min in menu -> MATCH TIME LIMIT (hypothesis A)" }
} else { Write-Output "  (no log file)" }

Write-Output ""
Write-Output "=== teardown ==="
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "killing $($_.ProcessName) $($_.Id)"; try{$_.Kill()}catch{} }
