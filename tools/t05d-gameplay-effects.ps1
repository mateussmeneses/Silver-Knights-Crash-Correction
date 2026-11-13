# T-05d: matched-camera effect comparison DURING GAMEPLAY.
#
# run-35 proved the Battle setup screen does NOT apply post-processing effects
# (byte-identical frames under effects-off vs effects-on), so that screen cannot be
# used as the comparison surface. Effects are only applied to the live 3D match.
#
# A replay could not be recorded (run-34), so the camera cannot be frozen exactly.
# Mitigation used here: capture a BURST of frames per profile immediately after the
# match starts, from the match-start camera pose, which is deterministic
# ("Battle Start" -> fixed spawn view). Then compare like-for-like earliest frames.
#
# This is explicitly a best-effort matched comparison. Any residual difference is
# reported, not hidden.
param(
    [string]$WorkDir   = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox4",
    [string]$OutDir    = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\t05d",
    [string]$IniSource = "C:\projetos\Silver-Knights-Crash-Correction\SilverKnights.ini"
)
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WC {
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
if(-not ("WC" -as [type])){ Write-Output "FATAL: Add-Type failed"; exit 1 }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$iniPath  = Join-Path $WorkDir 'SilverKnights.ini'
$backup   = Join-Path $WorkDir 'SilverKnights.ini.t05d-backup'
$original = Get-Content $IniSource -Raw
Copy-Item $IniSource $backup -Force

function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [WC]::EnumWindows({param($h,$z) $o=0;[void][WC]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[WC]::C($h);Text=[WC]::T($h);Vis=[WC]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [WC]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[WC]::C($c);Text=[WC]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Capture($hwnd,$path){
  $rc=New-Object 'WC+RECT'
  if(-not [WC]::GetClientRect($hwnd,[ref]$rc)){ return $false }
  $w=$rc.Right-$rc.Left; $h=$rc.Bottom-$rc.Top
  if($w -le 0 -or $h -le 0){ return $false }
  $pt=New-Object 'WC+POINT'; $pt.X=0; $pt.Y=0
  [void][WC]::ClientToScreen($hwnd,[ref]$pt)
  try { $bmp=New-Object System.Drawing.Bitmap $w,$h
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X,$pt.Y,0,0,(New-Object System.Drawing.Size $w,$h))
    $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); return $true
  } catch { return $false } }

function Launch {
  $psi=New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
  $sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
  $t0=Get-Date; $clicked=$false
  while(((Get-Date)-$t0).TotalSeconds -lt 28){
    Start-Sleep -Milliseconds 350
    foreach($w in (AllWins $sp.Id)){
      if($w.Text -eq 'Error Massage'){
        $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
        if($ok){[void][WC]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
      } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
        $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
        if($b){[void][WC]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
      }
    }
    $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
    if($m){ $udx=(AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1
      if($udx -and ((Get-Date)-$t0).TotalSeconds -gt 22){ break } }
  }
  $m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if(-not $m){ return $null }
  return [pscustomobject]@{Proc=$m; Win=((AllWins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS' -and $_.Vis}|Select-Object -First 1)} }
function EnsureFocus($t){ for($i=0;$i -lt 3;$i++){ [void][WC]::ForceForeground($t); Start-Sleep -Milliseconds 350
    if([WC]::GetForegroundWindow() -eq $t){ return $true } } return $false }
function Press($t,$scan,$ext,$settle){ if(-not (EnsureFocus $t)){ Write-Output "    !! focus refused" }
  [void][WC]::Key([uint16]$scan,$ext,140); Start-Sleep -Milliseconds $settle }

function RunProfile($label,$set){
  Write-Output ""
  Write-Output ("##### {0} #####" -f $label)
  Write-Output ("  ini: " + (($set.GetEnumerator()|Sort-Object Name|ForEach-Object{"$($_.Key)=$($_.Value)"}) -join ' '))
  $text = $original
  foreach($k in $set.Keys){
    $pattern = "(?m)^(\s*$([regex]::Escape($k))\s*=\s*).*$"
    if($text -match $pattern){ $text = [regex]::Replace($text,$pattern,('${1}'+$set[$k])) }
    else { Write-Output ("  WARN missing key "+$k) }
  }
  [System.IO.File]::WriteAllText($iniPath,$text)

  $r = Launch
  if(-not $r){ Write-Output "  LAUNCH FAILED"; return }
  $udx = $r.Win.H
  Press $udx 0x50 $true  2500     # Battle Mode
  Press $udx 0x1C $false 2600     # setup
  Press $udx 0x3D $false 5200     # F3 start
  Press $udx 0x1C $false 3000     # confirm

  # Burst captures from the deterministic match-start pose. No movement input, so the
  # camera stays near the spawn view; the first burst frame is the most comparable.
  for($i=1;$i -le 4;$i++){
    $p = Join-Path $OutDir ("{0}-{1}.png" -f $label,$i)
    if(Capture $udx $p){ Write-Output ("  cap{0} {1} bytes" -f $i,(Get-Item $p).Length) }
    Start-Sleep -Milliseconds 850
  }
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
  Start-Sleep -Milliseconds 1400
}

try {
  RunProfile 'off' @{ EFFECT_LEVEL='1'; HDR_LIGHTING='0'; DEPTH_OF_FIELD='0'; BLUR_2_5D='0'; OUTLINE='0'; MOTION_BLUR='0' }
  RunProfile 'on'  @{ EFFECT_LEVEL='3'; HDR_LIGHTING='1'; DEPTH_OF_FIELD='1'; BLUR_2_5D='1'; OUTLINE='1'; THICKNESS='1'; MOTION_BLUR='1' }
} finally {
  Copy-Item $backup $iniPath -Force
  Remove-Item $backup -Force -ErrorAction SilentlyContinue
  $restored = Get-Content $iniPath -Raw
  if($restored -eq $original){ Write-Output "`nRESTORED SilverKnights.ini, verified byte-identical" }
  else { Write-Output "`nWARN: INI restore differs" }
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
}
