# Capture the SK-Main render window with PrintWindow (works even if occluded),
# at several points in time, and report whether frames differ.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [int]$RunSeconds = 75,
    [string]$OutPrefix = "C:\projetos\Silver-Knights-Crash-Correction\docs\evidence\pw"
)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Drawing;
public class W5 {
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
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
    public static string Text(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string Cls(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }

    public static bool SaveWindow(IntPtr hwnd, string path)
    {
        RECT r; if (!GetWindowRect(hwnd, out r)) return false;
        int w = r.Right - r.Left, hh = r.Bottom - r.Top;
        if (w <= 0 || hh <= 0) return false;
        using (Bitmap bmp = new Bitmap(w, hh))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            IntPtr hdc = g.GetHdc();
            bool ok = PrintWindow(hwnd, hdc, 2); // PW_RENDERFULLCONTENT
            g.ReleaseHdc(hdc);
            if (!ok) return false;
            bmp.Save(path, System.Drawing.Imaging.ImageFormat.Png);
        }
        return true;
    }
}
'@
function Wins($p_){ $r=New-Object System.Collections.ArrayList
  [W5]::EnumWindows({param($h,$z) $o=0;[void][W5]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_ -and [W5]::IsWindowVisible($h)){$rc=New-Object 'W5+RECT';[void][W5]::GetWindowRect($h,[ref]$rc)
      [void]$r.Add([pscustomobject]@{H=$h;Cls=[W5]::Cls($h);Text=[W5]::Text($h);L=$rc.Left;T=$rc.Top;R=$rc.Right;B=$rc.Bottom})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [W5]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[W5]::Cls($c);Text=[W5]::Text($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi; [void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false
$plan=@(@{t=8;n='T08'},@{t=16;n='T16'},@{t=26;n='T26'},@{t=40;n='T40'})
$idx=0; $keysSent=$false
$deadline=$t0.AddSeconds($RunSeconds)
while((Get-Date) -lt $deadline){
  Start-Sleep -Milliseconds 400
  $el=((Get-Date)-$t0).TotalSeconds
  foreach($w in (Wins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $k=Kids $w.H; $msg=($k|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
      Write-Output ("T+{0:N1} [Startup] ERROR: {1}" -f $el,$msg)
      $ok=$k|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][W5]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){ [void][W5]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Write-Output ("T+{0:N1} CLICK 'Window'" -f $el); Start-Sleep -Milliseconds 400 }
    }
  }
  $m=Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($m -and $m.MainWindowHandle -ne 0){
    foreach($dw in (Wins $m.Id)){ if($dw.Text -eq 'Error Massage'){
      $dk=Kids $dw.H; $dmsg=($dk|Where-Object{$_.Cls -eq 'Static' -and $_.Text}|Select-Object -First 1).Text
      Write-Output ("T+{0:N1} [SK-Main] ERROR DIALOG: {1}" -f $el,$dmsg) } }
    $w=(Wins $m.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS'}|Select-Object -First 1
    if($w -and $idx -lt $plan.Count -and $el -gt $plan[$idx].t){
      $p="$OutPrefix-$($plan[$idx].n).png"
      if([W5]::SaveWindow($w.H,$p)){ Write-Output ("T+{0:N1} PRINTWINDOW {1} ok={2} bytes={3}" -f $el,$plan[$idx].n,$true,(Get-Item $p).Length) }
      else { Write-Output ("T+{0:N1} PRINTWINDOW {1} FAILED" -f $el,$plan[$idx].n) }
      $idx++
      if(-not $keysSent -and $el -gt 16){
        [void][W5]::SetForegroundWindow($w.H); Start-Sleep -Milliseconds 300
        [void][W5]::PostMessageW($w.H,0x0100,[IntPtr]0x0D,[IntPtr]::Zero); Start-Sleep -Milliseconds 100
        [void][W5]::PostMessageW($w.H,0x0101,[IntPtr]0x0D,[IntPtr]::Zero); Start-Sleep -Milliseconds 200
        [void][W5]::PostMessageW($w.H,0x0100,[IntPtr]0x20,[IntPtr]::Zero); Start-Sleep -Milliseconds 100
        [void][W5]::PostMessageW($w.H,0x0101,[IntPtr]0x20,[IntPtr]::Zero)
        Write-Output ("T+{0:N1} SENT Enter+Space" -f $el); $keysSent=$true
      }
    }
  }
}
Write-Output ("ALIVE_AT_END=" + [bool](Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue))
Write-Output "--- teardown ---"
foreach($n in @('SK-Main','SK-Startup')){ Get-Process -Name $n -ErrorAction SilentlyContinue|ForEach-Object{Write-Output "killing $n $($_.Id)";try{$_.Kill()}catch{}} }
Get-ChildItem "$OutPrefix-*.png" -ErrorAction SilentlyContinue | ForEach-Object { Write-Output ("SHOT {0} {1} bytes" -f $_.Name,$_.Length) }
