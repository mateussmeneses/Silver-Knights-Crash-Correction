# T-01c: menu navigation via SendInput with SCANCODES.
# DirectInput8 reads scancodes from the raw input stream; keybd_event with VK codes
# and PostMessage(WM_KEYDOWN) are both ignored by a polling DirectInput app.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [string]$OutDir  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t01c"
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WZ {
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
    [DllImport("user32.dll")] public static extern IntPtr GetThreadDesktop(uint tid);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();

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

    // Scancode-only injection: DirectInput reads these from the raw input queue.
    public static uint KeyScan(ushort scan, int holdMs)
    {
        INPUT[] down = new INPUT[1];
        down[0].type = 1;
        down[0].u.ki.wVk = 0;
        down[0].u.ki.wScan = scan;
        down[0].u.ki.dwFlags = 0x0008;   // KEYEVENTF_SCANCODE
        down[0].u.ki.time = 0;
        down[0].u.ki.dwExtraInfo = IntPtr.Zero;
        uint r1 = SendInput(1, down, Marshal.SizeOf(typeof(INPUT)));
        System.Threading.Thread.Sleep(holdMs);
        INPUT[] up = new INPUT[1];
        up[0].type = 1;
        up[0].u.ki.wVk = 0;
        up[0].u.ki.wScan = scan;
        up[0].u.ki.dwFlags = 0x0008 | 0x0002; // SCANCODE | KEYUP
        up[0].u.ki.time = 0;
        up[0].u.ki.dwExtraInfo = IntPtr.Zero;
        SendInput(1, up, Marshal.SizeOf(typeof(INPUT)));
        return r1;
    }
}
'@
if(-not ("WZ" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
function Wins($p_){ $r=New-Object System.Collections.ArrayList
  [WZ]::EnumWindows({param($h,$z) $o=0;[void][WZ]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WZ]::C($h);Text=[WZ]::T($h);Vis=[WZ]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WZ]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WZ]::C($c);Text=[WZ]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Capture($hwnd,$path){
  $rc=New-Object 'WZ+RECT'
  if(-not [WZ]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WZ+POINT'; $pt.X=0; $pt.Y=0
  [void][WZ]::ClientToScreen($hwnd,[ref]$pt)
  try {
    $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X,$pt.Y,0,0,(New-Object System.Drawing.Size $w,$h))
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose(); return $true
  } catch { return $false }
}

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false; $udx=$null
while(((Get-Date)-$t0).TotalSeconds -lt 28){
  Start-Sleep -Milliseconds 350
  foreach($w in (Wins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WZ]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 200}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WZ]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Write-Output ("T+{0:N1} CLICK Window" -f ((Get-Date)-$t0).TotalSeconds); Start-Sleep -Milliseconds 300}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(Wins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 13){ break } }
}
if(-not $udx){ Write-Output "FATAL: no UDX window"; exit 1 }

[void][WZ]::SetForegroundWindow($udx.H)
$rc=New-Object 'WZ+RECT'; [void][WZ]::GetClientRect($udx.H,[ref]$rc)
$pt=New-Object 'WZ+POINT'; $pt.X=[int](($rc.Right-$rc.Left)/2); $pt.Y=[int](($rc.Bottom-$rc.Top)/2)
[void][WZ]::ClientToScreen($udx.H,[ref]$pt); [void][WZ]::SetCursorPos($pt.X,$pt.Y)
Start-Sleep -Milliseconds 800
$fg=[WZ]::GetForegroundWindow()
Write-Output ("T+{0:N1} focus check: foreground=0x{1:X} target=0x{2:X} match={3}" -f ((Get-Date)-$t0).TotalSeconds,$fg.ToInt64(),$udx.H.ToInt64(),($fg -eq $udx.H))

function Snap($label){ $p=Join-Path $OutDir ("{0}.png" -f $label); Capture $udx.H $p | Out-Null }

# Scancodes: Down=0x50, Up=0x48, Enter=0x1C, Esc=0x01, Space=0x39
Snap 'A-baseline'
Write-Output "SCAN DOWN (0x50)"
[void][WZ]::KeyScan(0x50, 120); Start-Sleep -Milliseconds 1200; Snap 'B-down1'
Write-Output "SCAN DOWN"
[void][WZ]::KeyScan(0x50, 120); Start-Sleep -Milliseconds 1200; Snap 'C-down2'
Write-Output "SCAN ENTER (0x1C)"
[void][WZ]::KeyScan(0x1C, 120); Start-Sleep -Milliseconds 3000; Snap 'D-enter'

Write-Output ""
Write-Output "=== compare with imgdiff ==="
Write-Output ("images in {0}" -f $OutDir)
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