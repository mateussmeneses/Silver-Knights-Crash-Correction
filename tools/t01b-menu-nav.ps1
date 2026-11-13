# T-01b: prove menu navigation by injecting input at the hardware level.
# The game polls DirectInput8, so PostMessage/WM_KEYDOWN never reaches it.
# SendInput writes to the raw input stream that DirectInput reads.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [string]$OutDir  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t01b",
    [int]$RunSeconds = 75
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WY {
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
    [DllImport("user32.dll")] public static extern IntPtr SetActiveWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);

    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X,Y; }
    [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx,dy; public uint mouseData,dwFlags,time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT { public ushort wVk,wScan; public uint dwFlags,time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] public struct HARDWAREINPUT { public uint uMsg; public ushort wParamL,wParamH; }
    [StructLayout(LayoutKind.Explicit)] public struct INPUTUNION {
        [FieldOffset(0)] public MOUSEINPUT mi;
        [FieldOffset(0)] public KEYBDINPUT ki;
        [FieldOffset(0)] public HARDWAREINPUT hi; }
    [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type; public INPUTUNION u; }

    [DllImport("user32.dll", SetLastError=true)] public static extern uint SendInput(uint n, INPUT[] p, int cb);

    public static string T(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string C(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }

    // keybd_event is simpler and also reaches DirectInput via the raw input queue
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);

    public static void Key(byte vk, int holdMs)
    {
        keybd_event(vk, 0, 0, IntPtr.Zero);
        System.Threading.Thread.Sleep(holdMs);
        keybd_event(vk, 0, 2, IntPtr.Zero); // KEYEVENTF_KEYUP
    }
}
'@
if(-not ("WY" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
function Wins($p_){ $r=New-Object System.Collections.ArrayList
  [WY]::EnumWindows({param($h,$z) $o=0;[void][WY]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WY]::C($h);Text=[WY]::T($h);Vis=[WY]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WY]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WY]::C($c);Text=[WY]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Capture($hwnd,$path){
  $rc=New-Object 'WY+RECT'
  if(-not [WY]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WY+POINT'; $pt.X=0; $pt.Y=0
  [void][WY]::ClientToScreen($hwnd,[ref]$pt)
  try {
    $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X,$pt.Y,0,0,(New-Object System.Drawing.Size $w,$h))
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose(); return $true
  } catch { Write-Output ("  capture error: " + $_.Exception.Message); return $false }
}
function HashOf($path){
  $sha=[System.Security.Cryptography.SHA256]::Create()
  $h=($sha.ComputeHash([System.IO.File]::ReadAllBytes($path)) | ForEach-Object { $_.ToString('x2') }) -join ''
  $sha.Dispose(); return $h }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi; [void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH SK-Startup pid=$($sp.Id)"
$clicked=$false

# wait for menu
$udx=$null
while(((Get-Date)-$t0).TotalSeconds -lt 25){
  Start-Sleep -Milliseconds 350
  foreach($w in (Wins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WY]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 200}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WY]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Write-Output ("T+{0:N1} CLICK Window" -f ((Get-Date)-$t0).TotalSeconds); Start-Sleep -Milliseconds 300}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(Wins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 12){ break } }
}
if(-not $udx){ Write-Output "FATAL: no UDX window"; exit 1 }
Write-Output ("T+{0:N1} MENU READY hwnd=0x{1:X}" -f ((Get-Date)-$t0).TotalSeconds, $udx.H.ToInt64())

# focus hard
[void][WY]::SetForegroundWindow($udx.H); [void][WY]::SetActiveWindow($udx.H)
$rc=New-Object 'WY+RECT'; [void][WY]::GetClientRect($udx.H,[ref]$rc)
$pt=New-Object 'WY+POINT'; $pt.X=[int](($rc.Right-$rc.Left)/2); $pt.Y=[int](($rc.Bottom-$rc.Top)/2)
[void][WY]::ClientToScreen($udx.H,[ref]$pt)
[void][WY]::SetCursorPos($pt.X,$pt.Y)
Start-Sleep -Milliseconds 600

$frames=New-Object System.Collections.ArrayList
function Snap($label){
  $p=Join-Path $OutDir ("{0}.png" -f $label)
  if(Capture $udx.H $p){
    $h=HashOf $p
    $frames.Add([pscustomobject]@{N=$label;Hash=$h;Bytes=(Get-Item $p).Length})
    Write-Output ("  SNAP {0,-18} sha={1} bytes={2}" -f $label,$h.Substring(0,16),(Get-Item $p).Length)
  } else { Write-Output ("  SNAP {0} FAILED" -f $label) }
}

Snap 'A-baseline'
Write-Output "SEND: Down (keybd_event, 90ms)"
[WY]::Key(0x28, 90); Start-Sleep -Milliseconds 900; Snap 'B-after-down1'
Write-Output "SEND: Down"
[WY]::Key(0x28, 90); Start-Sleep -Milliseconds 900; Snap 'C-after-down2'
Write-Output "SEND: Down"
[WY]::Key(0x28, 90); Start-Sleep -Milliseconds 900; Snap 'D-after-down3'
Write-Output "SEND: Up"
[WY]::Key(0x26, 90); Start-Sleep -Milliseconds 900; Snap 'E-after-up1'
Write-Output "SEND: Enter"
[WY]::Key(0x0D, 90); Start-Sleep -Milliseconds 2500; Snap 'F-after-enter'
Write-Output "SEND: Esc"
[WY]::Key(0x1B, 90); Start-Sleep -Milliseconds 2000; Snap 'G-after-esc'

Write-Output ""
Write-Output "=== FRAME ANALYSIS ==="
$distinct=@($frames|Select-Object -ExpandProperty Hash -Unique)
Write-Output ("frames={0} distinct={1}" -f $frames.Count,$distinct.Count)
$frames | ForEach-Object { Write-Output ("  {0,-18} {1}" -f $_.N,$_.Hash.Substring(0,24)) }
Write-Output ""
if($distinct.Count -ge 3){ Write-Output "RESULT: INPUT REACHES THE GAME - multiple distinct frames from navigation." }
elseif($distinct.Count -eq 2){ Write-Output "RESULT: ONE CHANGE - limited response; inspect images." }
else { Write-Output "RESULT: NO RESPONSE to hardware-level input." }
Write-Output ""
Write-Output "=== teardown ==="
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "killing $($_.ProcessName) $($_.Id)"; try{$_.Kill()}catch{} }
