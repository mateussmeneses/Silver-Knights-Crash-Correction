# Drive SK-Startup: dismiss error dialogs, click a launch button, monitor SK-Main.
# Read-only w.r.t. game files. Records timings, windows, exit codes and new WER events.
param(
    [string]$WorkDir = "C:\projetos\Silver-Knights-Crash-Correction",
    [string]$Button  = "Window",
    [int]$Seconds    = 60
)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    public static string Text(IntPtr h){ var s=new StringBuilder(512); GetWindowTextW(h,s,512); return s.ToString(); }
    public static string Cls(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
}
'@

function Find-Windows($pid_) {
    $res = New-Object System.Collections.ArrayList
    [W]::EnumWindows({ param($h,$p)
        $owner=0; [void][W]::GetWindowThreadProcessId($h,[ref]$owner)
        if ($owner -eq $pid_) {
            [void]$res.Add([pscustomobject]@{H=$h;Class=[W]::Cls($h);Text=[W]::Text($h);Visible=[W]::IsWindowVisible($h)})
        }
        return $true
    }, [IntPtr]::Zero) | Out-Null
    return $res
}
function Find-Children($h) {
    $res = New-Object System.Collections.ArrayList
    [W]::EnumChildWindows($h, { param($c,$p)
        [void]$res.Add([pscustomobject]@{H=$c;Class=[W]::Cls($c);Text=[W]::Text($c);Visible=[W]::IsWindowVisible($c)})
        return $true
    }, [IntPtr]::Zero) | Out-Null
    return $res
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = Join-Path $WorkDir 'SK-Startup.exe'
$psi.WorkingDirectory = $WorkDir
$psi.UseShellExecute = $false
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi
[void]$p.Start()
$t0 = Get-Date
Write-Output "T+0 LAUNCH SK-Startup pid=$($p.Id)"

$clickedDismiss = $false
$clickedLaunch  = $false
$mainSeen = @{}
$deadline = $t0.AddSeconds($Seconds)

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 700
    $el = ((Get-Date)-$t0).TotalSeconds

    # --- SK-Startup dialogs ---
    foreach ($w in (Find-Windows $p.Id)) {
        if (-not $w.Visible) { continue }
        $kids = Find-Children $w.H
        if ($w.Text -eq 'Error Massage') {
            $ok = $kids | Where-Object { $_.Class -eq 'Button' -and $_.Text -eq 'OK' } | Select-Object -First 1
            if ($ok) {
                $msg = ($kids | Where-Object { $_.Class -eq 'Static' -and $_.Text } | Select-Object -First 1).Text
                Write-Output ("T+{0:N1} DISMISS error dialog: '{1}'" -f $el, $msg)
                [void][W]::SendMessageW($ok.H, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)  # BM_CLICK
                Start-Sleep -Milliseconds 300
            }
        }
        elseif ($w.Text -like 'SK Startup*' -and -not $clickedLaunch) {
            $btns = $kids | Where-Object { $_.Class -eq 'Button' -and $_.Text -eq $Button }
            if ($btns) {
                Write-Output ("T+{0:N1} CLICK launch button '{1}' (hwnd=0x{2:X})" -f $el, $Button, $btns[0].H.ToInt64())
                [void][W]::SetForegroundWindow($w.H)
                [void][W]::SendMessageW($btns[0].H, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
                $clickedLaunch = $true
                Start-Sleep -Milliseconds 500
            }
        }
    }

    # --- SK-Main observation ---
    $m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
    if ($m) {
        $key = $m.Id
        if (-not $mainSeen.ContainsKey($key)) {
            $mainSeen[$key] = $true
            Write-Output ("T+{0:N1} SK-Main STARTED pid={1} threads={2} ws={3}MB" -f $el,$m.Id,$m.Threads.Count,[math]::Round($m.WorkingSet64/1MB,1))
        }
        $title = $m.MainWindowTitle
        if ($title) {
            $tk = "t:$title"
            if (-not $mainSeen.ContainsKey($tk)) {
                $mainSeen[$tk]=$true
                Write-Output ("T+{0:N1} SK-Main WINDOW hwnd=0x{1:X} title='{2}'" -f $el,$m.MainWindowHandle.ToInt64(),$title)
            }
        }
    } elseif ($mainSeen.Count -gt 0) {
        Write-Output ("T+{0:N1} SK-Main GONE" -f $el)
        break
    }
    if ($p.HasExited) { Write-Output ("T+{0:N1} SK-Startup EXIT code={1}" -f $el,$p.ExitCode); break }
}

Write-Output "--- teardown ---"
foreach ($n in @('SK-Main','SK-Startup')) {
    Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "killing $n pid=$($_.Id) ws=$([math]::Round($_.WorkingSet64/1MB,1))MB"
        try { $_.Kill() } catch {}
    }
}
Write-Output "--- log tail ---"
Get-Content (Join-Path $WorkDir 'SilverKnights.log') -Tail 6
Write-Output "--- WER events last 15 min ---"
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=@(1000,1001,1002); StartTime=(Get-Date).AddMinutes(-15)} -MaxEvents 20 -ErrorAction SilentlyContinue |
  ForEach-Object { Write-Output ("[{0}] id={1} {2}" -f $_.TimeCreated.ToString('HH:mm:ss'),$_.Id,(($_.Message -replace "`r?`n",' ; ').Substring(0,[Math]::Min(400,($_.Message -replace "`r?`n",' ; ').Length)))) }
