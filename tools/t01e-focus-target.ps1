# T-01e: identify the REAL input window, then inject there.
# Earlier runs targeted the first visible UDX_CLASS window, but the foreground
# window had a DIFFERENT handle -> two UDX_CLASS windows exist and the wrong one
# was being driven. This run enumerates every window, reports which one is
# foreground, injects into the foreground window, and captures that same window.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [string]$OutDir  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t01e"
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WU {
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
    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr h, uint cmd);
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int idx);
    [DllImport("user32.dll")] public static extern IntPtr GetProcessWindowStation();

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

    // True if h is the foreground window or a descendant of it
    public static bool IsForegroundOrChild(IntPtr h, IntPtr fg)
    {
        if (h == fg) return true;
        IntPtr walk = fg;
        for (int i = 0; i < 8 && walk != IntPtr.Zero; i++)
        {
            if (walk == h) return true;
            walk = GetWindow(walk, 5); // GW_OWNER
        }
        return false;
    }
}
'@
if(-not ("WU" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi; [void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WU]::EnumWindows({param($h,$z) $o=0;[void][WU]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WU]::C($h);Text=[WU]::T($h);Vis=[WU]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WU]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WU]::C($c);Text=[WU]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Capture($hwnd,$path){
  $rc=New-Object 'WU+RECT'
  if(-not [WU]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WU+POINT'; $pt.X=0; $pt.Y=0
  [void][WU]::ClientToScreen($hwnd,[ref]$pt)
  try { $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X,$pt.Y,0,0,(New-Object System.Drawing.Size $w,$h))
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); return $true
  } catch { return $false } }

# settle
while(((Get-Date)-$t0).TotalSeconds -lt 28){
  Start-Sleep -Milliseconds 350
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WU]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 200}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WU]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Write-Output ("T+{0:N1} CLICK Window" -f ((Get-Date)-$t0).TotalSeconds); Start-Sleep -Milliseconds 300}
    }
  }
}
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if(-not $m){ Write-Output "FATAL: SK-Main not running"; exit 1 }

Write-Output ""
Write-Output "=== ALL SK-Main windows (pid $($m.Id)) ==="
$all = AllWins $m.Id
foreach($w in $all){
  Write-Output ("  hwnd=0x{0:X10}  cls={1,-22} vis={2,-5} text='{3}'" -f $w.H.ToInt64(),$w.Cls,$w.Vis,$w.Text)
}

$fg=[WU]::GetForegroundWindow()
Write-Output ""
Write-Output ("FOREGROUND hwnd=0x{0:X}  class={1}  text='{2}'" -f $fg.ToInt64(),[WU]::C($fg),[WU]::T($fg))

# Choose the input target: prefer a visible UDX_CLASS window; if the foreground
# is a UDX window use it. Report the decision explicitly.
$udxAll = @($all | Where-Object { $_.Cls -eq 'UDX_CLASS' })
Write-Output ("UDX_CLASS windows found: {0}" -f $udxAll.Count)
$target = $udxAll | Where-Object { $_.H -eq $fg } | Select-Object -First 1
if(-not $target){ $target = $udxAll | Where-Object { $_.Vis } | Select-Object -First 1 }
if(-not $target){ Write-Output "FATAL: no UDX window"; exit 1 }
Write-Output ("TARGET hwnd=0x{0:X} vis={1} text='{2}'" -f $target.H.ToInt64(),$target.Vis,$target.Text)

# Focus it, verify, and retry once if needed
[void][WU]::SetForegroundWindow($target.H)
Start-Sleep -Milliseconds 700
$fg2=[WU]::GetForegroundWindow()
if($fg2 -ne $target.H){
  Write-Output ("re-focus attempt: fg=0x{0:X} target=0x{1:X}" -f $fg2.ToInt64(),$target.H.ToInt64())
  [void][WU]::SetForegroundWindow($target.H); Start-Sleep -Milliseconds 700
  $fg2=[WU]::GetForegroundWindow()
}
$rc=New-Object 'WU+RECT'; [void][WU]::GetClientRect($target.H,[ref]$rc)
$pt=New-Object 'WU+POINT'; $pt.X=[int](($rc.Right-$rc.Left)/2); $pt.Y=[int](($rc.Bottom-$rc.Top)/2)
[void][WU]::ClientToScreen($target.H,[ref]$pt); [void][WU]::SetCursorPos($pt.X,$pt.Y)
Start-Sleep -Milliseconds 500
Write-Output ("FOCUS FINAL: fg=0x{0:X} target=0x{1:X} match={2}" -f [WU]::GetForegroundWindow().ToInt64(),$target.H.ToInt64(),([WU]::GetForegroundWindow() -eq $target.H))
Write-Output ""

function Snap($label){ $p=Join-Path $OutDir ("{0}.png" -f $label)
  if(Capture $target.H $p){ Write-Output ("  SNAP {0}" -f $label) } else { Write-Output ("  SNAP {0} FAILED" -f $label) } }
function Step($desc,$scan,$ext){
  Write-Output ("  >> {0} (scan=0x{1:X2} ext={2})" -f $desc,$scan,$ext)
  [void][WU]::Key([uint16]$scan,$ext,130); Start-Sleep -Milliseconds 1500 }

Snap 'A-baseline'
Step 'DIK_DOWN ext' 0x50 $true;  Snap 'B-down1'
Step 'DIK_DOWN ext' 0x50 $true;  Snap 'C-down2'
Step 'DIK_DOWN ext' 0x50 $true;  Snap 'D-down3'
Step 'DIK_UP   ext' 0x48 $true;  Snap 'E-up1'
Step 'Enter plain'  0x1C $false; Snap 'F-enter'

Write-Output ""
Write-Output "=== teardown ==="
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "killing $($_.ProcessName) $($_.Id)"; try{$_.Kill()}catch{} }
