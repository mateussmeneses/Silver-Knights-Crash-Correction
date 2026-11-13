# Enumerate 32-bit modules of a WOW64 process by running a 32-bit enumerator.
# The 64-bit PowerShell's .Modules only sees ntdll + wow64* stubs.
param(
    [int]$WarmupSeconds = 18,
    [string]$WorkDir = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox"
)
$ErrorActionPreference = 'SilentlyContinue'
$syswow = "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W8 {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    public static string T(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string C(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
}
'@
function AllWins($p_){ $r=New-Object System.Collections.ArrayList
  [W8]::EnumWindows({param($h,$z) $o=0;[void][W8]::GetWindowThreadProcessId($h,[ref]$o)
    if($o -eq $p_){[void]$r.Add([pscustomobject]@{H=$h;Cls=[W8]::C($h);Text=[W8]::T($h)})}
    return $true},[IntPtr]::Zero)|Out-Null; return $r }
function Kids($h){ $r=New-Object System.Collections.ArrayList
  [W8]::EnumChildWindows($h,{param($c,$z) [void]$r.Add([pscustomobject]@{H=$c;Cls=[W8]::C($c);Text=[W8]::T($c)}); return $true},[IntPtr]::Zero)|Out-Null; return $r }

$psi=New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName=Join-Path $WorkDir 'SK-Startup.exe'; $psi.WorkingDirectory=$WorkDir; $psi.UseShellExecute=$false
$sp=New-Object System.Diagnostics.Process; $sp.StartInfo=$psi; [void]$sp.Start()
$t0=Get-Date; Write-Output "T+0 LAUNCH pid=$($sp.Id)"
$clicked=$false
while(((Get-Date)-$t0).TotalSeconds -lt $WarmupSeconds){
  Start-Sleep -Milliseconds 500
  foreach($w in (AllWins $sp.Id)){
    if($w.Text -eq 'Error Massage'){
      $ok=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'OK'}|Select-Object -First 1
      if($ok){[void][W8]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250}
    } elseif($w.Text -like 'SK Startup*' -and -not $clicked){
      $b=(Kids $w.H)|Where-Object{$_.Cls -eq 'Button' -and $_.Text -eq 'Window'}|Select-Object -First 1
      if($b){[void][W8]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); $clicked=$true; Start-Sleep -Milliseconds 400}
    }
  }
}
$m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
if(-not $m){ Write-Output "FAIL: SK-Main not running"; exit 1 }
Write-Output "SK-Main pid=$($m.Id)  (32-bit / WOW64)"

if(-not (Test-Path $syswow)){
    Write-Output "WARN: 32-bit powershell not found at $syswow; falling back to a 64-bit module walk"
    $m.Modules | ForEach-Object { Write-Output ("  {0}" -f $_.ModuleName) }
    exit 0
}

# A 32-bit enumerator sees the real 32-bit module list of the WOW64 process.
$inner = @'
param([int]$TargetPid)
$ErrorActionPreference='SilentlyContinue'
$p = Get-Process -Id $TargetPid
$p.Modules | Sort-Object ModuleName | ForEach-Object {
    $vi = $_.FileVersionInfo
    "{0}`t{1}`t{2}" -f $_.ModuleName, ("0x{0:x8}" -f $_.BaseAddress.ToInt64()), $vi.FileVersion
}
'@
$tmp = Join-Path $env:TEMP ("sk_mods_{0}.ps1" -f (Get-Random))
Set-Content -Path $tmp -Value $inner -Encoding UTF8
Write-Output ""
Write-Output "=== 32-bit module list (via SysWOW64 powershell) ==="
$out = & $syswow -NoProfile -ExecutionPolicy Bypass -File $tmp -TargetPid $m.Id 2>&1
$out | ForEach-Object { Write-Output ("  " + $_) }
Remove-Item $tmp -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "=== keyword hits ==="
$kw = 'ddraw|d3d9|d3dx|dsound|dinput|dpnet|dpwsock|dplay|winmm|quartz|devenum|msmpeg|mpg|msacm|iac25|l3codeca|libeay|ssleay|SKGuard|msvcr|msvcp|ole32|oleaut|wininet|imm32|version|uxtheme|opengl|nvogl|nvwgf|dxgi|dwmapi|winhttp|urlmon|wsock|ws2_32|oleacc'
$out | Where-Object { $_ -match $kw } | ForEach-Object { Write-Output ("  * " + $_) }

Write-Output ""
Write-Output "=== teardown ==="
Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "killing $($_.ProcessName) $($_.Id)"; try{$_.Kill()}catch{} }
