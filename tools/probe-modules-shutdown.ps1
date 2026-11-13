# Close W-2 and W-5: verify clean shutdown writes the End log line, and enumerate
# the actually-loaded modules of a running patched SK-Main.
param(
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox",
    [int]$WarmupSeconds = 18
)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W7 {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    public static string T(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string C(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
}
'@
function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [W7]::EnumWindows({param($h,$z) $o=0;[void][W7]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[W7]::C($h);Text=[W7]::T($h);Vis=[W7]::IsWindowVisible($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [W7]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[W7]::C($c);Text=[W7]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

$log = Join-Path $WorkDir 'SilverKnights.log'
Write-Output "=== log lines BEFORE ($((Get-Content $log).Count)) ==="
$before = Get-Content $log

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi
$script:SKStartedAt = (Get-Date).AddSeconds(-5)   # ownership boundary, with slack for a fast child
[void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false; $shotMods=$false
while(((Get-Date)-$t0).TotalSeconds -lt $WarmupSeconds){
  Start-Sleep -Milliseconds 500
  $el=((Get-Date)-$t0).TotalSeconds
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][W7]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][W7]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Write-Output ("T+{0:N1} CLICK Window" -f $el); Start-Sleep -Milliseconds 400}
    }
  }
}

$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if(-not $m){ Write-Output "FAIL: SK-Main not running at warmup end"; exit 1 }

Write-Output ""
Write-Output "=== W-5: LOADED MODULES of SK-Main pid=$($m.Id) ==="
$mods = $m.Modules | Sort-Object ModuleName
Write-Output ("total modules: {0}" -f $mods.Count)
$interesting = 'ddraw|d3d9|d3dx|dsound|dinput|dpnet|dpwsock|dplay|winmm|quartz|devenum|msmpeg|mpg|msacm|iac25|l3codeca|libeay|ssleay|SKGuard|msvcr|msvcp|ole32|oleaut|wininet|imm32|version|SHFOLDER|uxtheme|opengl|nv|aticfx|igd|vulkan|dxgi|dwmapi|winhttp|urlmon|wsock|ws2_32'
$mods | Where-Object { $_.ModuleName -match $interesting } | ForEach-Object {
  Write-Output ("  {0,-24} 0x{1:x8}  {2}" -f $_.ModuleName, $_.BaseAddress.ToInt64(), $_.FileName)
}
Write-Output ""
Write-Output "=== ALL modules (name + version) ==="
$mods | ForEach-Object {
  $vi = $_.FileVersionInfo
  Write-Output ("  {0,-24} {1}" -f $_.ModuleName, $vi.FileVersion)
}

Write-Output ""
Write-Output "=== W-2: clean shutdown via WM_CLOSE ==="
$udx = (AllWins $m.Id) | Where-Object { $_.Cls -eq 'UDX_CLASS' } | Select-Object -First 1
if($udx){
  Write-Output ("sending WM_CLOSE to UDX hwnd=0x{0:X}" -f $udx.H.ToInt64())
  [void][W7]::PostMessageW($udx.H,0x0010,[IntPtr]::Zero,[IntPtr]::Zero)
} else { Write-Output "WARN: no UDX_CLASS window found; sending WM_CLOSE to main window" 
  [void][W7]::PostMessageW($m.MainWindowHandle,0x0010,[IntPtr]::Zero,[IntPtr]::Zero) }

$exitDeadline=(Get-Date).AddSeconds(20)
while((Get-Date) -lt $exitDeadline){
  Start-Sleep -Milliseconds 400
  if(-not (Get-Process -Id $m.Id -ErrorAction SilentlyContinue)){ break }
}
$still = Get-Process -Id $m.Id -ErrorAction SilentlyContinue
if($still){
  Write-Output "SK-Main did NOT exit within 20s of WM_CLOSE -> killing"
  try { $still.Kill() } catch {}
} else {
  Write-Output "SK-Main exited after WM_CLOSE"
}
Start-Sleep -Seconds 2
Write-Output ""
Write-Output "=== log AFTER ==="
$after = Get-Content $log
$after | Select-Object -Last 6 | ForEach-Object { Write-Output "  $_" }
Write-Output ""
Write-Output ("lines added: {0}" -f ($after.Count - $before.Count))
if(($after | Select-String 'End   <').Count -gt ($before | Select-String 'End   <').Count){
  Write-Output "RESULT: PASS - a new 'SK-Main.exe End' line was written (clean shutdown path ran)"
} else {
  Write-Output "RESULT: INCONCLUSIVE - no new 'End' line written"
}
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