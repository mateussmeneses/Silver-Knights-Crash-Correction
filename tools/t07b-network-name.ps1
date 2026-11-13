# T-07b: Network Mode, stage 2. Stage 1 (run-37) reached the player-name entry screen
# but DirectPlay was never loaded because a name must be entered first.
#
# This run types a name via scancode injection, advances, and observes whether
# dpnet.dll / dplayx.dll load and whether a lobby/host screen appears or errors.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox4",
    [string]$OutDir  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t07b",
    [string]$PlayerName = "TestPilot"
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WE {
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
}
'@
if(-not ("WE" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Set-1 scancodes for A-Z (letters are NOT extended)
$scanMap = @{
 'A'=0x1E;'B'=0x30;'C'=0x2E;'D'=0x20;'E'=0x12;'F'=0x21;'G'=0x22;'H'=0x23;'I'=0x17;'J'=0x24;
 'K'=0x25;'L'=0x26;'M'=0x32;'N'=0x31;'O'=0x18;'P'=0x19;'Q'=0x10;'R'=0x13;'S'=0x1F;'T'=0x14;
 'U'=0x16;'V'=0x2F;'W'=0x11;'X'=0x2D;'Y'=0x15;'Z'=0x2C;
 '0'=0x0B;'1'=0x02;'2'=0x03;'3'=0x04;'4'=0x05;'5'=0x06;'6'=0x07;'7'=0x08;'8'=0x09;'9'=0x0A;
 ' '=0x39
}

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WE]::EnumWindows({param($h,$z) $o=0;[void][WE]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WE]::C($h);Text=[WE]::T($h);Vis=[WE]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WE]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WE]::C($c);Text=[WE]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Capture($hwnd,$path){
  $rc=New-Object 'WE+RECT'
  if(-not [WE]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WE+POINT'; $pt.X=0; $pt.Y=0
  [void][WE]::ClientToScreen($hwnd,[ref]$pt)
  try { $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X,$pt.Y,0,0,(New-Object System.Drawing.Size $w,$h))
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); return $true
  } catch { return $false } }
function Mods($m){
  $names = @('dpnet','dplayx','dpwsock','dpnaddr','dpvacm','dplaysvr','ws2_32','wsock32','mswsock','netapi32','iphlpapi')
  $hit = $m.Modules | Where-Object { $n=$_.ModuleName.ToLower(); $names | Where-Object { $n -like "*$_*" } } | Sort-Object ModuleName
  if($hit){ $hit | ForEach-Object { Write-Output ("    LOADED {0}" -f $_.ModuleName) } }
  else { Write-Output "    (none)" } }

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
      if($ok){[void][WE]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WE]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 22){ break } }
}
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
$target = (AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
if(-not $target){ Write-Output "FATAL: no game window"; exit 1 }

function EnsureFocus { for($i=0;$i -lt 3;$i++){ [void][WE]::ForceForeground($target.H); Start-Sleep -Milliseconds 350
    if([WE]::GetForegroundWindow() -eq $target.H){ return $true } } return $false }
function Press($name,$scan,$ext,$settle){
  if(-not (EnsureFocus)){ Write-Output "  !! focus refused before '$name'" }
  [void][WE]::Key([uint16]$scan,$ext,140); Start-Sleep -Milliseconds $settle }

# navigate to Network Mode
Press 'DIK_DOWN -> Battle'  0x50 $true 1800
Press 'DIK_DOWN -> Network' 0x50 $true 1800
Press 'ENTER -> name entry' 0x1C $false 4500
Capture $target.H (Join-Path $OutDir '01-name-entry-before.png') | Out-Null
Write-Output "name entry screen captured"

# type the player name using letter scancodes (letters are NOT extended)
[void](EnsureFocus)
Write-Output ("typing name: {0}" -f $PlayerName)
foreach($ch in $PlayerName.ToUpper().ToCharArray()){
  $s = $scanMap[[string]$ch]
  if($null -ne $s){
    [void][WE]::Key([uint16]$s,$false,70)
    Start-Sleep -Milliseconds 160
  }
}
Start-Sleep -Milliseconds 700
Capture $target.H (Join-Path $OutDir '02-name-typed.png') | Out-Null
Write-Output "name typed, screen captured"

# advance
Press 'ENTER -> continue' 0x1C $false 5000
Capture $target.H (Join-Path $OutDir '03-after-name.png') | Out-Null

$m2 = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if($m2){
  Write-Output ""
  Write-Output "=== dialogs after name entry ==="
  foreach($dw in (AllWins $m2.Id)){ if($dw.Text -eq 'Error Massage'){
    $dk=Kids $dw.H; $msg=($dk|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
    Write-Output ("    DIALOG: {0}" -f $msg)
    $ok=$dk|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
    if($ok){[void][WE]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 400}
  }}
  Write-Output "=== modules ==="
  Mods $m2
}

# press F3 (start/host) which the setup screens use, then observe DirectPlay
Press 'F3 -> attempt host/start' 0x3D $false 6000
Capture $target.H (Join-Path $OutDir '04-after-f3.png') | Out-Null
$m3 = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if($m3){
  Write-Output ""
  Write-Output "=== modules after F3 ==="
  Mods $m3
  foreach($dw in (AllWins $m3.Id)){ if($dw.Text -eq 'Error Massage'){
    $dk=Kids $dw.H; $msg=($dk|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
    Write-Output ("    DIALOG: {0}" -f $msg) }}
  Write-Output ("alive ws={0}MB threads={1}" -f [math]::Round($m3.WorkingSet64/1MB,1),$m3.Threads.Count)
} else { Write-Output "SK-Main EXITED after F3" }

Write-Output ""
Write-Output "=== teardown ==="
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "killing $($_.ProcessName) $($_.Id)"; try{$_.Kill()}catch{} }
