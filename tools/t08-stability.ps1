# T-08: long-run stability and memory growth.
#
# Runs a live match for the requested duration and samples working set, thread count,
# handle count and GDI/USER object counts so a leak shows up as a slope rather than as a
# crash. Also watches for any error dialog or WER event appearing mid-run.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox4",
    [int]$Minutes = 30,
    [int]$SampleSec = 30
)
$ErrorActionPreference = 'Continue'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WL {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
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
if(-not ("WL" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WL]::EnumWindows({param($h,$z) $o=0;[void][WL]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WL]::C($h);Text=[WL]::T($h);Vis=[WL]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WL]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WL]::C($c);Text=[WL]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id) target=${Minutes}min sample=${SampleSec}s"
$clicked=$false
while(((Get-Date)-$t0).TotalSeconds -lt 30){
  Start-Sleep -Milliseconds 350
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WL]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WL]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 22){ break } }
}
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if(-not $m){ Write-Output "FATAL: SK-Main not running"; exit 1 }
$target = (AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1

function EnsureFocus { for($i=0;$i -lt 3;$i++){ [void][WL]::ForceForeground($target.H); Start-Sleep -Milliseconds 350
    if([WL]::GetForegroundWindow() -eq $target.H){ return $true } } return $false }
function Press($scan,$ext,$settle){ if(-not (EnsureFocus)){ Write-Output "  !! focus refused" }
  [void][WL]::Key([uint16]$scan,$ext,140); Start-Sleep -Milliseconds $settle }

# enter a live match
Press 0x50 $true 2400
Press 0x1C $false 2400
Press 0x3D $false 5200
Press 0x1C $false 3500
Write-Output "match started, beginning sampling"

$samples = New-Object System.Collections.ArrayList
$deadline = (Get-Date).AddMinutes($Minutes)
$dialogSeen = 0
while((Get-Date) -lt $deadline){
  Start-Sleep -Seconds $SampleSec
  $p = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if(-not $p){
    Write-Output ("STOP: SK-Main EXITED at T+{0:N0}s" -f ((Get-Date)-$t0).TotalSeconds)
    break
  }
  $el = ((Get-Date)-$t0).TotalSeconds
  $samples.Add([pscustomobject]@{
    T=[math]::Round($el,0)
    WS_MB=[math]::Round($p.WorkingSet64/1MB,1)
    Priv_MB=[math]::Round($p.PrivateMemorySize64/1MB,1)
    Threads=$p.Threads.Count
    Handles=$p.HandleCount
  })
  # watch for dialogs
  foreach($dw in (AllWins $p.Id)){ if($dw.Text -eq 'Error Massage'){
    $dialogSeen++
    $dk=Kids $dw.H; $msg=($dk|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
    Write-Output ("  T+{0:N0}s DIALOG: {1}" -f $el,$msg)
    $ok=$dk|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
    if($ok){[void][WL]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 400}
  }}
  $last = $samples[$samples.Count-1]
  Write-Output ("  T+{0,5}s  WS={1,7}MB  priv={2,7}MB  thr={3,3}  hnd={4,5}" -f $last.T,$last.WS_MB,$last.Priv_MB,$last.Threads,$last.Handles)
}

Write-Output ""
Write-Output "=== SUMMARY ==="
if($samples.Count -ge 2){
  $first=$samples[0]; $last=$samples[$samples.Count-1]
  $mins = [math]::Max(1,($last.T-$first.T)/60.0)
  Write-Output ("samples          : {0} over {1:N0}s" -f $samples.Count,$last.T)
  Write-Output ("working set      : {0}MB -> {1}MB   ({2:+0.0;-0.0;0}MB, {3:+0.00;-0.00;0} MB/min)" -f $first.WS_MB,$last.WS_MB,($last.WS_MB-$first.WS_MB),(($last.WS_MB-$first.WS_MB)/$mins))
  Write-Output ("private bytes    : {0}MB -> {1}MB   ({2:+0.0;-0.0;0}MB)" -f $first.Priv_MB,$last.Priv_MB,($last.Priv_MB-$first.Priv_MB))
  Write-Output ("threads          : {0} -> {1}" -f $first.Threads,$last.Threads)
  Write-Output ("handles          : {0} -> {1}   ({2:+0;-0;0})" -f $first.Handles,$last.Handles,($last.Handles-$first.Handles))
  Write-Output ("dialogs observed : {0}" -f $dialogSeen)
  $growth = $last.WS_MB - $first.WS_MB
  if($growth -gt 150){ Write-Output "VERDICT: SIGNIFICANT GROWTH - likely leak, investigate" }
  elseif($growth -gt 50){ Write-Output "VERDICT: MODERATE GROWTH - monitor" }
  else { Write-Output "VERDICT: STABLE - no meaningful memory growth" }
} else { Write-Output "insufficient samples" }

Write-Output ""
Write-Output "=== WER events in the last $($Minutes+2) min ==="
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=@(1000,1001,1002); StartTime=(Get-Date).AddMinutes(-($Minutes+2))} -MaxEvents 20 -ErrorAction SilentlyContinue |
  ForEach-Object { Write-Output ("[{0}] id={1} {2}" -f $_.TimeCreated.ToString('HH:mm:ss'),$_.Id,$_.ProviderName) }

Write-Output ""
Write-Output "=== clean shutdown test ==="
$m2 = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if($m2 -and $target){
  [void][WL]::ForceForeground($target.H)
  [void][WL]::Key([uint16]0x01,$false,120)  # ESC
  Start-Sleep -Seconds 2
}
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