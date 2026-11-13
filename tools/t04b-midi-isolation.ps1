# T-04b: isolate the MIDI path.
#
# Why: T-04 measured audio reaching the output device via WASAPI, but the music that was
# playing could only have been the MP3/DirectShow path. `dmusic.dll` and `midimap.dll` load,
# yet no MIDI track was ever isolated. The open question is simply: does the DirectMusic/MIDI
# path produce audible output at all?
#
# Method - make MP3 impossible, so any signal must be MIDI:
#   1. Copy the game to its own sandbox.
#   2. REMOVE the mp3/ files from that sandbox only. If the game falls back to MP3 regardless
#      of the MIDI flag, it will now have nothing to play through DirectShow.
#   3. Set MIDI=1 and WAVE=0 in silverknights.ini so the engine is told to use MIDI.
#   4. Sample the WASAPI endpoint peak meter on the title screen and main menu.
#        signal present  -> DirectMusic/MIDI works  (T-04b PASS)
#        silence         -> MIDI path is dead or unused (T-04b FAIL, documented)
#
# The repo tree is never modified. The sandbox is disposable.
param(
    [string]$SrcDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox5",
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-midi",
    [string]$OutDir = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t04b"
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WM {
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
if(-not ("WM" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }

# WASAPI peak meter on the default render endpoint
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
[ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
    int NotImpl1();
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppDevice);
}
[ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
    int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
}
[ComImport, Guid("C02216F6-8C67-4B5B-9D00-D008E73E0064"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioMeterInformation {
    int GetPeakValue(out float pfPeak);
}
public class Peak {
    static IAudioMeterInformation meter = null;
    static void Init() {
        if (meter != null) return;
        IMMDeviceEnumerator en = (IMMDeviceEnumerator)(new MMDeviceEnumeratorComObject());
        IMMDevice dev = null;
        en.GetDefaultAudioEndpoint(0, 1, out dev);
        Guid iid = typeof(IAudioMeterInformation).GUID;
        object o = null;
        dev.Activate(ref iid, 1, IntPtr.Zero, out o);
        meter = (IAudioMeterInformation)o;
    }
    public static float Read() {
        Init();
        float p = 0f;
        meter.GetPeakValue(out p);
        return p;
    }
}
'@
if(-not ("Peak" -as [type])){ Write-Output "FATAL: WASAPI helper failed to compile"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WM]::EnumWindows({param($h,$z) $o=0;[void][WM]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WM]::C($h);Text=[WM]::T($h);Vis=[WM]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WM]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WM]::C($c);Text=[WM]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

# --- prepare the sandbox ---------------------------------------------------
if(Test-Path $WorkDir){ Remove-Item -Recurse -Force $WorkDir }
Copy-Item -Recurse -Force $SrcDir $WorkDir

$mp3 = Join-Path $WorkDir 'mp3'
$midi = Join-Path $WorkDir 'midi'
$mp3Count = 0
if(Test-Path $mp3){
    $mp3Count = (Get-ChildItem -Path $mp3 -File -Recurse).Count
    Get-ChildItem -Path $mp3 -File -Recurse | Remove-Item -Force
    Write-Output ("MP3 DISABLED: deleted {0} file(s) from the sandbox's mp3\\" -f $mp3Count)
} else { Write-Output "note: no mp3 dir in sandbox" }
$midiCount = if(Test-Path $midi){ (Get-ChildItem -Path $midi -File -Recurse).Count } else { 0 }
Write-Output ("MIDI assets present: {0} file(s) in midi\\" -f $midiCount)

$ini = Join-Path $WorkDir 'SilverKnights.ini'
if(Test-Path $ini){
    $txt = Get-Content -Raw $ini
    $txt2 = $txt -replace '(?m)^\s*MIDI\s*=.*$','MIDI= 1'
    $txt2 = $txt2 -replace '(?m)^\s*WAVE\s*=.*$','WAVE= 0'
    if($txt2 -notmatch '(?m)^\s*WAVE\s*='){ $txt2 = $txt2 -replace '(?m)^(\[ENVIRONMENT\])',"`$1`r`nWAVE= 0" }
    [System.IO.File]::WriteAllText($ini, $txt2)
    Write-Output "INI set: MIDI=1, WAVE=0"
    Get-Content $ini | Select-Object -First 6 | ForEach-Object { Write-Output ("    " + $_) }
} else { Write-Output "FATAL: no SilverKnights.ini in sandbox"; exit 1 }

# --- run -------------------------------------------------------------------
$base = [Peak]::Read()
Write-Output ""
Write-Output ("baseline peak (before launch): {0:F5}" -f $base)

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date; Write-Output ("T+0 LAUNCH pid={0}" -f $sp.Id)

$clicked=$false
$reached=$false
while(((Get-Date)-$t0).TotalSeconds -lt 45){
  Start-Sleep -Milliseconds 400
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WM]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WM]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx){ $reached=$true; if(((Get-Date)-$t0).TotalSeconds -gt 30){ break } } }
}
if(-not $reached){ Write-Output "FATAL: never reached the game window"; exit 1 }
Write-Output "game window up"

# Which modules loaded? This is direct evidence about the audio path.
Start-Sleep -Seconds 4
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if($m){
    Write-Output ""
    Write-Output "=== audio-related modules ==="
    $m.Modules | Where-Object { $_.ModuleName -match 'dmusic|dmloader|dmsynth|midimap|quartz|dsound|winmm|l3codeca|msmpeg2|wdmaud|msacm' } |
        Sort-Object ModuleName | ForEach-Object { Write-Output ("    " + $_.ModuleName) }
}

# Sample the meter in 3 windows: title, menu, and after a few seconds
Write-Output ""
Write-Output "=== peak meter sampling (30 x 300 ms) ==="
$vals = New-Object System.Collections.ArrayList
for($i=0; $i -lt 30; $i++){
    Start-Sleep -Milliseconds 300
    $p = [Peak]::Read()
    [void]$vals.Add($p)
}
$nz = ($vals | Where-Object { $_ -gt 0.0001 }).Count
$max = ($vals | Measure-Object -Maximum).Maximum
$avg = ($vals | Measure-Object -Average).Average
Write-Output ("samples      : {0}" -f $vals.Count)
Write-Output ("non-zero     : {0} / {1}" -f $nz,$vals.Count)
Write-Output ("max peak     : {0:F5}" -f $max)
Write-Output ("average peak : {0:F5}" -f $avg)
Write-Output ("raw          : {0}" -f (($vals | ForEach-Object { "{0:F4}" -f $_ }) -join ", "))

Write-Output ""
if($max -gt 0.0005){
    Write-Output "VERDICT: SIGNAL PRESENT with mp3\\ emptied and MIDI=1."
    Write-Output "         The DirectMusic/MIDI path DOES produce audible output. T-04b PASS."
} else {
    Write-Output "VERDICT: SILENCE with mp3\\ emptied and MIDI=1."
    Write-Output "         Either the MIDI path is not used for music, or it fails silently."
    Write-Output "         T-04b: the MIDI path does NOT produce audible output in this build."
}

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
Write-Output ("note: sandbox mp3\\ had {0} file(s) removed; the repository tree was not touched" -f $mp3Count)
