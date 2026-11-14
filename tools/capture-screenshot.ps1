# Run the patched build, wait for the render window, capture a screenshot as evidence.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [string]$Button  = "Window",
    [int]$RunSeconds = 45,
    [int]$ShotAt = 12,
    [string]$OutPng  = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\sk-patched-running.png"
)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W3 {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
    public static string Text(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string Cls(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
}
'@
function Wins($p_){ $r=New-Object System.Collections.ArrayList
  [W3]::EnumWindows({param($h,$z) $o=0;[void][W3]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_ -and [W3]::IsWindowVisible($h)){$rc=New-Object 'W3+RECT';[void][W3]::GetWindowRect($h,[ref]$rc)
      [void]$r.Add([pscustomobject]@{H=$h;Cls=[W3]::Cls($h);Text=[W3]::Text($h);L=$rc.Left;T=$rc.Top;R=$rc.Right;B=$rc.Bottom})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [W3]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[W3]::Cls($c);Text=[W3]::Text($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false; $shot=$false
$deadline=$t0.AddSeconds($RunSeconds)
while((Get-Date) -lt $deadline){
  Start-Sleep -Milliseconds 500
  $el=((Get-Date)-$t0).TotalSeconds
  foreach($w in (Wins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $k=Kids $w.H; $msg=($k|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
      Write-Output ("T+{0:N1} [Startup] ERROR: {1}" -f $el,$msg)
      $ok=$k|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][W3]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq $Button}|Select-Object -First 1
      if($b){ Write-Output ("T+{0:N1} CLICK '{1}'" -f $el,$Button)
        [void][W3]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400 }
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m -and $m.MainWindowHandle -ne 0 -and -not $shot -and $el -gt $ShotAt){
    $w=(Wins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS'}|Select-Object -First 1
    if($w -and ($w.R-$w.L) -gt 100){
      $mh=$m.MainWindowHandle
      [void][W3]::SetForegroundWindow($mh); Start-Sleep -Milliseconds 1200
      $bmp=New-Object System.Drawing.Bitmap (($w.R-$w.L)),(($w.B-$w.T))
      $g=[System.Drawing.Graphics]::FromImage($bmp)
      $g.CopyFromScreen($w.L,$w.T,0,0,$bmp.Size)
      $bmp.Save($OutPng,[System.Drawing.Imaging.ImageFormat]::Png)
      $g.Dispose(); $bmp.Dispose()
      Write-Output ("T+{0:N1} SCREENSHOT -> {1} ({2}x{3})" -f $el,$OutPng,($w.R-$w.L),($w.B-$w.T))
      $shot=$true
    }
  }
}
Write-Output ("ALIVE_AT_END=" + [bool](Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue))
Write-Output "--- teardown ---"
foreach($n in @('SK-Main','SK-Startup')){ Get-Process -Name $n -ErrorAction SilentlyContinue|ForEach-Object{Write-Output "killing $n $($_.Id)";try{$_.Kill()}catch{}} }
Write-Output "--- log ---"; Get-Content (Join-Path $WorkDir 'SilverKnights.log') -Tail 5
