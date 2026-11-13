# T-01h: start an actual match.
#
# KEY FINDING that unblocks this: the start control is F3, not Enter.
# Evidence from the shipped language file (1041.ini [FUNCTION]):
#   F3_START  =F3 Start
#   F3_COMPLET=F3 Complete
#   F3_CANCEL =F3 Cancel
#   F3_SAVE   =F3 Save
# and [BATTLE_RESULT] carries READY_AND_WAIT= <Ready>. So the Battle setup screen
# advances with F3, while Enter only manipulates the currently focused slot.
#
# Scancodes (Set 1, plain / non-extended): F1=0x3B F2=0x3C F3=0x3D F4=0x3E F6=0x40
#                                          ESC=0x01 ENTER=0x1C SPACE=0x39
# Arrows are E0-extended: DOWN=0x50 UP=0x48 LEFT=0x4B RIGHT=0x4D
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox2",
    [string]$OutDir  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t01h",
    [int]$SettleMs   = 2400
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WF {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool at);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SetActiveWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);

    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X,Y; }
    [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx,dy; public uint mouseData,dwFlags,time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT { public ushort wVk,wScan; public uint dwFlags,time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] public struct HARDWAREINPUT { public uint uMsg; public ushort wParamL,wParamH; }
    [StructLayout(LayoutKind.Explicit)] public struct U {
        [FieldOffset(0)] public MOUSEINPUT mi;
        [FieldOffset(0)] public KEYBDINPUT ki;
        [FieldOffset(0)] public HARDWAREINPUT hi; }
    [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type; public U u; }
    [DllImport("user32.dll", SetLastError=true)] public static extern uint SendInput(uint n, INPUT[] p, int cb);

    public static string T(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string C(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }

    public static bool ForceForeground(IntPtr target)
    {
        uint myTid = GetCurrentThreadId();
        IntPtr fg = GetForegroundWindow();
        uint p; uint fgTid = GetWindowThreadProcessId(fg, out p);
        keybd_event(0x12, 0, 0, IntPtr.Zero);
        keybd_event(0x12, 0, 2, IntPtr.Zero);
        bool a1 = AttachThreadInput(myTid, fgTid, true);
        uint tp; uint tTid = GetWindowThreadProcessId(target, out tp);
        bool a2 = (tTid != fgTid) && AttachThreadInput(myTid, tTid, true);
        BringWindowToTop(target); SetActiveWindow(target);
        bool ok = SetForegroundWindow(target); SetFocus(target);
        if (a2) AttachThreadInput(myTid, tTid, false);
        if (a1) AttachThreadInput(myTid, fgTid, false);
        return ok;
    }

    public static uint Key(ushort scan, bool ext, int holdMs)
    {
        uint f = 0x0008; if (ext) f |= 0x0001;
        INPUT[] d = new INPUT[1];
        d[0].type = 1; d[0].u.ki.wVk = 0; d[0].u.ki.wScan = scan; d[0].u.ki.dwFlags = f;
        uint r = SendInput(1, d, Marshal.SizeOf(typeof(INPUT)));
        System.Threading.Thread.Sleep(holdMs);
        INPUT[] u = new INPUT[1];
        u[0].type = 1; u[0].u.ki.wVk = 0; u[0].u.ki.wScan = scan; u[0].u.ki.dwFlags = f | 0x0002;
        SendInput(1, u, Marshal.SizeOf(typeof(INPUT)));
        return r;
    }
}
'@
if(-not ("WF" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi; [void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WF]::EnumWindows({param($h,$z) $o=0;[void][WF]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WF]::C($h);Text=[WF]::T($h);Vis=[WF]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WF]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WF]::C($c);Text=[WF]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Capture($hwnd,$path){
  $rc=New-Object 'WF+RECT'
  if(-not [WF]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WF+POINT'; $pt.X=0; $pt.Y=0
  [void][WF]::ClientToScreen($hwnd,[ref]$pt)
  try { $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X,$pt.Y,0,0,(New-Object System.Drawing.Size $w,$h))
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); return $true
  } catch { return $false } }

while(((Get-Date)-$t0).TotalSeconds -lt 30){
  Start-Sleep -Milliseconds 350
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WF]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WF]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true
        Write-Output ("T+{0:N1} CLICK Window" -f ((Get-Date)-$t0).TotalSeconds); Start-Sleep -Milliseconds 400}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 22){ break } }
}
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
$target = (AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
if(-not $target){ Write-Output "FATAL: no UDX_CLASS window"; exit 1 }
Write-Output ("T+{0:N1} game window hwnd=0x{1:X}" -f ((Get-Date)-$t0).TotalSeconds,$target.H.ToInt64())

function EnsureFocus {
  for($i=0;$i -lt 3;$i++){
    [void][WF]::ForceForeground($target.H); Start-Sleep -Milliseconds 350
    if([WF]::GetForegroundWindow() -eq $target.H){ return $true } }
  return $false }
function Snap($label){
  $p=Join-Path $OutDir ("{0}.png" -f $label)
  if(Capture $target.H $p){ Write-Output ("  SNAP {0,-28} {1} bytes" -f $label,(Get-Item $p).Length) }
  else { Write-Output ("  SNAP {0} FAILED" -f $label) } }
function Press($name,$scan,$ext,$settle){
  if(-not (EnsureFocus)){ Write-Output "  !! focus refused before '$name'" }
  Write-Output ("  >> {0}" -f $name)
  [void][WF]::Key([uint16]$scan,$ext,140)
  Start-Sleep -Milliseconds $settle }

Snap '01-main-menu'
Press 'DIK_DOWN -> Battle Mode'            0x50 $true  $SettleMs
Snap '02-battle-selected'
Press 'ENTER -> open Battle setup'         0x1C $false $SettleMs
Snap '03-battle-setup'
Press 'F3 -> START match'                  0x3D $false 4000
Snap '04-after-F3'
Press 'F3 -> again (may need Ready)'       0x3D $false 5000
Snap '05-after-F3b'
Press 'ENTER -> confirm any prompt'        0x1C $false 5000
Snap '06-after-enter'

Write-Output ""
Write-Output ("ELAPSED {0:N1}s" -f ((Get-Date)-$t0).TotalSeconds)
$mp = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if($mp){ Write-Output ("SK-Main alive ws={0}MB threads={1}" -f [math]::Round($mp.WorkingSet64/1MB,1),$mp.Threads.Count) }
else { Write-Output "SK-Main EXITED" }
Write-Output "=== teardown ==="
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "killing $($_.ProcessName) $($_.Id)"; try{$_.Kill()}catch{} }
