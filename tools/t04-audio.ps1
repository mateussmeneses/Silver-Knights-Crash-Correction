# T-04: determine whether each audio path actually produces sound.
#
# Module-load evidence proves a DLL was mapped, NOT that audio was rendered.
# This measures the WASAPI output level of the default render device while the game
# runs, so "silent" and "audible" become measured facts rather than impressions.
#
# Method: launch the game, start a match, then sample the default endpoint's peak
# meter (IAudioMeterInformation) at intervals. A peak > 0 on any sample means the
# game is putting signal on the output device.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox4",
    [string]$OutDir  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t04-audio",
    [int]$SamplesPerPhase = 24,
    [int]$SampleMs   = 400
)
$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# --- WASAPI peak meter over Core Audio (COM interop, no extra modules needed) ---
$cs = @'
using System;
using System.Runtime.InteropServices;

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
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
class MMDeviceEnumerator { }

public class PeakMeter {
    private IMMDeviceEnumerator _enum;
    private IMMDevice _dev;
    private IAudioMeterInformation _meter;

    public PeakMeter() {
        _enum = (IMMDeviceEnumerator)new MMDeviceEnumerator();
        int hr = _enum.GetDefaultAudioEndpoint(0, 0, out _dev); // eRender, eConsole
        if (hr != 0) throw new Exception("GetDefaultAudioEndpoint failed hr=0x" + hr.ToString("x8"));
        Guid IID_IAudioMeterInformation = new Guid("C02216F6-8C67-4B5B-9D00-D008E73E0064");
        object o;
        hr = _dev.Activate(ref IID_IAudioMeterInformation, 23 /*CLSCTX_ALL*/, IntPtr.Zero, out o);
        if (hr != 0) throw new Exception("Activate(IAudioMeterInformation) failed hr=0x" + hr.ToString("x8"));
        _meter = (IAudioMeterInformation)o;
    }
    public float Peak() {
        float p; int hr = _meter.GetPeakValue(out p);
        return hr == 0 ? p : -1f;
    }
}
'@
Add-Type -TypeDefinition $cs -Language CSharp

try {
    $pm = New-Object PeakMeter
    Write-Output ("WASAPI peak meter attached. idle peak = {0:F6}" -f $pm.Peak())
} catch {
    Write-Output ("FATAL: could not attach WASAPI meter: " + $_.Exception.Message)
    exit 1
}

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WA {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool at);
    [DllImport("user32.dll")] public static extern IntPtr SetActiveWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
    [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx,dy; public uint mouseData,dwFlags,time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT { public ushort wVk,wScan; public uint dwFlags,time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] public struct HARDWAREINPUT { public uint uMsg; public ushort wParamL,wParamH; }
    [StructLayout(LayoutKind.Explicit)] public struct U { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; [FieldOffset(0)] public HARDWAREINPUT hi; }
    [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type; public U u; }
    [DllImport("user32.dll", SetLastError=true)] public static extern uint SendInput(uint n, INPUT[] p, int cb);
    public static string T(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string C(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
    public static bool ForceForeground(IntPtr target) {
        uint my=GetCurrentThreadId(); IntPtr fg=GetForegroundWindow();
        uint p; uint ft=GetWindowThreadProcessId(fg,out p);
        keybd_event(0x12,0,0,IntPtr.Zero); keybd_event(0x12,0,2,IntPtr.Zero);
        bool a1=AttachThreadInput(my,ft,true);
        uint tp; uint tt=GetWindowThreadProcessId(target,out tp);
        bool a2=(tt!=ft)&&AttachThreadInput(my,tt,true);
        BringWindowToTop(target); SetActiveWindow(target);
        bool ok=SetForegroundWindow(target); SetFocus(target);
        if(a2) AttachThreadInput(my,tt,false);
        if(a1) AttachThreadInput(my,ft,false);
        return ok; }
    public static void Key(ushort scan, bool ext, int hold) {
        uint f=0x0008; if(ext) f|=0x0001;
        INPUT[] d=new INPUT[1]; d[0].type=1; d[0].u.ki.wScan=scan; d[0].u.ki.dwFlags=f;
        SendInput(1,d,Marshal.SizeOf(typeof(INPUT)));
        System.Threading.Thread.Sleep(hold);
        INPUT[] u=new INPUT[1]; u[0].type=1; u[0].u.ki.wScan=scan; u[0].u.ki.dwFlags=f|0x0002;
        SendInput(1,u,Marshal.SizeOf(typeof(INPUT))); }
}
'@
if(-not ("WA" -as [type])){ Write-Output "FATAL: Add-Type (WA) failed"; exit 1 }

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WA]::EnumWindows({param($h,$z) $o=0;[void][WA]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WA]::C($h);Text=[WA]::T($h);Vis=[WA]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WA]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WA]::C($c);Text=[WA]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

