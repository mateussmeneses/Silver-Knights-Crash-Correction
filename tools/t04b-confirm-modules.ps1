# T-04b confirmation: with MIDI=1 and mp3\ empty, does DirectMusic actually load?
#
# run-52 showed signal (30/30, max 0.111) under MIDI=1 with mp3\ removed.
# run-54 was the control: identical setup, MIDI=0 -> 0/30 non-zero, max 0.00000, on a
# verifiably silent pre-launch baseline (0.0000 x10).
#
# That A/B is strong, but it infers the mechanism from the flag. This run closes the loop by
# reading the ACTUAL 32-bit module list of the WOW64 process, which the earlier attempt failed
# to do because it ran the enumerator inline and got only the wow64 stubs.
#
# Method: launch with MIDI=1, mp3\ empty; then invoke the proven 32-bit enumerator
# (tools/probe-32bit-modules.ps1 pattern) against the live pid and look for dmusic.dll,
# dmloader.dll, dmsynth.dll, midimap.dll.
param(
    [string]$SrcDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox5",
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-midi-mods",
    [string]$OutDir = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t04b-mods"
)
$ErrorActionPreference = 'Continue'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WR {
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
if(-not ("WR" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WR]::EnumWindows({param($h,$z) $o=0;[void][WR]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WR]::C($h);Text=[WR]::T($h);Vis=[WR]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WR]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WR]::C($c);Text=[WR]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

if(Test-Path $WorkDir){ Remove-Item -Recurse -Force $WorkDir }
Copy-Item -Recurse -Force $SrcDir $WorkDir
$mp3=Join-Path $WorkDir 'mp3'
if(Test-Path $mp3){ Get-ChildItem -Path $mp3 -File -Recurse | Remove-Item -Force; Write-Output "mp3 emptied" }
$ini=Join-Path $WorkDir 'SilverKnights.ini'
$txt=Get-Content -Raw $ini
$txt=$txt -replace '(?m)^\s*MIDI\s*=.*$','MIDI= 1'
$txt=$txt -replace '(?m)^\s*WAVE\s*=.*$','WAVE= 0'
[System.IO.File]::WriteAllText($ini,$txt)
Write-Output "CONFIG: MIDI=1  WAVE=0  mp3=EMPTY"

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt=(Get-Date).AddSeconds(-5)
[void]$sp.Start()
$t0=Get-Date
$clicked=$false; $reached=$false
while(((Get-Date)-$t0).TotalSeconds -lt 45){
  Start-Sleep -Milliseconds 400
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WR]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WR]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx){ $reached=$true; if(((Get-Date)-$t0).TotalSeconds -gt 30){ break } } }
}
if(-not $reached){ Write-Output "FATAL: never reached the game window"; exit 1 }
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue | Select-Object -First 1
Write-Output ("game up, pid={0}" -f $m.Id)
Start-Sleep -Seconds 5

# 32-bit enumerator: a 64-bit .Modules walk only sees the wow64 stubs.
$syswow = "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
$modsFile = Join-Path $OutDir 'modules32.txt'
Write-Output ""
Write-Output "=== 32-bit module list (SysWOW64 powershell) ==="
if(Test-Path $syswow){
    # Use a script FILE, not an inline -Command: inline escaping of $_ inside a
    # double-quoted string failed previously and produced 776 CategoryInfo errors.
    $enumerator = Join-Path $PSScriptRoot 'dump-modules32.ps1'
    & $syswow -NoProfile -ExecutionPolicy Bypass -File $enumerator -TargetPid $m.Id 2>&1 |
        Set-Content -Path $modsFile -Encoding UTF8
    $mods = @(Get-Content $modsFile | Where-Object { $_ -match '\S' -and $_ -notmatch 'CategoryInfo|FullyQualifiedErrorId|CommandNotFoundException' })
    Write-Output ("module count: {0}" -f $mods.Count)
    Write-Output ""
    Write-Output "--- DirectMusic / audio specifically ---"
    foreach($t in 'dmusic.dll','dmloader.dll','dmsynth.dll','midimap.dll','quartz.dll','dsound.dll','winmm.dll','l3codeca.acm','msmpeg2adec.dll','wdmaud.drv','msacm32.drv'){
        $hit = $mods | Where-Object { $_ -ieq $t } | Select-Object -First 1
        Write-Output ("    {0,-20} {1}" -f $t, $(if($hit){"LOADED"}else{"absent"}))
    }
    Write-Output ""
    Write-Output "--- all modules matching audio/stream patterns ---"
    $audio = $mods | Where-Object { $_ -match 'music|dmloader|dmsynth|midimap|quartz|dsound|winmm|codec|mpeg|wma|acm|drv$|sound|audio' } | Sort-Object -Unique
    if($audio){ $audio | ForEach-Object { Write-Output ("    " + $_) } } else { Write-Output "    (none)" }
    Write-Output ""
    Write-Output ("--- full module list ({0}) ---" -f $mods.Count)
    $mods | ForEach-Object { Write-Output ("    " + $_) }
} else { Write-Output "FATAL: 32-bit powershell not found"; }

Write-Output ""
Write-Output "=== teardown ==="
$__skOwned = @()
if($script:SKStartedAt){
  $__skOwned = @(Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue |
                 Where-Object { $_.StartTime -ge $script:SKStartedAt })
}
if($__skOwned.Count -gt 0){
  $__skOwned | ForEach-Object { Write-Output ("killing owned {0} {1}" -f $_.ProcessName,$_.Id); try{$_.Kill()}catch{} }
} else { Write-Output "teardown: nothing owned to kill" }
