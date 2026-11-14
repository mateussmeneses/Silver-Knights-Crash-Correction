# Enumerate all windows and child controls (text) belonging to SK-Startup / SK-Main.
# Read-only UI inspection. Uses Win32 EnumWindows/EnumChildWindows via P/Invoke.
param(
    [string]$Exe = "C:\projetos\Silver-Knights-Crash-Correction\SK-Startup.exe",
    [string]$WorkDir = "C:\projetos\Silver-Knights-Crash-Correction",
    [int]$WaitSeconds = 20
)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class WinDump {
    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr w, StringBuilder l);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern IntPtr GetDlgItem(IntPtr h, int id);

    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }

    public static List<string> Dump(uint targetPid) {
        var outp = new List<string>();
        EnumWindows((h, p) => {
            uint pid; GetWindowThreadProcessId(h, out pid);
            if (pid != targetPid) return true;
            var t = new StringBuilder(512); GetWindowTextW(h, t, 512);
            var c = new StringBuilder(256); GetClassNameW(h, c, 256);
            RECT r; GetWindowRect(h, out r);
            outp.Add(String.Format("WINDOW hwnd=0x{0:X} class='{1}' visible={2} rect={3},{4},{5},{6} text='{7}'",
                h.ToInt64(), c, IsWindowVisible(h), r.Left, r.Top, r.Right, r.Bottom, t));
            int idx = 0;
            EnumChildWindows(h, (ch, cp) => {
                var ct = new StringBuilder(1024); GetWindowTextW(ch, ct, 1024);
                var cc = new StringBuilder(256); GetClassNameW(ch, cc, 256);
                RECT cr; GetWindowRect(ch, out cr);
                outp.Add(String.Format("   CHILD[{0}] hwnd=0x{1:X} class='{2}' visible={3} rect={4},{5},{6},{7} text='{8}'",
                    idx, ch.ToInt64(), cc, IsWindowVisible(ch), cr.Left, cr.Top, cr.Right, cr.Bottom, ct));
                idx++;
                return true;
            }, IntPtr.Zero);
            return true;
        }, IntPtr.Zero);
        return outp;
    }
}
'@

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Exe
$psi.WorkingDirectory = $WorkDir
$psi.UseShellExecute = $false
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi
[void]$p.Start()
Write-Output "launched pid=$($p.Id)"
Write-Output "=== all windows for pid (polling every 1s, $WaitSeconds s) ==="

$lastBlob = ''
for ($i = 0; $i -lt $WaitSeconds; $i++) {
    Start-Sleep -Seconds 1
    $lines = [WinDump]::Dump([uint32]$p.Id)
    $blob = ($lines -join "`n")
    if ($blob -ne $lastBlob) {
        Write-Output ""
        Write-Output ("--- T+{0}s ---" -f ($i+1))
        $lines | Where-Object { $_ -match "text='.+'|WINDOW " } | ForEach-Object { Write-Output $_ }
        $lastBlob = $blob
    }
    if ($p.HasExited) { Write-Output "parent exited code=$($p.ExitCode)"; break }
}

# Also dump SK-Main if it appeared
Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Output ""
    Write-Output "=== SK-Main pid=$($_.Id) windows ==="
    [WinDump]::Dump([uint32]$_.Id) | ForEach-Object { Write-Output $_ }
}

Write-Output "=== cleanup ==="
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