function Sample($label,$n){
    $peakMax = 0.0; $nz = 0
    for($i=0;$i -lt $n;$i++){
        Start-Sleep -Milliseconds $SampleMs
        $v = $pm.Peak()
        if($v -gt $peakMax){ $peakMax = $v }
        if($v -gt 0.0005){ $nz++ }
    }
    Write-Output ("  [{0}] samples={1} nonzero={2} peakMax={3:F5}" -f $label,$n,$nz,$peakMax)
    return [pscustomobject]@{Label=$label;Peak=$peakMax;NonZero=$nz;N=$n}
}

$results = New-Object System.Collections.ArrayList

# phase 0: idle baseline (nothing playing)
Write-Output "PHASE 0: idle baseline (game not running)"
[void]$results.Add((Sample 'idle-baseline' 10))

Write-Output ""
Write-Output "PHASE 1: launch and observe the launcher / intro"
$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date; Write-Output "  T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false
while(((Get-Date)-$t0).TotalSeconds -lt 26){
    Start-Sleep -Milliseconds 350
    foreach($w in (AllWins $sp.Id)){
      if($w.Text -eq 'Error Massage'){
        $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
        if($ok){[void][WA]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
      } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
        $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
        if($b){[void][WA]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true
          Write-Output ("  T+{0:N1} CLICK Window" -f ((Get-Date)-$t0).TotalSeconds); Start-Sleep -Milliseconds 400}
      }
    }
    $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
    if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
      if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 20){ break } }
}
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if(-not $m){ Write-Output "FATAL: SK-Main not running"; exit 1 }
$target = (AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
Write-Output ("  game window hwnd=0x{0:X}" -f $target.H.ToInt64())

# BGM / menu music
Write-Output "PHASE 2: main menu (BGM expected)"
[void]$results.Add((Sample 'menu-bgm' $SamplesPerPhase))

function EnsureFocus { for($i=0;$i -lt 3;$i++){ [void][WA]::ForceForeground($target.H); Start-Sleep -Milliseconds 350
    if([WA]::GetForegroundWindow() -eq $target.H){ return $true } } return $false }
function Press($scan,$ext,$settle){ if(-not (EnsureFocus)){ Write-Output "    !! focus refused" }
  [void][WA]::Key([uint16]$scan,$ext,140); Start-Sleep -Milliseconds $settle }

Press 0x50 $true 2400      # Battle Mode
Press 0x1C $false 2400     # setup
Press 0x3D $false 6000     # F3 start
Press 0x1C $false 4000     # confirm

Write-Output "PHASE 3: in-match (SFX + BGM expected)"
[void]$results.Add((Sample 'match-audio' $SamplesPerPhase))

# fire / move to provoke SFX
Press 0x30 $false 700      # DIK_B = ATTACK1 per SilverKnights.ini
Press 0x30 $false 700
Write-Output "PHASE 4: after attack input (SFX expected)"
[void]$results.Add((Sample 'match-after-attack' 16))

Write-Output ""
Write-Output "=== RESULT ==="
foreach($r in $results){
    $verdict = if($r.NonZero -gt 0){ "SIGNAL PRESENT" } else { "SILENT" }
    Write-Output ("  {0,-22} nonzero={1,3}/{2,3}  peakMax={3:F5}  -> {4}" -f $r.Label,$r.NonZero,$r.N,$r.Peak,$verdict)
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