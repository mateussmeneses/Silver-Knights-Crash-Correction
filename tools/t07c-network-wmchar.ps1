# T-07c: Network Mode name entry via WM_CHAR.
#
# run-38 typed with scancode injection: navigation worked (we reached Network Mode) but
# the name field stayed BLANK. A text field consumes characters through the message
# queue (WM_CHAR), and this game imports IMM32, so the field may also go through IME.
# Scancode SendInput produces WM_KEYDOWN but the game may not translate it for the field.
#
# This run posts WM_CHAR directly to the game window, which is exactly what a text
# control expects for character input.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox4",
    [string]$OutDir  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t07c",
    [string]$PlayerName = "TestPilot"
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WK {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool at);
    [DllImport("user32.dll")] public static extern IntPtr SetActiveWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X,Y; }
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
    // WM_CHAR directly: this is what a text field consumes
    public static void Char(IntPtr h, char c) {
        PostMessageW(h, 0x0102, (IntPtr)(int)c, (IntPtr)1);   // WM_CHAR
    }
}
'@
if(-not ("WK" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WK]::EnumWindows({param($h,$z) $o=0;[void][WK]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WK]::C($h);Text=[WK]::T($h);Vis=[WK]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WK]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WK]::C($c);Text=[WK]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Capture($hwnd,$path){
  $rc=New-Object 'WK+RECT'
  if(-not [WK]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WK+POINT'; $pt.X=0; $pt.Y=0
  [void][WK]::ClientToScreen($hwnd,[ref]$pt)
  try { $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X,$pt.Y,0,0,(New-Object System.Drawing.Size $w,$h))
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); return $true
  } catch { return $false } }
function Mods($m){
  $names = @('dpnet','dplayx','dpwsock','dpnaddr','dplaysvr','ws2_32','wsock32','mswsock')
  $hit = $m.Modules | Where-Object { $n=$_.ModuleName.ToLower(); $names | Where-Object { $n -like "*$_*" } } | Sort-Object ModuleName
  if($hit){ $hit | ForEach-Object { Write-Output ("    LOADED {0}" -f $_.ModuleName) } } else { Write-Output "    (none)" } }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi; [void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false
while(((Get-Date)-$t0).TotalSeconds -lt 28){
  Start-Sleep -Milliseconds 350
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WK]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WK]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 22){ break } }
}
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
$target = (AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
if(-not $target){ Write-Output "FATAL: no game window"; exit 1 }

function EnsureFocus { for($i=0;$i -lt 3;$i++){ [void][WK]::ForceForeground($target.H); Start-Sleep -Milliseconds 350
    if([WK]::GetForegroundWindow() -eq $target.H){ return $true } } return $false }
function Press($name,$scan,$ext,$settle){
  if(-not (EnsureFocus)){ Write-Output "  !! focus refused before '$name'" }
  [void][WK]::Key([uint16]$scan,$ext,140); Start-Sleep -Milliseconds $settle }

Press 'DIK_DOWN -> Battle'  0x50 $true 1800
Press 'DIK_DOWN -> Network' 0x50 $true 1800
Press 'ENTER -> name entry' 0x1C $false 4500
Capture $target.H (Join-Path $OutDir '01-before-chars.png') | Out-Null

Write-Output ("posting WM_CHAR for '{0}' to hwnd=0x{1:X}" -f $PlayerName,$target.H.ToInt64())
[void](EnsureFocus)
foreach($ch in $PlayerName.ToCharArray()){
  [WK]::Char($target.H, $ch)
  Start-Sleep -Milliseconds 130
}
Start-Sleep -Milliseconds 900
Capture $target.H (Join-Path $OutDir '02-after-chars.png') | Out-Null

Write-Output "advancing with ENTER"
Press 'ENTER -> continue' 0x1C $false 6000
Capture $target.H (Join-Path $OutDir '03-after-enter.png') | Out-Null

$m2 = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if($m2){
  Write-Output "=== modules ==="; Mods $m2
  foreach($dw in (AllWins $m2.Id)){ if($dw.Text -eq 'Error Massage'){
    $dk=Kids $dw.H; $msg=($dk|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
    Write-Output ("    DIALOG: {0}" -f $msg) }}
  Write-Output ("alive ws={0}MB threads={1}" -f [math]::Round($m2.WorkingSet64/1MB,1),$m2.Threads.Count)
} else { Write-Output "SK-Main EXITED" }

Write-Output ""
Write-Output "=== teardown ==="
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "killing $($_.ProcessName) $($_.Id)"; try{$_.Kill()}catch{} }
