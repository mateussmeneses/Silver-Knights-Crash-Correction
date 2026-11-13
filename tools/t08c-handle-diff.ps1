# T-08b: identify the leaking handle type (corrected implementation).
#
# Supersedes tools/t08b-handle-types.ps1, which had two PowerShell defects:
#   1. `Snap` used Write-Output for its diagnostics, so those strings entered the pipeline and
#      became part of the function's return value. `$s1` ended up an array of strings, and the
#      later `$s1.ContainsKey(...)` failed with "System.String does not contain a method
#      named 'ContainsKey'". The snapshots printed nothing usable.
#   2. it had no attach mode, so it launched a second game instance and interfered with a
#      soak that was already running.
#
# This version writes all diagnostics with Write-Host (host only, never the pipeline) and
# returns exactly one object per snapshot. It can attach to a running instance.
#
# Why this matters: run-48 and run-49 both show handle count rising ~+20/min while memory is
# flat. Flat memory rules out a growing data structure, so the leak is small kernel objects
# created on a repeating tick and never closed. Naming the type is the actionable step.
param(
    [string]$WorkDir  = "C:\Users\Mateus\AppData\Local\hermes\cache\scratch\sk-sandbox5",
    [int]$FirstAtSec  = 30,
    [int]$SecondAtSec = 240,
    [switch]$AttachToExisting
)
$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class HandleDiff {
    [StructLayout(LayoutKind.Sequential)]
    public struct ENTRY {
        public ushort UniqueProcessId;
        public ushort CreatorBackTraceIndex;
        public byte   ObjectTypeIndex;
        public byte   HandleAttributes;
        public ushort HandleValue;
        public IntPtr Object;
        public uint   GrantedAccess;
    }

    [DllImport("ntdll.dll")]
    static extern int NtQuerySystemInformation(int cls, IntPtr info, int len, out int retLen);

    const int SystemHandleInformation = 16;

    // C# 5 only: PowerShell 5.1's compiler rejects C# 7 inline out-declarations.
    public static Dictionary<int,int> Counts(int pid, out int total) {
        Dictionary<int,int> counts = new Dictionary<int,int>();
        total = 0;
        int len = 1 << 20;
        IntPtr buf = IntPtr.Zero;
        int status = -1;
        int needed = 0;
        for (int attempt = 0; attempt < 8; attempt++) {
            buf = Marshal.AllocHGlobal(len);
            status = NtQuerySystemInformation(SystemHandleInformation, buf, len, out needed);
            if (status == 0) { break; }
            Marshal.FreeHGlobal(buf);
            buf = IntPtr.Zero;
            int next = needed + (1 << 16);
            if (next <= len) { next = len * 2; }
            len = next;
        }
        if (buf == IntPtr.Zero) { return counts; }
        try {
            int count = Marshal.ReadInt32(buf);
            int stride = Marshal.SizeOf(typeof(ENTRY));
            long baseOff = (IntPtr.Size == 8) ? 8L : 4L;
            for (int i = 0; i < count; i++) {
                IntPtr p = new IntPtr(buf.ToInt64() + baseOff + (long)i * stride);
                ENTRY e = (ENTRY)Marshal.PtrToStructure(p, typeof(ENTRY));
                if ((int)e.UniqueProcessId != pid) { continue; }
                total++;
                int ti = (int)e.ObjectTypeIndex;
                if (!counts.ContainsKey(ti)) { counts[ti] = 0; }
                counts[ti] = counts[ti] + 1;
            }
        } finally {
            Marshal.FreeHGlobal(buf);
        }
        return counts;
    }
}
'@
if(-not ("HandleDiff" -as [type])){ Write-Host "FATAL: Add-Type failed"; exit 1 }
Write-Host "HandleDiff compiled OK"

if($AttachToExisting){
    $m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue | Select-Object -First 1
    if(-not $m){ Write-Host "FATAL: -AttachToExisting but no SK-Main is running"; exit 1 }
    $gamePid = $m.Id
    Write-Host ("attached to pid={0} age={1:N0}s" -f $gamePid, ((Get-Date)-$m.StartTime).TotalSeconds)
} else {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $WorkDir 'SK-Startup.exe'
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false
    $sp = New-Object System.Diagnostics.Process
    $sp.StartInfo = $psi
    [void]$sp.Start()
    Write-Host "launched launcher"
    Start-Sleep -Seconds 28
    $m = Get-Process -Name 'SK-Main' -ErrorAction SilentlyContinue | Select-Object -First 1
    if(-not $m){ Write-Host "FATAL: SK-Main not running"; exit 1 }
    $gamePid = $m.Id
    Write-Host "game pid=$gamePid"
}

# Returns ONE hashtable. All human-readable output goes to the host, never the pipeline.
function Get-Snapshot([string]$label) {
    $total = 0
    $counts = [HandleDiff]::Counts([int]$gamePid, [ref]$total)
    Write-Host ""
    Write-Host ("=== {0}: total={1} distinctTypes={2} ===" -f $label, $total, $counts.Count)
    $rows = $counts.GetEnumerator() | Sort-Object -Property Value -Descending
    foreach($r in $rows){
        Write-Host ("    typeIndex {0,3}   count {1,6}" -f $r.Key, $r.Value)
    }
    Write-Host ""
    return @{ Total = $total; Counts = $counts }
}

Start-Sleep -Seconds ([int]$FirstAtSec)
$s1 = Get-Snapshot "SNAPSHOT 1"

$gap = $SecondAtSec - $FirstAtSec
if($gap -gt 0){ Start-Sleep -Seconds ([int]$gap) }
$s2 = Get-Snapshot "SNAPSHOT 2"

$c1 = $s1.Counts
$c2 = $s2.Counts
$allKeys = New-Object System.Collections.ArrayList
foreach($k in $c1.Keys){ [void]$allKeys.Add($k) }
foreach($k in $c2.Keys){ if(-not $allKeys.Contains($k)){ [void]$allKeys.Add($k) } }

Write-Host ""
Write-Host "=== DELTA by object type index ==="
Write-Host ("total handles: {0} -> {1}   delta {2:+#;-#;0}" -f $s1.Total, $s2.Total, ($s2.Total - $s1.Total))
$grown = @()
foreach($k in ($allKeys | Sort-Object)){
    $a = 0; if($c1.ContainsKey($k)){ $a = $c1[$k] }
    $b = 0; if($c2.ContainsKey($k)){ $b = $c2[$k] }
    $d = $b - $a
    if($d -ne 0){
        Write-Host ("  typeIndex {0,3}: {1,6} -> {2,6}   delta {3,+#;-#;0}" -f $k, $a, $b, $d)
        if($d -gt 0){ $grown += [pscustomobject]@{ TypeIndex = $k; Grew = $d } }
    }
}

Write-Host ""
if($grown.Count -gt 0){
    Write-Host "=== the leaking type(s), largest first ==="
    foreach($g in ($grown | Sort-Object -Property Grew -Descending)){
        Write-Host ("  typeIndex {0}  grew by {1}" -f $g.TypeIndex, $g.Grew)
    }
} else {
    Write-Host "no type grew between the snapshots - leak may need a longer interval or a match"
}

Write-Host ""
Write-Host "=== teardown ==="
if(-not $AttachToExisting){
    Get-Process -Name 'SK-Main','SK-Startup' -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "killing $($_.ProcessName) $($_.Id)"
        try { $_.Kill() } catch { }
    }
} else {
    Write-Host "attached mode: leaving the process running"
}
