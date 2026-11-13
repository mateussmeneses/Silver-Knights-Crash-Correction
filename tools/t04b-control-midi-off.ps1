# T-04b CONTROL: prove the signal in run-52 actually came from MIDI.
#
# run-52 showed signal with mp3\ emptied and MIDI=1. That is suggestive but NOT conclusive,
# for two reasons:
#
#   1. The pre-launch baseline was 0.00342, not zero - something else on the machine was
#      already making sound, so "non-zero peak" does not prove the GAME made it.
#   2. The module list came back empty, because this 64-bit PowerShell cannot enumerate a
#      WOW64 process's modules (a documented pitfall). So there is no direct evidence from
#      run-52 that dmusic.dll was even loaded.
#
# The control that settles it: identical sandbox, mp3\ emptied, but MIDI=0. If that is SILENT
# while run-52 was not, the signal is attributable to MIDI. If both are equally loud, the
# "signal" was ambient and run-52 proved nothing.
#
# Also fixes reason 2 by enumerating modules from a 32-bit PowerShell, which can see the
# WOW64 process's real module list.
param(
    [string]$SrcDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox5",
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-midi-control",
    [string]$OutDir = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t04b-control",
    [int]$MidiFlag = 0
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WQ {
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
if(-not ("WQ" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObjectC { }
[ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumeratorC { int NotImpl1(); int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDeviceC ppDevice); }
[ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceC { int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface); }
[ComImport, Guid("C02216F6-8C67-4B5B-9D00-D008E73E0064"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioMeterInformationC { int GetPeakValue(out float pfPeak); }
public class PeakC {
    static IAudioMeterInformationC meter = null;
    static void Init() {
        if (meter != null) return;
        IMMDeviceEnumeratorC en = (IMMDeviceEnumeratorC)(new MMDeviceEnumeratorComObjectC());
        IMMDeviceC dev = null;
        en.GetDefaultAudioEndpoint(0, 1, out dev);
        Guid iid = typeof(IAudioMeterInformationC).GUID;
        object o = null;
        dev.Activate(ref iid, 1, IntPtr.Zero, out o);
        meter = (IAudioMeterInformationC)o;
    }
    public static float Read() { Init(); float p = 0f; meter.GetPeakValue(out p); return p; }
}
'@
if(-not ("PeakC" -as [type])){ Write-Output "FATAL: WASAPI helper failed"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WQ]::EnumWindows({param($h,$z) $o=0;[void][WQ]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WQ]::C($h);Text=[WQ]::T($h);Vis=[WQ]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WQ]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WQ]::C($c);Text=[WQ]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

if(Test-Path $WorkDir){ Remove-Item -Recurse -Force $WorkDir }
Copy-Item -Recurse -Force $SrcDir $WorkDir
$mp3 = Join-Path $WorkDir 'mp3'
if(Test-Path $mp3){
    $c = (Get-ChildItem -Path $mp3 -File -Recurse).Count
    Get-ChildItem -Path $mp3 -File -Recurse | Remove-Item -Force
    Write-Output ("mp3 disabled: removed {0} file(s)" -f $c)
}
$ini = Join-Path $WorkDir 'SilverKnights.ini'
$txt = Get-Content -Raw $ini
$txt = $txt -replace '(?m)^\s*MIDI\s*=.*$',("MIDI= {0}" -f $MidiFlag)
$txt = $txt -replace '(?m)^\s*WAVE\s*=.*$','WAVE= 0'
[System.IO.File]::WriteAllText($ini, $txt)
Write-Output ("CONFIG: MIDI={0}  WAVE=0  mp3=EMPTY" -f $MidiFlag)

# Ten seconds of quiet baseline before launching anything.
Write-Output ""
Write-Output "=== quiet baseline (10 samples over 5 s, nothing launched yet) ==="
$pre = New-Object System.Collections.ArrayList
for($i=0;$i -lt 10;$i++){ Start-Sleep -Milliseconds 500; [void]$pre.Add([PeakC]::Read()) }
$preMax = ($pre | Measure-Object -Maximum).Maximum
$preAvg = ($pre | Measure-Object -Average).Average
Write-Output ("pre-launch max={0:F5} avg={1:F5}  raw: {2}" -f $preMax,$preAvg,(($pre|ForEach-Object{"{0:F4}" -f $_}) -join ", "))

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date
$clicked=$false; $reached=$false
while(((Get-Date)-$t0).TotalSeconds -lt 45){
  Start-Sleep -Milliseconds 400
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WQ]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WQ]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx){ $reached=$true; if(((Get-Date)-$t0).TotalSeconds -gt 30){ break } } }
}
if(-not $reached){ Write-Output "FATAL: never reached the game window"; exit 1 }
Write-Output "game window up"

# 32-bit module enumeration, so WOW64 modules are actually visible.
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue | Select-Object -First 1
if($m){
    $mods = & "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "(Get-Process -Id $($m.Id)).Modules | ForEach-Object { \$_.ModuleName }" 2>$null
    if(-not $mods){
        # fall back: the 64-bit view at least proves the process exists
        $mods = $m.Modules | ForEach-Object { $_.ModuleName }
    }
    Write-Output ""
    Write-Output "=== audio-related modules (via 32-bit view where available) ==="
    $mods | Where-Object { $_ -match 'dmusic|dmloader|dmsynth|midimap|quartz|dsound|winmm|l3codeca|msmpeg2|wdmaud|msacm|wow64' } |
        Sort-Object | ForEach-Object { Write-Output ("    " + $_) }
    Write-Output ("    (total modules seen: {0})" -f ($mods | Measure-Object).Count)
}

Write-Output ""
Write-Output "=== peak meter while the game is up (30 x 300 ms) ==="
$vals = New-Object System.Collections.ArrayList
for($i=0; $i -lt 30; $i++){ Start-Sleep -Milliseconds 300; [void]$vals.Add([PeakC]::Read()) }
$nz = ($vals | Where-Object { $_ -gt 0.0005 }).Count
$max = ($vals | Measure-Object -Maximum).Maximum
$avg = ($vals | Measure-Object -Average).Average
Write-Output ("non-zero : {0} / {1}" -f $nz,$vals.Count)
Write-Output ("max      : {0:F5}" -f $max)
Write-Output ("average  : {0:F5}" -f $avg)
Write-Output ("raw      : {0}" -f (($vals | ForEach-Object { "{0:F4}" -f $_ }) -join ", "))

Write-Output ""
Write-Output "=== teardown ==="
# Teardown: SAFE BY DEFAULT. Kills nothing unless $script:SKStartedAt was set when this
# script launched the game. Never kill by process name alone - that destroys other
# harnesses' runs (see tools/lib-teardown.ps1 for the incident that motivated this).
$__skOwned = @()
if($script:SKStartedAt){
  $__skOwned = @(Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue |
                 Where-Object { $_.StartTime -ge $script:SKStartedAt })
}
if($__skOwned.Count -gt 0){
  $__skOwned | ForEach-Object { Write-Output ("killing owned {0} {1}" -f $_.ProcessName,$_.Id); try{$_.Kill()}catch{} }
} else {
  Write-Output "teardown: nothing owned to kill (other instances, if any, left untouched)"
}