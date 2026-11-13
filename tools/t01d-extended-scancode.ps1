# T-01d: menu navigation with correct DIK/extended-scancode semantics.
#
# Evidence for the config contract (SilverKnights.ini [KEYBOARD]):
#   UP=200  DOWN=208  LEFT=203  RIGHT=205   -> DIK_UP/DOWN/LEFT/RIGHT (0x80|scancode)
#   ATTACK1=48 (DIK_B)  ATTACK2=47 (DIK_V)  GUARD=45 (DIK_X)  BOOST=46 (DIK_C)
#   LOCK=49 (DIK_N)     SUPPORT=44 (DIK_Z)  CALLSUPP=33 (DIK_F) CALLSPEAR=32 (DIK_D)
# so the game reads DirectInput SCANCODES, not virtual keys.
#
# Arrow keys are E0-prefixed EXTENDED scancodes. Injecting 0x50 without
# KEYEVENTF_EXTENDEDKEY delivers NumPad-2, not Down. That was the flaw in the
# previous attempt. This run sets the flag.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [string]$OutDir  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t01d"
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WV {
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

    // Scancode injection with explicit extended-key control.
    //   ext=true  -> E0-prefixed (arrows, right-ctrl, numpad-enter, ...)
    //   ext=false -> plain Set-1 scancode (letters, digits, Enter, Esc, Space)
    public static uint Key(ushort scan, bool ext, int holdMs)
    {
        uint baseFlags = 0x0008;                    // KEYEVENTF_SCANCODE
        if (ext) baseFlags |= 0x0001;               // KEYEVENTF_EXTENDEDKEY

        INPUT[] down = new INPUT[1];
        down[0].type = 1;
        down[0].u.ki.wVk = 0;
        down[0].u.ki.wScan = scan;
        down[0].u.ki.dwFlags = baseFlags;
        uint r = SendInput(1, down, Marshal.SizeOf(typeof(INPUT)));
        System.Threading.Thread.Sleep(holdMs);

        INPUT[] up = new INPUT[1];
        up[0].type = 1;
        up[0].u.ki.wVk = 0;
        up[0].u.ki.wScan = scan;
        up[0].u.ki.dwFlags = baseFlags | 0x0002;    // | KEYEVENTF_KEYUP
        SendInput(1, up, Marshal.SizeOf(typeof(INPUT)));
        return r;
    }
}
'@
if(-not ("WV" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
function Wins($p_){ $r=New-Object System.Collections.ArrayList
  [WV]::EnumWindows({param($h,$z) $o=0;[void][WV]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WV]::C($h);Text=[WV]::T($h);Vis=[WV]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WV]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WV]::C($c);Text=[WV]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Capture($hwnd,$path){
  $rc=New-Object 'WV+RECT'
  if(-not [WV]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WV+POINT'; $pt.X=0; $pt.Y=0
  [void][WV]::ClientToScreen($hwnd,[ref]$pt)
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

# wait for the menu, then give the intro a long settle so the menu is interactive
while(((Get-Date)-$t0).TotalSeconds -lt 40){
  Start-Sleep -Milliseconds 350
  foreach($w in (Wins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][WV]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 200}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][WV]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Write-Output ("T+{0:N1} CLICK Window" -f ((Get-Date)-$t0).TotalSeconds); Start-Sleep -Milliseconds 300}
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m){ $udx=(Wins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
    if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 30){ break } }
}
if(-not $udx){ Write-Output "FATAL: no UDX window"; exit 1 }

# hard focus + cursor inside the client area
[void][WV]::SetForegroundWindow($udx.H)
$rc=New-Object 'WV+RECT'; [void][WV]::GetClientRect($udx.H,[ref]$rc)
$pt=New-Object 'WV+POINT'; $pt.X=[int](($rc.Right-$rc.Left)/2); $pt.Y=[int](($rc.Bottom-$rc.Top)/2)
[void][WV]::ClientToScreen($udx.H,[ref]$pt); [void][WV]::SetCursorPos($pt.X,$pt.Y)
Start-Sleep -Milliseconds 900
Write-Output ("T+{0:N1} focus: fg=0x{1:X} target=0x{2:X} match={3}" -f ((Get-Date)-$t0).TotalSeconds,[WV]::GetForegroundWindow().ToInt64(),$udx.H.ToInt64(),([WV]::GetForegroundWindow() -eq $udx.H))

function Snap($label){ $p=Join-Path $OutDir ("{0}.png" -f $label); [void](Capture $udx.H $p) }
function Step($desc, $scan, $ext){
  Write-Output ("  >> {0}  (scancode 0x{1:X2}, extended={2})" -f $desc,$scan,$ext)
  [void][WV]::Key([uint16]$scan, $ext, 130)
  Start-Sleep -Milliseconds 1400
}

Snap 'A-baseline'

# DIK_DOWN = 0xD0 -> scancode 0x50, EXTENDED. This is the case the earlier run got wrong.
Step 'DIK_DOWN x1 (extended)' 0x50 $true;  Snap 'B-down-ext1'
Step 'DIK_DOWN x2 (extended)' 0x50 $true;  Snap 'C-down-ext2'
Step 'DIK_UP   x1 (extended)' 0x48 $true;  Snap 'D-up-ext1'
# Non-extended confirm candidates: Enter 0x1C, DIK_B (ATTACK1) 0x30
Step 'Enter 0x1C (plain)'     0x1C $false; Snap 'E-enter'
Step 'DIK_B 0x30 (plain)'     0x30 $false; Snap 'F-keyB'

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
Write-Output "images: $OutDir"
