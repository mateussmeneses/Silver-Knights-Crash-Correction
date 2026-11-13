# Launch SK-Startup, dismiss startup errors, click launch, then read EVERY SK-Main dialog
# text verbatim as it appears. Also captures the render window title/size changes.
param(
    [string]$WorkDir = "C:\projetos\Silver-Knights-Crash-Correction",
    [string]$Button  = "Window",
    [int]$Seconds    = 90
)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W2 {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
    public static string Text(IntPtr h){ var s=new StringBuilder(1024); GetWindowTextW(h,s,1024); return s.ToString(); }
    public static string Cls(IntPtr h){ var s=new StringBuilder(256); GetClassNameW(h,s,256); return s.ToString(); }
}
'@

function Wins($pid_) {
    $res = New-Object System.Collections.ArrayList
    [W2]::EnumWindows({ param($h,$p)
        $o=0; [void][W2]::GetWindowThreadProcessId($h,[ref]$o)
        if ($o -eq $pid_ -and [W2]::IsWindowVisible($h)) {
            $r = New-Object 'W2+RECT'
            [void][W2]::GetWindowRect($h,[ref]$r)
            [void]$res.Add([pscustomobject]@{H=$h;Class=[W2]::Cls($h);Text=[W2]::Text($h);Rect="$($r.Left),$($r.Top),$($r.Right),$($r.Bottom)"})
        }
        return $true
    },[IntPtr]::Zero) | Out-Null
    return $res
}
function Kids($h) {
    $res = New-Object System.Collections.ArrayList
    [W2]::EnumChildWindows($h,{ param($c,$p)
        [void]$res.Add([pscustomobject]@{H=$c;Class=[W2]::Cls($c);Text=[W2]::Text($c);Visible=[W2]::IsWindowVisible($c)})
        return $true
    },[IntPtr]::Zero) | Out-Null
    return $res
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = Join-Path $WorkDir 'SK-Startup.exe'
$psi.WorkingDirectory = $WorkDir
$psi.UseShellExecute = $false
$sp = New-Object System.Diagnostics.Process
$sp.StartInfo = $psi
[void]$sp.Start()
$t0 = Get-Date
Write-Output "T+0 LAUNCH SK-Startup pid=$($sp.Id)"

$clickedLaunch = $false
$reported = @{}
$deadline = $t0.AddSeconds($Seconds)

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 500
    $el = ((Get-Date)-$t0).TotalSeconds

    foreach ($w in (Wins $sp.Id)) {
        if ($w.Text -eq 'Error Massage') {
            $k = Kids $w.H
            $msg = ($k | Where-Object { $_.Class -eq 'Static' -and $_.Text } | Select-Object -First 1).Text
            $key = "SU:$msg"
            if (-not $reported.ContainsKey($key)) {
                $reported[$key] = $true
                Write-Output ("T+{0:N1} [SK-Startup] ERROR: {1}" -f $el,$msg)
            }
            $ok = $k | Where-Object { $_.Class -eq 'Button' -and $_.Text -eq 'OK' } | Select-Object -First 1
            if ($ok) { [void][W2]::SendMessageW($ok.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero); Start-Sleep -Milliseconds 250 }
        }
        elseif ($w.Text -like 'SK Startup*' -and -not $clickedLaunch) {
            $b = (Kids $w.H) | Where-Object { $_.Class -eq 'Button' -and $_.Text -eq $Button } | Select-Object -First 1
            if ($b) {
                Write-Output ("T+{0:N1} CLICK '{1}'" -f $el,$Button)
                [void][W2]::SendMessageW($b.H,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero)
                $clickedLaunch = $true
                Start-Sleep -Milliseconds 400
            }
        }
    }

    $m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue
    if ($m) {
        $everSawMain = $true
        foreach ($w in (Wins $m.Id)) {
            $k = Kids $w.H
            $statics = ($k | Where-Object { $_.Class -eq 'Static' -and $_.Text -and $_.Visible } | ForEach-Object { $_.Text }) -join ' || '
            $sig = "$($w.Class)|$($w.Text)|$statics|$($w.Rect)"
            if (-not $reported.ContainsKey($sig)) {
                $reported[$sig] = $true
                Write-Output ("T+{0:N1} [SK-Main] WIN class='{1}' text='{2}' rect={3}" -f $el,$w.Class,$w.Text,$w.Rect)
                if ($statics) { Write-Output ("          STATIC: {0}" -f $statics) }
                $btns = ($k | Where-Object { $_.Class -eq 'Button' -and $_.Text } | ForEach-Object { "'" + $_.Text + "'" }) -join ', '
                if ($btns) { Write-Output ("          BUTTONS: {0}" -f $btns) }
            }
        }
    } elseif ($everSawMain) {
        Write-Output ("T+{0:N1} SK-Main process gone" -f $el)
        break
    }
}

Write-Output "--- teardown ---"
foreach ($n in @('SK-Main','SK-Startup')) {
    Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "killing $n $($_.Id)"; try{$_.Kill()}catch{} }
}
Write-Output "--- log tail ---"; Get-Content (Join-Path $WorkDir 'SilverKnights.log') -Tail 4
