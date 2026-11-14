# Interaction probe: launch patched build, focus the render window, send keys,
# capture screenshots at intervals, and report whether the window contents change.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [int]$RunSeconds = 70,
    [string]$OutPrefix = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\probe"
)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W4 {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
    public static string Text(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string Cls(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
}
'@
function Wins($p_){ $r=New-Object System.Collections.ArrayList
  [W4]::EnumWindows({param($h,$z) $o=0;[void][W4]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_ -and [W4]::IsWindowVisible($h)){$rc=New-Object 'W4+RECT';[void][W4]::GetWindowRect($h,[ref]$rc)
      [void]$r.Add([pscustomobject]@{H=$h;Cls=[W4]::Cls($h);Text=[W4]::Text($h);L=$rc.Left;T=$rc.Top;R=$rc.Right;B=$rc.Bottom})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [W4]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[W4]::Cls($c);Text=[W4]::Text($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Snap($w,$path){
  $bmp=New-Object System.Drawing.Bitmap (($w.R-$w.L)),(($w.B-$w.T))
  $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($w.L,$w.T,0,0,$bmp.Size)
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose() }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false; $shots=0
$deadline=$t0.AddSeconds($RunSeconds)
while((Get-Date) -lt $deadline){
  Start-Sleep -Milliseconds 500
  $el=((Get-Date)-$t0).TotalSeconds
  foreach($w in (Wins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $k=Kids $w.H; $msg=($k|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
      Write-Output ("T+{0:N1} [Startup] ERROR: {1}" -f $el,$msg)
      $ok=$k|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][W4]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){ Write-Output ("T+{0:N1} CLICK 'Window'" -f $el)
        [void][W4]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400 }
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m -and $m.MainWindowHandle -ne 0){
    $w=(Wins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS'}|Select-Object -First 1
    if($w -and ($w.R-$w.L) -gt 100){
      # T+8 baseline shot
      if($shots -eq 0 -and $el -gt 8){ Snap $w "$OutPrefix-T08-title.png"; Write-Output ("T+{0:N1} SNAP title" -f $el); $shots=1 }
      # T+14 send keys
      elseif($shots -eq 1 -and $el -gt 14){
        [void][W4]::SetForegroundWindow($w.H)
        Start-Sleep -Milliseconds 400
        Write-Output ("T+{0:N1} SEND WM_KEYDOWN/UP VK_RETURN(0x0D) + VK_SPACE(0x20) to hwnd=0x{1:X}" -f $el,$w.H.ToInt64())
        [void][W4]::PostMessageW($w.H,0x0100,[IntPtr]0x0D,[IntPtr]::Zero)
        Start-Sleep -Milliseconds 120
        [void][W4]::PostMessageW($w.H,0x0101,[IntPtr]0x0D,[IntPtr]::Zero)
        Start-Sleep -Milliseconds 300
        [void][W4]::PostMessageW($w.H,0x0100,[IntPtr]0x20,[IntPtr]::Zero)
        Start-Sleep -Milliseconds 120
        [void][W4]::PostMessageW($w.H,0x0101,[IntPtr]0x20,[IntPtr]::Zero)
        $shots=2
      }
      # T+22 post-key shot
      elseif($shots -eq 2 -and $el -gt 22){ Snap $w "$OutPrefix-T22-afterkeys.png"; Write-Output ("T+{0:N1} SNAP after keys" -f $el); $shots=3 }
      # T+30 shot
      elseif($shots -eq 3 -and $el -gt 30){ Snap $w "$OutPrefix-T30-late.png"; Write-Output ("T+{0:N1} SNAP late" -f $el); $shots=4 }
    }
    # always report any dialog
    foreach($dw in (Wins $m.Id)){ if($dw.Text -eq 'Error Massage'){
      $dk=Kids $dw.H; $dmsg=($dk|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
      Write-Output ("T+{0:N1} [SK-Main] ERROR DIALOG: {1}" -f $el,$dmsg) } }
  }
}
Write-Output ("ALIVE_AT_END=" + [bool](Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue))
Write-Output "--- teardown ---"
foreach($n in @('SK-Main','SK-Startup')){ Get-Process -Name $n -ErrorAction SilentlyContinue|ForEach-Object{Write-Output "killing $n $($_.Id)";try{$_.Kill()}catch{}} }
Get-ChildItem "$OutPrefix-*.png" | ForEach-Object { Write-Output ("SHOT {0} {1} bytes" -f $_.Name,$_.Length) }
