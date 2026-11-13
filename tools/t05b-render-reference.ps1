# T-05b: exercise the high-end renderer and capture the visual reference.
#
# SilverKnights.ini ships EFFECT_LEVEL=1 (lowest), so run-27 never exercised the
# HDR / bloom / depth-of-field / 2.5D-blur / outline / motion-blur D3DX paths.
# Those are exactly what a translation layer (DXVK / MoltenVK) breaks first, so a
# verified high-effect reference on Windows is the yardstick for Linux and macOS.
#
# This script:
#   1. backs up SilverKnights.ini
#   2. for each effect profile: rewrites the INI, launches, starts a match, captures
#   3. ALWAYS restores the original INI (finally block)
#
# It never touches a tracked binary and never leaves the INI modified.
param(
    [string]$WorkDir   = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox2",
    [string]$OutDir    = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t05b",
    [string]$IniSource = "C:\projetos\Silver-Knights-Crash-Correction\SilverKnights.ini"
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WH {
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
if(-not ("WH" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$iniPath  = Join-Path $WorkDir 'SilverKnights.ini'
$backup   = Join-Path $WorkDir 'SilverKnights.ini.t05b-backup'
$original = Get-Content $IniSource -Raw
Copy-Item $IniSource $backup -Force
Write-Output "backed up INI to $backup"

# Effect profiles. EFFECT_LEVEL's valid range is NOT documented in any shipped file,
# so 3 is used as "high" rather than guessing a higher number. Each profile isolates
# features so the image difference can be attributed.
$profiles = @(
  @{ name='00-baseline-effectlevel-1';   set=@{ EFFECT_LEVEL='1'; HDR_LIGHTING='0'; DEPTH_OF_FIELD='0'; BLUR_2_5D='0'; OUTLINE='0'; MOTION_BLUR='0'; BODY_EFFECT='1' } },
  @{ name='01-effectlevel-3';            set=@{ EFFECT_LEVEL='3'; HDR_LIGHTING='0'; DEPTH_OF_FIELD='0'; BLUR_2_5D='0'; OUTLINE='0'; MOTION_BLUR='0'; BODY_EFFECT='1' } },
  @{ name='02-hdr-dof';                  set=@{ EFFECT_LEVEL='3'; HDR_LIGHTING='1'; DEPTH_OF_FIELD='1'; BLUR_2_5D='0'; OUTLINE='0'; MOTION_BLUR='0'; BODY_EFFECT='1' } },
  @{ name='03-all-effects';              set=@{ EFFECT_LEVEL='3'; HDR_LIGHTING='1'; DEPTH_OF_FIELD='1'; BLUR_2_5D='1'; OUTLINE='1'; THICKNESS='1'; MOTION_BLUR='1'; BODY_EFFECT='1' } }
)

function Set-IniValues([string]$text, [hashtable]$set){
  foreach($k in $set.Keys){
    $pattern = "(?m)^(\s*$([regex]::Escape($k))\s*=\s*).*$"
    if($text -match $pattern){ $text = [regex]::Replace($text, $pattern, ('${1}' + $set[$k])) }
    else { Write-Output ("  WARN: INI key not found: {0}" -f $k) }
  }
  return $text }

function Capture($hwnd,$path){
  $rc=New-Object 'WH+RECT'
  if(-not [WH]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WH+POINT'; $pt.X=0; $pt.Y=0
  [void][WH]::ClientToScreen($hwnd,[ref]$pt)
  try { $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X,$pt.Y,0,0,(New-Object System.Drawing.Size $w,$h))
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); return $true
  } catch { return $false } }

function RunProfile($prof){
  $label = $prof.name
  Write-Output ""
  Write-Output ("##### PROFILE {0} #####" -f $label)
  Write-Output ("  settings: " + (($prof.set.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' '))

  $text = Set-IniValues $original $prof.set
  [System.IO.File]::WriteAllText($iniPath, $text)

  $psi=New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
  $sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi; [void]$sp.Start()
  $t0=Get-Date; Write-Output "  T+0 LAUNCH pid=$($sp.Id)"
  $clicked=$false; $dialogs=0

  function AllWins($p_){ $r=New-Object System.Collections.ArrayList
    [WH]::EnumWindows({param($h,$z) $o=0;[void][WH]::GetWindowThreadProcessId($h,[ref]$o)
      if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WH]::C($h);Text=[WH]::T($h);Vis=[WH]::IsWindowVisible($h)})}
      return $true},[IntPtr]::Zero)|Out-Null; return $r }
  function Kids($h){ $r=New-Object System.Collections.ArrayList
    [WH]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WH]::C($c);Text=[WH]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

  while(((Get-Date)-$t0).TotalSeconds -lt 30){
    Start-Sleep -Milliseconds 350
    foreach($w in (AllWins $sp.Id)){
      if($w.Text -eq 'Error Massage'){
        $k=Kids $w.H; $msg=($k|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
        Write-Output ("  T+{0:N1} [Startup] DIALOG: {1}" -f ((Get-Date)-$t0).TotalSeconds,$msg)
        $ok=$k|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
        if($ok){[void][WH]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
      } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
        $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
        if($b){[void][WH]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true
          Write-Output ("  T+{0:N1} CLICK Window" -f ((Get-Date)-$t0).TotalSeconds); Start-Sleep -Milliseconds 400}
      }
    }
    $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
    if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
      if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 22){ break } }
  }
  $m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if(-not $m){ Write-Output "  FAIL: SK-Main not running"; return }
  $target = (AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
  if(-not $target){ Write-Output "  FAIL: no game window"; return }

  function EnsureFocus { for($i=0;$i -lt 3;$i++){ [void][WH]::ForceForeground($target.H); Start-Sleep -Milliseconds 350
      if([WH]::GetForegroundWindow() -eq $target.H){ return $true } } return $false }
  function Press($scan,$ext,$settle){ if(-not (EnsureFocus)){ Write-Output "  !! focus refused" }
    [void][WH]::Key([uint16]$scan,$ext,140); Start-Sleep -Milliseconds $settle }

  # menu -> Battle -> setup -> F3 start
  Press 0x50 $true  2600     # DIK_DOWN -> Battle Mode
  Press 0x1C $false 2600     # ENTER -> setup
  Press 0x3D $false 6000     # F3 -> start
  Press 0x1C $false 4000     # confirm

  # let the match run so effects are applied, then capture twice
  Start-Sleep -Milliseconds 2500
  $p1 = Join-Path $OutDir ("{0}-a.png" -f $label)
  if(Capture $target.H $p1){ Write-Output ("  SNAP {0}-a.png {1} bytes" -f $label,(Get-Item $p1).Length) }
  Start-Sleep -Milliseconds 3000
  $p2 = Join-Path $OutDir ("{0}-b.png" -f $label)
  if(Capture $target.H $p2){ Write-Output ("  SNAP {0}-b.png {1} bytes" -f $label,(Get-Item $p2).Length) }

  # detect any SK-Main error dialog that appeared during the match
  foreach($dw in (AllWins $m.Id)){ if($dw.Text -eq 'Error Massage'){
    $dk=Kids $dw.H; $dmsg=($dk|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
    Write-Output ("  !! [SK-Main] ERROR DIALOG: {0}" -f $dmsg) } }

  Write-Output ("  elapsed {0:N1}s, ws={1}MB, threads={2}" -f ((Get-Date)-$t0).TotalSeconds,[math]::Round($m.WorkingSet64/1MB,1),$m.Threads.Count)
  Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { try{$_.Kill()}catch{} }
  Start-Sleep -Milliseconds 1200
}

try {
  foreach($prof in $profiles){ RunProfile $prof }
} finally {
  # ALWAYS restore the shipped configuration
  Copy-Item $backup $iniPath -Force
  Remove-Item $backup -Force -ErrorAction SilentlyContinue
  Write-Output ""
  Write-Output "RESTORED SilverKnights.ini from backup"
  $restored = Get-Content $iniPath -Raw
  if($restored -eq $original){ Write-Output "VERIFY: restored content is byte-identical to the shipped file" }
  else { Write-Output "WARN: restored content DIFFERS from the shipped file - inspect manually" }
  Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { try{$_.Kill()}catch{} }
}
Write-Output "images in $OutDir"
