# T-01f: take real focus with AttachThreadInput, then inject DIK scancodes.
#
# Diagnostics from run-23: there is exactly ONE UDX_CLASS window, and
# SetForegroundWindow was REFUSED - the PowerShell console stayed foreground.
# That is Windows' foreground lock: a process that did not receive the last input
# event cannot call SetForegroundWindow directly. DirectInput8 polls the keyboard
# attached to the foreground thread, so without real focus no injected key is seen.
#
# Standard remedy: AttachThreadInput(current, foreground, true) -> SetForegroundWindow
# -> AttachThreadInput(false), plus the ALT-tap unlock.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [string]$OutDir  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t01f"
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WT {
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
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SetActiveWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
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

    // Force foreground using the AttachThreadInput + ALT-tap technique.
    public static bool ForceForeground(IntPtr target)
    {
        uint myTid  = GetCurrentThreadId();
        IntPtr fg   = GetForegroundWindow();
        uint fgPid; uint fgTid = GetWindowThreadProcessId(fg, out fgPid);

        // Classic unlock: a synthetic ALT press makes the OS permit the change.
        keybd_event(0x12, 0, 0, IntPtr.Zero);
        keybd_event(0x12, 0, 2, IntPtr.Zero);

        bool a1 = AttachThreadInput(myTid, fgTid, true);
        bool a2 = false;
        uint tp; uint tTid = GetWindowThreadProcessId(target, out tp);
        if (tTid != fgTid) a2 = AttachThreadInput(myTid, tTid, true);

        BringWindowToTop(target);
        SetActiveWindow(target);
        bool ok = SetForegroundWindow(target);
        SetFocus(target);

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
if(-not ("WT" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WT]::EnumWindows({param($h,$z) $o=0;[void][WT]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WT]::C($h);Text=[WT]::T($h);Vis=[WT]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WT]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WT]::C($c);Text=[WT]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Capture($hwnd,$path){
  $rc=New-Object 'WT+RECT'
  if(-not [WT]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WT+POINT'; $pt.X=0; $pt.Y=0
  [void][WT]::ClientToScreen($hwnd,[ref]$pt)
  try { $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X,$pt.Y,0,0,(New-Object System.Drawing.Size $w,$h))
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); return $true
  } catch { return $false } }

while(((Get-Date)-$t0).TotalSeconds -lt 26){
  Start-Sleep -Milliseconds 350
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WT]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 200}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WT]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Write-Output ("T+{0:N1} CLICK Window" -f ((Get-Date)-$t0).TotalSeconds); Start-Sleep -Milliseconds 300}
    }
  }
}
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if(-not $m){ Write-Output "FATAL: SK-Main not running"; exit 1 }
$target = (AllWins $m.Id) | Where-Object { $_.Cls -eq 'UDX_CLASS' -and $_.Vis } | Select-Object -First 1
if(-not $target){ Write-Output "FATAL: no UDX window"; exit 1 }
Write-Output ("TARGET hwnd=0x{0:X}" -f $target.H.ToInt64())

[void][WT]::ShowWindow($target.H, 9)   # SW_RESTORE
Start-Sleep -Milliseconds 400
$ok = [WT]::ForceForeground($target.H)
Start-Sleep -Milliseconds 900
$fg = [WT]::GetForegroundWindow()
Write-Output ("ForceForeground returned {0}; fg=0x{1:X} class={2} match={3}" -f $ok,$fg.ToInt64(),[WT]::C($fg),($fg -eq $target.H))

$rc=New-Object 'WT+RECT'; [void][WT]::GetClientRect($target.H,[ref]$rc)
$pt=New-Object 'WT+POINT'; $pt.X=[int](($rc.Right-$rc.Left)/2); $pt.Y=[int](($rc.Bottom-$rc.Top)/2)
[void][WT]::ClientToScreen($target.H,[ref]$pt); [void][WT]::SetCursorPos($pt.X,$pt.Y)
Start-Sleep -Milliseconds 400
$fg = [WT]::GetForegroundWindow()
Write-Output ("FOCUS NOW: fg=0x{0:X} match={1}" -f $fg.ToInt64(),($fg -eq $target.H))
Write-Output ""

function Snap($l){ $p=Join-Path $OutDir ("{0}.png" -f $l); if(Capture $target.H $p){ Write-Output ("  SNAP {0}" -f $l) } }
function Step($d,$s,$e){ Write-Output ("  >> {0}" -f $d); [void][WT]::Key([uint16]$s,$e,130); Start-Sleep -Milliseconds 1500 }

Snap 'A-baseline'
Step 'DIK_DOWN ext x1' 0x50 $true;  Snap 'B-down1'
Step 'DIK_DOWN ext x2' 0x50 $true;  Snap 'C-down2'
Step 'DIK_UP   ext x1' 0x48 $true;  Snap 'D-up1'
Step 'Enter plain'     0x1C $false; Snap 'E-enter'

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