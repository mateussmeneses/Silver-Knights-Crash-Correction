# Verbose launch trace: log EVERY window/class/text seen each second, plus WER,
# plus whether the process exits and why. No early exit. Read-only observation.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [int]$Seconds = 60,
    [switch]$DismissErrors,
    [switch]$LaunchWindow,
    [int]$KeyAt = 0
)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W6 {
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
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
    public static string T(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string C(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
}
'@
function AllWins($p_){
  $r=New-Object System.Collections.ArrayList
  [W6]::EnumWindows({param($h,$z) $o=0;[void][W6]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){$rc=New-Object 'W6+RECT';[void][W6]::GetWindowRect($h,[ref]$rc)
      [void]$r.Add([pscustomobject]@{H=$h;Cls=[W6]::C($h);Text=[W6]::T($h);Vis=[W6]::IsWindowVisible($h);L=$rc.Left;T=$rc.Top;R=$rc.Right;B=$rc.Bottom})}
    return $true},[IntPtr]::Zero)|Out-Null
  return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [W6]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[W6]::C($c);Text=[W6]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null
  return $r }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH SK-Startup pid=$($sp.Id) cwd=$WorkDir"
$seen=@{}; $launched=$false; $keysSent=$false
$deadline=$t0.AddSeconds($Seconds)
while((Get-Date) -lt $deadline){
  Start-Sleep -Milliseconds 500
  $el=((Get-Date)-$t0).TotalSeconds
  $procs=@()
  if(-not $sp.HasExited){ $procs += $sp }
  $mp = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
  if($mp){ $procs += $mp }
  foreach($pr in $procs){
    foreach($w in (AllWins $pr.Id)){
      $sig = "$($pr.ProcessName)/$($w.Cls)/$($w.Text)/$($w.Vis)"
      if(-not $seen.ContainsKey($sig)){
        $seen[$sig]=$true
        $kids=(Kids $w.H)|Where-Object{$_.Text}
        $kidstr = ($kids|ForEach-Object{ "[$($_.Cls)]$($_.Text)" }) -join ' ; '
        Write-Output ("T+{0:N1} {1} cls='{2}' vis={3} rect={4},{5},{6},{7} text='{8}'{9}" -f $el,$pr.ProcessName,$w.Cls,$w.Vis,$w.L,$w.T,$w.R,$w.B,$w.Text, $(if($kidstr){"  kids: $kidstr"}else{""}))
      }
      # act on dialogs
      if($w.Text -eq 'Error Massage' -and $DismissErrors){
        $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
        if($ok){ Write-Output ("T+{0:N1}   -> dismiss OK" -f $el); [void][W6]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 300 }
      }
      if($pr.ProcessName -eq 'SK-Startup' -and $w.Text -like 'SK Startup*' -and $LaunchWindow -and -not $launched){
        $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
        if($b){ Write-Output ("T+{0:N1}   -> CLICK Window" -f $el); [void][W6]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $launched=$true; Start-Sleep -Milliseconds 400 }
      }
    }
  }
  if($KeyAt -gt 0 -and -not $keysSent -and $el -gt $KeyAt -and $mp -and $mp.MainWindowHandle -ne 0){
    $udx = (AllWins $mp.Id)|Where-Object{$_.Cls -eq 'UDX_CLASS'}|Select-Object -First 1
    if($udx){
      [void][W6]::PostMessageW($udx.H,0x0100,[IntPtr]0x0D,[IntPtr]::Zero); Start-Sleep -Milliseconds 90
      [void][W6]::PostMessageW($udx.H,0x0101,[IntPtr]0x0D,[IntPtr]::Zero); Start-Sleep -Milliseconds 200
      [void][W6]::PostMessageW($udx.H,0x0100,[IntPtr]0x20,[IntPtr]::Zero); Start-Sleep -Milliseconds 90
      [void][W6]::PostMessageW($udx.H,0x0101,[IntPtr]0x20,[IntPtr]::Zero)
      Write-Output ("T+{0:N1}   -> SENT Enter+Space to UDX hwnd=0x{1:X}" -f $el,$udx.H.ToInt64()); $keysSent=$true
    }
  }
}
Write-Output "--- end state ---"
if($sp.HasExited){ Write-Output ("SK-Startup exited code=0x{0:X8}" -f $sp.ExitCode) } else { Write-Output "SK-Startup still running" }
foreach($mp in (Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue)){
  Write-Output ("SK-Main pid={0} alive={1:N1}s ws={2}MB threads={3}" -f $mp.Id,((Get-Date)-$mp.StartTime).TotalSeconds,[math]::Round($mp.WorkingSet64/1MB,1),$mp.Threads.Count)
}
Write-Output "--- log tail ---"; Get-Content (Join-Path $WorkDir 'SilverKnights.log') -Tail 4
Write-Output "--- WER/AppError last 10 min ---"
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=@(1000,1001,1002); StartTime=(Get-Date).AddMinutes(-10)} -MaxEvents 20 -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Output ("[{0}] id={1} :: {2}" -f $_.TimeCreated.ToString('HH:mm:ss'),$_.Id,(($_.Message -replace "`r?`n",' ; ').Substring(0,[Math]::Min(300,($_.Message -replace "`r?`n",' ; ').Length)))) }
Write-Output "--- teardown ---"
foreach($n in @('SK-Main','SK-Startup')){ Get-Process -Name $n -ErrorAction SilentlyContinue|ForEach-Object{Write-Output "killing $n $($_.Id)";try{$_.Kill()}catch{}} }
